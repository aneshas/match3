import SwiftUI
import Match3Core

/// Draws the cells, the candies and the match bursts, and turns drags into swipes. There is no
/// panel behind the board: the faint cells alone show the playable shape.
struct BoardView: View {
    let session: GameSession
    /// One swipe per finger-down. Without this a long drag could trigger a second swap
    /// from the tile's new position once the first one finishes.
    @State private var dragConsumed = false
    @State private var settings = Settings.shared
    @Environment(\.colorSchemeContrast) private var systemContrast

    var body: some View {
        let highContrast = settings.highContrastActive(systemIncreased: systemContrast == .increased)
        GeometryReader { geo in
            let rows = session.config.rows
            let cols = session.config.cols
            let inset: CGFloat = 6
            // Small opening boards (up to 5x5) may use big candies; larger boards are capped so a
            // tablet does not become a wall of giant candies.
            let maxCell: CGFloat = (rows <= 5 && cols <= 5) ? 150 : 110
            let cell = min((geo.size.width - inset * 2) / CGFloat(cols), (geo.size.height - inset * 2) / CGFloat(rows), maxCell)
            let boardWidth = cell * CGFloat(cols)
            let boardHeight = cell * CGFloat(rows)

            ZStack {
                ZStack(alignment: .topLeading) {
                    // Faint cells show the playable area, so holes read as "not part of the board".
                    ForEach(session.board.allPositions, id: \.self) { p in
                        RoundedRectangle(cornerRadius: cell * 0.22, style: .continuous)
                            .fill(highContrast ? Theme.cellHighContrast : Theme.cell)
                            .overlay(RoundedRectangle(cornerRadius: cell * 0.22, style: .continuous)
                                .strokeBorder(highContrast ? Theme.cellBorderHighContrast : Theme.cellBorder, lineWidth: highContrast ? 3 : 2))
                            .frame(width: cell * 0.92, height: cell * 0.92)
                            .position(center(row: Double(p.row), col: Double(p.col), cell: cell))
                    }

                    ForEach(session.sweeps) { sweep in
                        let horizontal = sweep.axis == .horizontal
                        SweepView(color: session.palette.particleColor(for: sweep.color), horizontal: horizontal)
                            .frame(width: horizontal ? boardWidth : cell * 0.9, height: horizontal ? cell * 0.9 : boardHeight)
                            .position(x: horizontal ? boardWidth / 2 : (CGFloat(sweep.index) + 0.5) * cell,
                                      y: horizontal ? (CGFloat(sweep.index) + 0.5) * cell : boardHeight / 2)
                            .allowsHitTesting(false)
                    }

                    ForEach(session.tiles) { tile in
                        TileView(imageName: session.palette.imageName(for: tile.color, power: tile.power),
                                 size: cell * 0.88,
                                 wiggling: session.wigglingIDs.contains(tile.id),
                                 hinting: session.hintIDs.contains(tile.id),
                                 hintStrength: session.hintLevel,
                                 outlined: highContrast)
                            .rotationEffect(.degrees(tile.rotation))
                            .scaleEffect(tile.scale)
                            .opacity(tile.opacity)
                            .position(center(row: tile.row, col: tile.col, cell: cell))
                            .accessibilityIdentifier("tile.\(Int(tile.row.rounded())).\(Int(tile.col.rounded()))")
                            .gesture(swipeGesture(for: tile))
                    }

                    ForEach(session.bursts) { burst in
                        BurstView(color: session.palette.particleColor(for: burst.color), radius: cell * 0.5, big: burst.big)
                            .position(center(row: Double(burst.row), col: Double(burst.col), cell: cell))
                    }

                    if let arrow = session.hintArrow {
                        let from = center(row: Double(arrow.from.row), col: Double(arrow.from.col), cell: cell)
                        let to = center(row: Double(arrow.to.row), col: Double(arrow.to.col), cell: cell)
                        HintArrowView(direction: direction(from: arrow.from, to: arrow.to))
                            .frame(width: cell * 0.7, height: cell * 0.7)
                            .position(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
                            .transition(.scale.combined(with: .opacity))
                            .allowsHitTesting(false)
                    }

                    if let demo = session.demo {
                        SwipeDemoView(from: center(row: Double(demo.from.row), col: Double(demo.from.col), cell: cell),
                                      to: center(row: Double(demo.to.row), col: Double(demo.to.col), cell: cell),
                                      cell: cell)
                            .id(demo.id)
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
                .clipped()
                .scaleEffect(session.boardPunch ? 1.035 : 1)
                .animation(.spring(response: 0.22, dampingFraction: 0.45), value: session.boardPunch)

                // Rings from special candies, outside the clip so they can spread past the board.
                ForEach(session.shockwaves) { wave in
                    ShockwaveView(color: session.palette.particleColor(for: wave.color), big: wave.big)
                        .frame(width: cell * (wave.big ? 6 : 4), height: cell * (wave.big ? 6 : 4))
                        .position(x: (geo.size.width - boardWidth) / 2 + center(row: Double(wave.row), col: Double(wave.col), cell: cell).x,
                                  y: (geo.size.height - boardHeight) / 2 + center(row: Double(wave.row), col: Double(wave.col), cell: cell).y)
                        .allowsHitTesting(false)
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func direction(from a: Position, to b: Position) -> Direction {
        if b.col > a.col { return .right }
        if b.col < a.col { return .left }
        return b.row > a.row ? .down : .up
    }

    private func center(row: Double, col: Double, cell: CGFloat) -> CGPoint {
        CGPoint(x: (col + 0.5) * cell, y: (row + 0.5) * cell)
    }

    /// Fires once per drag as soon as the finger has moved far enough in one direction.
    private func swipeGesture(for tile: TileState) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                session.playerTouched()
                guard !dragConsumed else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                guard max(abs(dx), abs(dy)) >= 14 else { return }
                dragConsumed = true
                guard session.phase == .idle else { return }
                let direction: Direction = abs(dx) > abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up)
                session.swipe(from: Position(row: Int(tile.row.rounded()), col: Int(tile.col.rounded())), direction)
            }
            .onEnded { _ in
                dragConsumed = false
            }
    }
}
