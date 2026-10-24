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
    var power: Power = .none
}

/// A striped candy going off: a flash along its whole row or column.
struct Sweep: Identifiable, Equatable {
    let id = UUID()
    let axis: LineAxis
    /// Row index for a horizontal sweep, column index for a vertical one.
    let index: Int
    let color: TileColor
}

/// An animated hand showing the player how to swipe: it appears on `from`, drags to `to`.
struct DemoSwipe: Identifiable, Equatable {
    let id = UUID()
    let from: Position
    let to: Position
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
    /// What the bar fills toward: a candy from the next level (set by AppFlow).
    var nextCandy: CandyArt.Preview?
    /// Counters for the adaptive-difficulty policy. Never shown to the player.
    private(set) var stats = LevelStats()
    /// Debug/UI-test counter: every swipe that reached the session, valid or not.
    private(set) var swipeAttempts = 0
    private var playableSince: Date?
    private(set) var board: Board
    private(set) var tiles: [TileState] = []
    private(set) var bursts: [Burst] = []
    private(set) var matchesMade = 0
    /// Progress in steps. A swipe's own match is worth 1 step for three candies, 1.5 for
    /// four, 2 for five or more (summed if one swipe makes two groups). Every group that
    /// matches on its own in a cascade is worth half of that. Levels still need real
    /// swipes; bigger matches and chains just get there sooner.
    private(set) var points: Double = 0
    static let cascadeCredit = 0.5
    /// Steps added when a special candy goes off.
    static let powerCredit = 1.0
    /// Striped-candy flashes currently on screen.
    private(set) var sweeps: [Sweep] = []
    /// How many special candies have gone off this level (debug counters, tests).
    private(set) var triggeredPowers = 0
    /// Whether matches of four and five create special candies (caregiver setting, read
    /// when the level starts so it never changes mid-level).
    let powersEnabled: Bool
    static func stepValue(matched count: Int) -> Double {
        count >= 5 ? 2 : (count == 4 ? 1.5 : 1)
    }
    private(set) var phase: Phase = .busy  // busy until the entrance animation is done
    /// Tiles briefly shaking after an invalid swap.
    private(set) var wigglingIDs: Set<UUID> = []
    /// Tiles pulsing as a hint after the player has been idle for a while.
    private(set) var hintIDs: Set<UUID> = []
    /// How insistent the hint is: 1 = pulse (8 s), 2 = bright glow (16 s), 3 = arrow (24 s).
    private(set) var hintLevel = 0
    /// The move the arrow points along when `hintLevel` reaches 3.
    private(set) var hintArrow: DemoSwipe?
    /// The swipe demo currently playing, if any.
    private(set) var demo: DemoSwipe?

    var onLevelComplete: (() -> Void)?
    /// Fired on the player's first successful swap in this session.
    var onPlayerSwiped: (() -> Void)?

    private var hintTask: Task<Void, Never>?
    private var demoTask: Task<Void, Never>?
    private let hintDelay: Duration = .seconds(8)
    /// Teach by doing: until the player has ever swiped, a hand shows the move right after
    /// the board lands, and keeps repeating after this much idle time.
    private var wantsDemo: Bool
    private var demoShownOnce = false
    private let demoRepeatDelay: Duration = .seconds(3)

    var goal: Int { config.goalMatches }
    /// Progress toward the goal in steps, capped at the goal.
    var progressPoints: Double { min(Double(goal), points) }
    var progressFraction: Double { progressPoints / Double(goal) }

    init(config: LevelConfig, swipeDemo: Bool = false) {
        self.config = config
        self.wantsDemo = swipeDemo
        self.powersEnabled = Settings.shared.powerUpsEnabled
        self.board = config.makeBoard()
        if DebugFlags.powerDemo, powersEnabled, let move = board.findAnyMove() {
            // Debug: two specials placed on the first move the hint (and autoplay) will pick,
            // so whichever side forms the match, a special candy goes off.
            board.setPower(.striped(move.0.row == move.1.row ? .vertical : .horizontal), at: move.0)
            board.setPower(.wrapped, at: move.1)
        }
        rebuildTileStates()
        // Start every tile above the board; `dropIn` lets them fall into place.
        for i in tiles.indices { tiles[i].row -= Double(config.rows + 1) }
        Task { await dropIn() }
    }

    // MARK: - Input

    /// Entry point from the board view. `position` is the tile the player dragged,
    /// `direction` where they dragged it.
    func swipe(from position: Position, _ direction: Direction) {
        swipeAttempts += 1
        guard phase == .idle else { return }
        let target = position.offset(direction)
        guard board.canSwap(position, target) else { return }
        cancelHint()
        cancelDemo()
        phase = .busy  // set synchronously so a second gesture event cannot start another swap
        Task { await performSwap(position, target) }
    }

    /// Any touch cancels the hint and restarts its timer.
    func playerTouched() {
        cancelHint()
        cancelDemo()
        if phase == .idle {
            scheduleHint()
            scheduleDemo(after: demoRepeatDelay)
        }
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
            stats.invalidSwaps += 1
            SoundPlayer.shared.play(.invalid, volume: 0.6)
            await sleep(wiggleDuration)
            wigglingIDs = []
            finishTurn()
            return
        }

        withAnimation(.easeOut(duration: 0.1)) { setScale(idA, 1) }
        board.swap(a, b)
        if wantsDemo {
            wantsDemo = false
            onPlayerSwiped?()
        }
        // Steps are credited inside `resolveCascades` (the swipe's own match in full, cascade
        // groups at half value). `matchesMade` stays the plain swipe count for the stats.
        matchesMade = min(goal, matchesMade + 1)
        await resolveCascades(swapped: [a, b])

        if progressPoints >= Double(goal) {
            phase = .complete
            stats.matches = matchesMade
            stats.seconds = playableSince.map { Date().timeIntervalSince($0) } ?? 0
            SoundPlayer.shared.playLevelDone()
            await celebrateBoard()
            onLevelComplete?()
            return
        }

        if !board.hasAnyMove {
            await reshuffle()
        }
        finishTurn()
    }

    private func resolveCascades(swapped: Set<Position>) async {
        var depth = 0
        while true {
            let groups = board.findMatches()
            if groups.isEmpty { return }

            // Which candies clear, and which special candies this match earns. The earning
            // candy (the one the player moved, else the middle of the run) stays on the board
            // and transforms instead of popping.
            var base = Set(groups.flatMap { $0.positions })
            var creations: [(at: Position, power: Power)] = []
            if powersEnabled {
                for g in groups {
                    guard let power = g.earnedPower,
                          let pivot = pivot(for: g, preferring: depth == 0 ? swapped : []) else { continue }
                    creations.append((pivot, power))
                    base.remove(pivot)
                }
            }
            let expansion = board.expandedRemoval(for: base)
            // A pivot caught in a striped sweep is simply cleared; nothing is created there.
            creations.removeAll { expansion.removed.contains($0.at) }
            let triggerPositions = Set(expansion.triggered.map(\.position))
            triggeredPowers += expansion.triggered.count

            let big = depth > 0 || !expansion.triggered.isEmpty || groups.contains { $0.positions.count >= 4 }
            // Credit the bar right away so the reward lands with the burst: full value for
            // the swipe's own groups (depth 0), half for groups the board matched by itself,
            // and a full step for every special candy that went off.
            let stepsNow = groups.reduce(0.0) { $0 + GameSession.stepValue(matched: $1.positions.count) }
            points += (depth == 0 ? stepsNow : stepsNow * GameSession.cascadeCredit)
                + Double(expansion.triggered.count) * GameSession.powerCredit
            Haptics.matchMade(big: big)
            SoundPlayer.shared.playMatch(big: big)

            // Striped candies flash along their line, behind the popping candies.
            for t in expansion.triggered {
                guard case .striped(let axis) = t.power, let tile = board.tile(at: t.position) else { continue }
                let sweep = Sweep(axis: axis, index: axis == .horizontal ? t.position.row : t.position.col, color: tile.color)
                sweeps.append(sweep)
                Task { [weak self] in
                    try? await Task.sleep(for: .milliseconds(700))
                    self?.sweeps.removeAll { $0.id == sweep.id }
                }
            }

            let removed = expansion.removed.compactMap { p in board.tile(at: p).map { (p, $0) } }
            let removedIDs = Set(removed.map { $0.1.id })

            // Puff up, then shrink away while particles fly out.
            withAnimation(.easeOut(duration: popDuration * 0.4)) {
                for i in tiles.indices where removedIDs.contains(tiles[i].id) { tiles[i].scale = 1.3 }
            }
            await sleep(popDuration * 0.4)
            let newBursts = removed.map {
                Burst(row: $0.0.row, col: $0.0.col, color: $0.1.color, big: big || triggerPositions.contains($0.0))
            }
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

            board.remove(expansion.removed)
            tiles.removeAll { removedIDs.contains($0.id) }

            // Earned special candies transform in place with a little pop.
            for c in creations {
                board.setPower(c.power, at: c.at)
                guard let id = board.tile(at: c.at)?.id, let i = tiles.firstIndex(where: { $0.id == id }) else { continue }
                tiles[i].power = c.power
                tiles[i].scale = 1.45
                withAnimation(.spring(response: 0.4 * motionScale, dampingFraction: 0.5)) { tiles[i].scale = 1 }
            }

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
        }
    }

    /// Where an earned special candy appears: the candy the player moved if it is in the
    /// group, otherwise the middle of the group. Never on top of an existing special.
    private func pivot(for group: MatchGroup, preferring preferred: Set<Position>) -> Position? {
        let plain = group.positions.filter { board.tile(at: $0)?.power == Power.none }
        if let p = plain.first(where: { preferred.contains($0) }) { return p }
        let sorted = plain.sorted { ($0.row, $0.col) < ($1.row, $1.col) }
        guard !sorted.isEmpty else { return nil }
        return sorted[sorted.count / 2]
    }

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
        if playableSince == nil { playableSince = Date() }
        scheduleHint()
        scheduleDemo(after: demoShownOnce ? demoRepeatDelay : .milliseconds(500))
        if DebugFlags.autoPlay { scheduleAutoPlay() }
    }

    // MARK: - Swipe demo

    private func scheduleDemo(after delay: Duration) {
        guard wantsDemo else { return }
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, self.wantsDemo, self.phase == .idle, let (p, q) = self.board.findAnyMove() else { return }
            self.demoShownOnce = true
            self.hintIDs = Set([self.board.tile(at: p)?.id, self.board.tile(at: q)?.id].compactMap { $0 })
            self.demo = DemoSwipe(from: p, to: q)
            try? await Task.sleep(for: .milliseconds(2300))
            guard !Task.isCancelled else { return }
            self.demo = nil
            self.scheduleDemo(after: self.demoRepeatDelay)
        }
    }

    private func cancelDemo() {
        demoTask?.cancel()
        demoTask = nil
        demo = nil
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

    /// Escalating hint: the same valid move is pulsed after 8 s, glows brightly after 16 s and
    /// gets an arrow after 24 s. The player should never be stuck for long.
    private func scheduleHint() {
        hintTask?.cancel()
        hintTask = Task { [weak self] in
            guard let self else { return }
            for level in 1...3 {
                try? await Task.sleep(for: self.hintDelay)
                guard !Task.isCancelled, self.phase == .idle, let (p, q) = self.board.findAnyMove() else { return }
                self.hintIDs = Set([self.board.tile(at: p)?.id, self.board.tile(at: q)?.id].compactMap { $0 })
                self.hintLevel = level
                if level == 1 { self.stats.hintsShown += 1 }
                if level == 3 { self.hintArrow = DemoSwipe(from: p, to: q) }
            }
        }
    }

    private func cancelHint() {
        hintTask?.cancel()
        hintTask = nil
        hintIDs = []
        hintLevel = 0
        hintArrow = nil
    }

    // MARK: - Helpers

    private func rebuildTileStates() {
        tiles = board.tiles.map { TileState(id: $0.tile.id, color: $0.tile.color,
                                            row: Double($0.position.row), col: Double($0.position.col),
                                            power: $0.tile.power) }
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
