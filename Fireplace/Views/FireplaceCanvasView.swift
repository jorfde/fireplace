import SwiftUI

enum FireplaceAnimationState {
    case idle
    case burning
    case embers
}

struct FireplaceCanvasView: View {
    let state: FireplaceAnimationState
    @State private var frameIndex: Int = 0

    private let fps: Double = 4
    private let gridSize: Int = 16

    private let darkWood = Color(red: 0.17, green: 0.11, blue: 0.05)
    private let hearth = Color(red: 0.55, green: 0.27, blue: 0.07)
    private let flameCore = Color(red: 1.0, green: 0.4, blue: 0.0)
    private let flameTip = Color(red: 1.0, green: 0.84, blue: 0.0)
    private let emberGlow = Color(red: 1.0, green: 0.27, blue: 0.0)
    private let ash = Color(red: 0.35, green: 0.32, blue: 0.30)
    private let background = Color(red: 0.10, green: 0.07, blue: 0.04)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
            Canvas { ctx, size in
                let cellW = size.width / CGFloat(gridSize)
                let cellH = size.height / CGFloat(gridSize)

                // Background
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(background))

                // Hearth base (stone platform)
                for x in 3...12 {
                    fillCell(ctx: ctx, x: x, y: 13, w: cellW, h: cellH, color: hearth)
                    fillCell(ctx: ctx, x: x, y: 14, w: cellW, h: cellH, color: darkWood)
                }

                // Side logs
                for y in 10...12 {
                    fillCell(ctx: ctx, x: 4, y: y, w: cellW, h: cellH, color: hearth)
                    fillCell(ctx: ctx, x: 11, y: y, w: cellW, h: cellH, color: hearth)
                }
                // Cross log
                for x in 5...10 {
                    fillCell(ctx: ctx, x: x, y: 12, w: cellW, h: cellH, color: darkWood)
                }

                let frame = currentFrame(from: context.date)

                switch state {
                case .idle:
                    drawIdleHearth(ctx: ctx, cellW: cellW, cellH: cellH)
                case .burning:
                    drawBurningFlame(ctx: ctx, cellW: cellW, cellH: cellH, frame: frame)
                case .embers:
                    drawEmbers(ctx: ctx, cellW: cellW, cellH: cellH, frame: frame)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func currentFrame(from date: Date) -> Int {
        Int(date.timeIntervalSinceReferenceDate * fps) % 4
    }

    private func fillCell(ctx: GraphicsContext, x: Int, y: Int, w: CGFloat, h: CGFloat, color: Color) {
        let rect = CGRect(x: CGFloat(x) * w, y: CGFloat(y) * h, width: w + 0.5, height: h + 0.5)
        ctx.fill(Path(rect), with: .color(color))
    }

    private func drawIdleHearth(ctx: GraphicsContext, cellW: CGFloat, cellH: CGFloat) {
        // A few ash pixels
        fillCell(ctx: ctx, x: 6, y: 11, w: cellW, h: cellH, color: ash)
        fillCell(ctx: ctx, x: 8, y: 11, w: cellW, h: cellH, color: ash)
        fillCell(ctx: ctx, x: 9, y: 11, w: cellW, h: cellH, color: ash)
    }

    private func drawBurningFlame(ctx: GraphicsContext, cellW: CGFloat, cellH: CGFloat, frame: Int) {
        // Base embers
        for x in 6...9 {
            fillCell(ctx: ctx, x: x, y: 11, w: cellW, h: cellH, color: emberGlow)
        }

        // Flame core patterns per frame
        let corePatterns: [[(Int, Int)]] = [
            [(7, 10), (8, 10), (7, 9), (8, 9), (7, 8)],
            [(7, 10), (8, 10), (6, 9), (8, 9), (8, 8)],
            [(6, 10), (8, 10), (7, 9), (8, 9), (7, 8), (8, 7)],
            [(7, 10), (9, 10), (7, 9), (8, 9), (8, 8)],
        ]

        let tipPatterns: [[(Int, Int)]] = [
            [(7, 7), (8, 6)],
            [(8, 7), (7, 6)],
            [(7, 7), (7, 6), (8, 5)],
            [(8, 7), (8, 6)],
        ]

        let safeFrame = frame % corePatterns.count

        for (x, y) in corePatterns[safeFrame] {
            fillCell(ctx: ctx, x: x, y: y, w: cellW, h: cellH, color: flameCore)
        }
        for (x, y) in tipPatterns[safeFrame] {
            fillCell(ctx: ctx, x: x, y: y, w: cellW, h: cellH, color: flameTip)
        }
    }

    private func drawEmbers(ctx: GraphicsContext, cellW: CGFloat, cellH: CGFloat, frame: Int) {
        let emberPositions: [[(Int, Int)]] = [
            [(7, 11), (8, 11), (6, 11)],
            [(7, 11), (9, 11), (8, 11)],
            [(6, 11), (8, 11), (9, 11)],
            [(7, 11), (8, 11)],
        ]

        let safeFrame = frame % emberPositions.count
        for (x, y) in emberPositions[safeFrame] {
            fillCell(ctx: ctx, x: x, y: y, w: cellW, h: cellH, color: emberGlow.opacity(frame % 2 == 0 ? 1.0 : 0.6))
        }

        // A dim glow pixel
        fillCell(ctx: ctx, x: 7, y: 10, w: cellW, h: cellH, color: flameCore.opacity(0.3))
    }
}


