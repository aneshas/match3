import SwiftUI
import Match3Core
#if canImport(UIKit)
import UIKit
#endif

/// What the board view draws for one tile. Positions are Doubles so a freshly spawned tile
/// can start above the board (negative row) and fall into place.
struct TileState: Identifiable, Equatable {
    let id: UUID
    let color: TileColor
    var row: Double
    var col: Double
    var scale: Double = 1
    var opacity: Double = 1
    var rotation: Double = 0
}

/// A transient particle burst where a candy was matched.
struct Burst: Identifiable, Equatable {
    let id = UUID()
    let row: Int
    let col: Int
    let color: TileColor
    let big: Bool
}

/// Runs one level: owns the `Board`, drives the swap/match/fall animation sequence and
/// counts matches toward the goal. Everything here is MainActor because it mutates the
/// SwiftUI-observed tile states inside `withAnimation`.
@MainActor
@Observable
final class GameSession {
    enum Phase: Equatable {
        case idle      // waiting for a swipe
        case busy      // animating; input ignored
        case complete  // goal reached
    }

    let config: LevelConfig
    private(set) var board: Board
    private(set) var tiles: [TileState] = []
    private(set) var bursts: [Burst] = []
    private(set) var matchesMade = 0
    private(set) var phase: Phase = .busy  // busy until the entrance animation is done
    /// Tiles briefly shaking after an invalid swap.
    private(set) var wigglingIDs: Set<UUID> = []
    /// Tiles pulsing as a hint after the player has been idle for a while.
    private(set) var hintIDs: Set<UUID> = []

    var onLevelComplete: (() -> Void)?

    private var hintTask: Task<Void, Never>?
    private let hintDelay: Duration = .seconds(8)

    var goal: Int { config.goalMatches }
    var progressFraction: Double { min(1, Double(matchesMade) / Double(goal)) }

    init(config: LevelConfig) {
        self.config = config
        self.board = config.makeBoard()
        rebuildTileStates()
        // Start every tile above the board; `dropIn` lets them fall into place.
        for i in tiles.indices { tiles[i].row -= Double(config.rows + 1) }
        Task { await dropIn() }
    }

    // MARK: - Input

    /// Entry point from the board view. `position` is the tile the player dragged,
    /// `direction` where they dragged it.
    func swipe(from position: Position, _ direction: Direction) {
        guard phase == .idle else { return }
        let target = position.offset(direction)
        guard board.canSwap(position, target) else { return }
        cancelHint()
        phase = .busy  // set synchronously so a second gesture event cannot start another swap
        Task { await performSwap(position, target) }
    }

    /// Any touch cancels the hint and restarts its timer.
    func playerTouched() {
        cancelHint()
        if phase == .idle { scheduleHint() }
    }

    // MARK: - Entrance

    /// Candies rain into place column by column with a little bounce.
    private func dropIn() async {
        let perColumn = 0.05 * motionScale
        let perRow = 0.03 * motionScale
        var longest = 0.0
        for i in tiles.indices {
            let target = tiles[i].row + Double(config.rows + 1)
            let delay = tiles[i].col * perColumn + (Double(config.rows) - target) * perRow
            longest = max(longest, delay)
            withAnimation(.spring(response: 0.55 * motionScale, dampingFraction: 0.68).delay(delay)) {
                tiles[i].row = target
            }
        }
        await sleep(longest + 0.6 * motionScale)
        finishTurn()
    }

    // MARK: - Sequence

    private func performSwap(_ a: Position, _ b: Position) async {
        let idA = board.tile(at: a)!.id
        let idB = board.tile(at: b)!.id

        // Lift the dragged candy slightly and slide the two across each other.
        withAnimation(.easeInOut(duration: swapDuration)) {
            move(idA, to: b)
            move(idB, to: a)
            setScale(idA, 1.15)
        }
        await sleep(swapDuration)

        guard board.swapCreatesMatch(a, b) else {
            // Not a match: slide back and wiggle. No sound, no red, just "nope".
            withAnimation(.easeInOut(duration: swapDuration)) {
                move(idA, to: a)
                move(idB, to: b)
                setScale(idA, 1)
            }
            await sleep(swapDuration)
            wigglingIDs = [idA, idB]
            SoundPlayer.shared.play(.invalid, volume: 0.6)
            await sleep(wiggleDuration)
            wigglingIDs = []
            finishTurn()
            return
        }

        withAnimation(.easeOut(duration: 0.1)) { setScale(idA, 1) }
        board.swap(a, b)
        await resolveCascades()

        if matchesMade >= goal {
            phase = .complete
            SoundPlayer.shared.play(.levelDone)
            await celebrateBoard()
            onLevelComplete?()
            return
        }

        if !board.hasAnyMove {
            await reshuffle()
        }
        finishTurn()
    }

    private func resolveCascades() async {
        var depth = 0
        while true {
            let groups = board.findMatches()
            if groups.isEmpty { return }

            matchesMade = min(goal, matchesMade + groups.count)
            let big = depth > 0 || groups.contains { $0.positions.count >= 4 }
            Haptics.matchMade(big: big)
            SoundPlayer.shared.playMatch(big: big)

            let removed = groups.flatMap { g in g.positions.compactMap { p in board.tile(at: p).map { (p, $0) } } }
            let removedIDs = Set(removed.map { $0.1.id })

            // Puff up, then shrink away while particles fly out.
            withAnimation(.easeOut(duration: popDuration * 0.4)) {
                for i in tiles.indices where removedIDs.contains(tiles[i].id) { tiles[i].scale = 1.3 }
            }
            await sleep(popDuration * 0.4)
            let newBursts = removed.map { Burst(row: $0.0.row, col: $0.0.col, color: $0.1.color, big: big) }
            bursts.append(contentsOf: newBursts)
            withAnimation(.easeIn(duration: popDuration * 0.6)) {
                for i in tiles.indices where removedIDs.contains(tiles[i].id) {
                    tiles[i].scale = 0.01
                    tiles[i].opacity = 0
                }
            }
            await sleep(popDuration * 0.6)
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(800))
                self?.bursts.removeAll { b in newBursts.contains(b) }
            }

            for g in groups { board.remove(g.positions) }
            tiles.removeAll { removedIDs.contains($0.id) }

            let result = board.applyGravityAndRefill()
            // Spawned tiles start above the board, then everything falls together with a bounce.
            for s in result.spawns {
                tiles.append(TileState(id: s.tile.id, color: s.tile.color,
                                       row: Double(s.at.row - s.rowsAbove), col: Double(s.at.col)))
            }
            withAnimation(.spring(response: fallDuration, dampingFraction: 0.62)) {
                for f in result.falls { move(f.tileID, to: f.to) }
                for s in result.spawns { move(s.tile.id, to: s.at) }
            }
            await sleep(fallDuration * 1.1)

            depth += 1
            if matchesMade >= goal { return }
        }
    }

    /// Candies spin away row by row before the Good Job screen.
    private func celebrateBoard() async {
        await sleep(0.35)
        let perRow = 0.06 * motionScale
        for i in tiles.indices {
            let delay = (Double(config.rows) - tiles[i].row) * perRow
            withAnimation(.easeIn(duration: 0.3 * motionScale).delay(delay)) {
                tiles[i].scale = 0.01
                tiles[i].rotation = 180
                tiles[i].opacity = 0
            }
        }
        await sleep(Double(config.rows) * perRow + 0.45 * motionScale)
    }

    /// Stuck board: candies twirl out, get new colors, twirl back in.
    private func reshuffle() async {
        SoundPlayer.shared.play(.shuffle, volume: 0.7)
        withAnimation(.easeIn(duration: 0.35 * motionScale)) {
            for i in tiles.indices {
                tiles[i].scale = 0.2
                tiles[i].rotation = 180
                tiles[i].opacity = 0
            }
        }
        await sleep(0.35 * motionScale)
        board.shuffle()
        rebuildTileStates()
        for i in tiles.indices {
            tiles[i].scale = 0.2
            tiles[i].rotation = -180
            tiles[i].opacity = 0
        }
        withAnimation(.spring(response: 0.5 * motionScale, dampingFraction: 0.7)) {
            for i in tiles.indices {
                tiles[i].scale = 1
                tiles[i].rotation = 0
                tiles[i].opacity = 1
            }
        }
        await sleep(0.55 * motionScale)
    }

    private func finishTurn() {
        phase = .idle
        scheduleHint()
        if DebugFlags.autoPlay { scheduleAutoPlay() }
    }

    /// Demo / verification mode: play a valid move by itself after a short pause.
    private func scheduleAutoPlay() {
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard let self, self.phase == .idle, let (p, q) = self.board.findAnyMove() else { return }
            let direction: Direction = q.row > p.row ? .down : q.row < p.row ? .up : q.col > p.col ? .right : .left
            self.swipe(from: p, direction)
        }
    }

    // MARK: - Hint

    private func scheduleHint() {
        hintTask?.cancel()
        hintTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.hintDelay)
            guard !Task.isCancelled, self.phase == .idle, let (p, q) = self.board.findAnyMove() else { return }
            let ids = Set([self.board.tile(at: p)?.id, self.board.tile(at: q)?.id].compactMap { $0 })
            self.hintIDs = ids
        }
    }

    private func cancelHint() {
        hintTask?.cancel()
        hintTask = nil
        hintIDs = []
    }

    // MARK: - Helpers

    private func rebuildTileStates() {
        tiles = board.tiles.map { TileState(id: $0.tile.id, color: $0.tile.color,
                                            row: Double($0.position.row), col: Double($0.position.col)) }
    }

    private func move(_ id: UUID, to p: Position) {
        guard let i = tiles.firstIndex(where: { $0.id == id }) else { return }
        tiles[i].row = Double(p.row)
        tiles[i].col = Double(p.col)
    }

    private func setScale(_ id: UUID, _ scale: Double) {
        guard let i = tiles.firstIndex(where: { $0.id == id }) else { return }
        tiles[i].scale = scale
    }

    private func sleep(_ seconds: Double) async {
        try? await Task.sleep(for: .milliseconds(Int(seconds * 1000)))
    }

    // Durations shrink when the system "Reduce Motion" setting is on.
    private var motionScale: Double { Motion.reduceMotion ? 0.4 : 1 }
    private var swapDuration: Double { 0.2 * motionScale }
    private var popDuration: Double { 0.3 * motionScale }
    private var fallDuration: Double { 0.38 * motionScale }
    private var wiggleDuration: Double { 0.35 }
}
