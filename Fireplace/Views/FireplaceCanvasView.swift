import SwiftUI

enum FireplaceAnimationState {
    case idle
    case lightingUp(progress: Double)
    case burning
    case dyingDown(progress: Double)
    case embers
}

struct FireplaceCanvasView: View {
    let state: FireplaceAnimationState
    var showMarshmallow: Bool = false
    var streakDays: Int = 0
    var timeProgress: Double = 0

    private let fps: Double = 4
    private let rows: Int = 16

    // Cute campfire palette — warm & saturated, GBA-era
    private let star = Color(red: 0.95, green: 0.92, blue: 0.70)
    private let grass = Color(red: 0.18, green: 0.35, blue: 0.15)
    private let grassLight = Color(red: 0.25, green: 0.45, blue: 0.20)
    private let dirt = Color(red: 0.30, green: 0.20, blue: 0.12)
    private let stoneRing = Color(red: 0.45, green: 0.42, blue: 0.40)
    private let stoneDark = Color(red: 0.32, green: 0.30, blue: 0.28)
    private let stoneNotch = Color(red: 0.55, green: 0.52, blue: 0.48)
    private let logBrown = Color(red: 0.45, green: 0.25, blue: 0.12)
    private let logLight = Color(red: 0.58, green: 0.35, blue: 0.18)
    private let logDark = Color(red: 0.30, green: 0.16, blue: 0.08)
    private let flameWhite = Color(red: 1.0, green: 0.96, blue: 0.85)
    private let flameYellow = Color(red: 1.0, green: 0.80, blue: 0.22)
    private let flameOrange = Color(red: 1.0, green: 0.48, blue: 0.12)
    private let flameRed = Color(red: 0.88, green: 0.22, blue: 0.10)
    private let emberBright = Color(red: 1.0, green: 0.38, blue: 0.08)
    private let emberDim = Color(red: 0.65, green: 0.18, blue: 0.06)
    private let ash = Color(red: 0.40, green: 0.36, blue: 0.34)
    private let warmGlow = Color(red: 0.35, green: 0.15, blue: 0.05)
    private let smoke = Color(red: 0.50, green: 0.48, blue: 0.52)
    private let mallowWhite = Color(red: 0.95, green: 0.92, blue: 0.88)
    private let mallowBrown = Color(red: 0.65, green: 0.45, blue: 0.25)
    private let stickBrown = Color(red: 0.50, green: 0.32, blue: 0.15)

    private var skyTop: Color { skyColors.0 }
    private var skyBot: Color { skyColors.1 }

    private var skyColors: (Color, Color) {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 6...7:   return (Color(red: 0.20, green: 0.15, blue: 0.25), Color(red: 0.35, green: 0.22, blue: 0.30))
        case 8...16:  return (Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.20, green: 0.30, blue: 0.50))
        case 17...18: return (Color(red: 0.30, green: 0.15, blue: 0.18), Color(red: 0.40, green: 0.20, blue: 0.15))
        default:      return (Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.08, green: 0.07, blue: 0.18))
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
            Canvas { ctx, size in
                // Square pixels based on height. Width adapts.
                let cell = size.height / CGFloat(rows)
                let cols = Int(ceil(size.width / cell))
                let xOff = (cols - 16) / 2  // center the 16-wide scene
                let frame = Int(context.date.timeIntervalSinceReferenceDate * fps) % 4

                drawSky(ctx: ctx, cell: cell, cols: cols, xOff: xOff, frame: frame)
                drawGround(ctx: ctx, cell: cell, cols: cols, xOff: xOff)
                drawStoneRing(ctx: ctx, cell: cell, xOff: xOff)
                drawStreakNotches(ctx: ctx, cell: cell, xOff: xOff)
                drawLogs(ctx: ctx, cell: cell, xOff: xOff)

                switch state {
                case .idle:
                    drawColdAsh(ctx: ctx, cell: cell, xOff: xOff, frame: frame)
                case .lightingUp(let progress):
                    drawLightingUp(ctx: ctx, cell: cell, xOff: xOff, frame: frame, progress: progress)
                case .burning:
                    drawGroundGlow(ctx: ctx, cell: cell, cols: cols, xOff: xOff, frame: frame)
                    drawFire(ctx: ctx, cell: cell, xOff: xOff, frame: frame)
                    drawSparks(ctx: ctx, cell: cell, cols: cols, xOff: xOff, frame: frame)
                    drawStars(ctx: ctx, cell: cell, cols: cols, xOff: xOff, glow: true, frame: frame)
                    if showMarshmallow { drawMarshmallow(ctx: ctx, cell: cell, xOff: xOff, frame: frame) }
                case .dyingDown(let progress):
                    drawDyingDown(ctx: ctx, cell: cell, xOff: xOff, frame: frame, progress: progress)
                case .embers:
                    drawEmberState(ctx: ctx, cell: cell, xOff: xOff, frame: frame)
                    drawSmoke(ctx: ctx, cell: cell, xOff: xOff, frame: frame)
                    drawStars(ctx: ctx, cell: cell, cols: cols, xOff: xOff, glow: false, frame: frame)
                }
            }
        }
    }

    // Square pixel at grid position (offset-adjusted for wide scenes)
    private func p(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ cell: CGFloat, _ color: Color) {
        let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell + 0.5, height: cell + 0.5)
        ctx.fill(Path(rect), with: .color(color))
    }

    // Shorthand with x-offset applied
    private func px(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ cell: CGFloat, _ xOff: Int, _ color: Color) {
        p(ctx, x + xOff, y, cell, color)
    }

    // MARK: - Sky (fills full width)

    private func drawSky(ctx: GraphicsContext, cell: CGFloat, cols: Int, xOff: Int, frame: Int) {
        for y in 0..<rows {
            for x in 0..<cols {
                p(ctx, x, y, cell, y < 6 ? skyTop : skyBot)
            }
        }
        if case .idle = state {
            drawStars(ctx: ctx, cell: cell, cols: cols, xOff: xOff, glow: false, frame: frame)
        }
    }

    private func drawStars(ctx: GraphicsContext, cell: CGFloat, cols: Int, xOff: Int, glow: Bool, frame: Int) {
        let drift = Int(timeProgress * 6)
        // More stars for the wider view
        let basePositions: [(Int, Int)] = [
            (2, 1), (12, 2), (5, 3), (14, 0), (9, 1), (0, 4),
            (-4, 2), (-2, 4), (17, 1), (19, 3), (-6, 1), (21, 2),
        ]
        for (i, (bx, y)) in basePositions.enumerated() {
            let x = ((bx + xOff + drift + i) % cols + cols) % cols
            let twinkle = (frame + i) % 4 == 0
            p(ctx, x, y, cell, star.opacity(twinkle ? 0.5 : 0.85))
        }
        if glow {
            let gx = ((2 + xOff + drift) % cols + cols) % cols
            p(ctx, gx, 1, cell, star.opacity(frame % 2 == 0 ? 1.0 : 0.7))
        }
    }

    // MARK: - Ground (fills full width)

    private func drawGround(ctx: GraphicsContext, cell: CGFloat, cols: Int, xOff: Int) {
        for x in 0..<cols {
            p(ctx, x, 12, cell, x % 3 == 0 ? grassLight : grass)
        }
        for x in 0..<cols {
            p(ctx, x, 13, cell, dirt)
            p(ctx, x, 14, cell, dirt)
            p(ctx, x, 15, cell, dirt)
        }
        // Grass tufts (relative to campfire center)
        px(ctx, 1, 11, cell, xOff, grass)
        px(ctx, 2, 11, cell, xOff, grassLight)
        px(ctx, 13, 11, cell, xOff, grass)
        px(ctx, 14, 11, cell, xOff, grassLight)
        // Extra tufts for wide view
        p(ctx, 1, 11, cell, grass)
        p(ctx, 2, 11, cell, grassLight)
        let lastCol = cols - 1
        p(ctx, lastCol - 1, 11, cell, grass)
        p(ctx, lastCol, 11, cell, grassLight)
    }

    // MARK: - Stone ring (centered)

    private func drawStoneRing(ctx: GraphicsContext, cell: CGFloat, xOff: Int) {
        let stones: [(Int, Int, Color)] = [
            (4, 12, stoneRing), (5, 13, stoneDark), (6, 13, stoneRing),
            (9, 13, stoneDark), (10, 13, stoneRing), (11, 12, stoneDark),
            (4, 13, stoneRing), (11, 13, stoneRing),
        ]
        for (x, y, c) in stones { px(ctx, x, y, cell, xOff, c) }
    }

    private func drawStreakNotches(ctx: GraphicsContext, cell: CGFloat, xOff: Int) {
        guard streakDays > 0 else { return }
        let notchPositions: [(Int, Int)] = [
            (4, 12), (5, 13), (6, 13), (9, 13), (10, 13), (11, 12), (4, 13)
        ]
        for i in 0..<min(streakDays, notchPositions.count) {
            let (x, y) = notchPositions[i]
            px(ctx, x, y, cell, xOff, stoneNotch)
        }
    }

    // MARK: - Logs (centered)

    private func drawLogs(ctx: GraphicsContext, cell: CGFloat, xOff: Int) {
        px(ctx, 5, 12, cell, xOff, logDark)
        px(ctx, 6, 11, cell, xOff, logBrown)
        px(ctx, 6, 12, cell, xOff, logLight)
        px(ctx, 7, 11, cell, xOff, logBrown)
        px(ctx, 7, 12, cell, xOff, logBrown)
        px(ctx, 8, 11, cell, xOff, logBrown)
        px(ctx, 8, 12, cell, xOff, logBrown)
        px(ctx, 9, 11, cell, xOff, logBrown)
        px(ctx, 9, 12, cell, xOff, logLight)
        px(ctx, 10, 12, cell, xOff, logDark)
        px(ctx, 7, 11, cell, xOff, logLight)
        px(ctx, 8, 11, cell, xOff, logLight)
    }

    // MARK: - Cold ash

    private func drawColdAsh(ctx: GraphicsContext, cell: CGFloat, xOff: Int, frame: Int) {
        px(ctx, 7, 11, cell, xOff, ash)
        px(ctx, 8, 11, cell, xOff, ash)
        px(ctx, 7, 10, cell, xOff, ash.opacity(0.5))
        let drift = frame % 2
        px(ctx, 7 + drift, 9, cell, xOff, smoke.opacity(0.2))
        px(ctx, 8 - drift, 8, cell, xOff, smoke.opacity(0.12))
    }

    // MARK: - Lighting up

    private func drawLightingUp(ctx: GraphicsContext, cell: CGFloat, xOff: Int, frame: Int, progress: Double) {
        for x in 6...9 { px(ctx, x, 11, cell, xOff, emberBright.opacity(progress)) }
        if progress > 0.25 {
            px(ctx, 7, 10, cell, xOff, flameOrange.opacity(progress))
            px(ctx, 8, 10, cell, xOff, flameOrange.opacity(progress))
        }
        if progress > 0.5 {
            px(ctx, 7, 9, cell, xOff, flameYellow.opacity(progress))
            px(ctx, 8, 9, cell, xOff, flameOrange.opacity(progress))
            px(ctx, 7 + frame % 2, 8, cell, xOff, flameRed.opacity(progress * 0.7))
        }
        if progress > 0.75 {
            px(ctx, 7, 8, cell, xOff, flameYellow.opacity(progress))
            px(ctx, 8, 7, cell, xOff, flameOrange.opacity(progress * 0.6))
            for x in 5...10 { px(ctx, x, 13, cell, xOff, warmGlow.opacity(progress * 0.3)) }
        }
    }

    // MARK: - Dying down

    private func drawDyingDown(ctx: GraphicsContext, cell: CGFloat, xOff: Int, frame: Int, progress: Double) {
        let remaining = 1.0 - progress
        for x in 6...9 { px(ctx, x, 11, cell, xOff, emberBright.opacity(0.5 + remaining * 0.5)) }
        if remaining > 0.2 {
            px(ctx, 7, 10, cell, xOff, flameOrange.opacity(remaining))
            px(ctx, 8, 10, cell, xOff, flameOrange.opacity(remaining))
        }
        if remaining > 0.5 {
            px(ctx, 7 + frame % 2, 9, cell, xOff, flameYellow.opacity(remaining))
            px(ctx, 8 - frame % 2, 8, cell, xOff, flameRed.opacity(remaining * 0.6))
        }
        if progress > 0.3 {
            let d = frame % 2
            px(ctx, 7 + d, 8, cell, xOff, smoke.opacity(progress * 0.25))
            px(ctx, 8 - d, 7, cell, xOff, smoke.opacity(progress * 0.15))
        }
        for x in 5...10 { px(ctx, x, 13, cell, xOff, warmGlow.opacity(remaining * 0.4)) }
    }

    // MARK: - Ground glow

    private func drawGroundGlow(ctx: GraphicsContext, cell: CGFloat, cols: Int, xOff: Int, frame: Int) {
        let a = frame % 2 == 0 ? 0.5 : 0.35
        for x in 5...10 { px(ctx, x, 13, cell, xOff, warmGlow.opacity(a)) }
        px(ctx, 4, 12, cell, xOff, warmGlow.opacity(0.15))
        px(ctx, 11, 12, cell, xOff, warmGlow.opacity(0.15))
        px(ctx, 3, 12, cell, xOff, warmGlow.opacity(0.08))
        px(ctx, 12, 12, cell, xOff, warmGlow.opacity(0.08))
    }

    // MARK: - Fire

    private func drawFire(ctx: GraphicsContext, cell: CGFloat, xOff: Int, frame: Int) {
        let intensity = timeProgress < 0.8 ? 1.0 : max(0.4, 1.0 - (timeProgress - 0.8) / 0.2 * 0.6)

        for x in 6...9 { px(ctx, x, 11, cell, xOff, frame % 2 == 0 ? emberBright : flameOrange) }

        let redFrames: [[(Int, Int)]] = [
            [(5, 10), (10, 10), (5, 9), (10, 9), (6, 10), (9, 10)],
            [(6, 10), (10, 10), (5, 9), (10, 9), (5, 10), (9, 10)],
            [(5, 10), (9, 10), (6, 9), (10, 9), (10, 10), (6, 10)],
            [(6, 10), (10, 10), (5, 10), (9, 10), (5, 9), (10, 9)],
        ]
        for (x, y) in redFrames[frame % 4] { px(ctx, x, y, cell, xOff, flameRed.opacity(intensity)) }

        let orangeFrames: [[(Int, Int)]] = [
            [(7, 10), (8, 10), (6, 9), (9, 9), (7, 9), (8, 9), (7, 8), (8, 8)],
            [(7, 10), (8, 10), (7, 9), (8, 9), (6, 9), (9, 9), (8, 8), (7, 8)],
            [(7, 10), (8, 10), (6, 9), (9, 9), (7, 9), (8, 9), (6, 8), (8, 8)],
            [(7, 10), (8, 10), (7, 9), (8, 9), (6, 9), (9, 9), (9, 8), (7, 8)],
        ]
        for (x, y) in orangeFrames[frame % 4] { px(ctx, x, y, cell, xOff, flameOrange.opacity(intensity)) }

        let yellowFrames: [[(Int, Int)]] = [
            [(7, 9), (8, 9), (7, 8), (8, 7)],
            [(7, 9), (8, 9), (8, 8), (7, 7)],
            [(8, 9), (7, 8), (8, 8), (8, 7), (7, 7)],
            [(7, 9), (8, 8), (7, 8), (7, 7)],
        ]
        for (x, y) in yellowFrames[frame % 4] { px(ctx, x, y, cell, xOff, flameYellow.opacity(intensity)) }

        let whitePositions: [(Int, Int)] = [(7, 8), (8, 7), (8, 8), (7, 7)]
        let (wx, wy) = whitePositions[frame % 4]
        px(ctx, wx, wy, cell, xOff, flameWhite.opacity(intensity))

        if intensity > 0.6 {
            let tipAlpha = (intensity - 0.6) / 0.4
            let tips: [[(Int, Int, Color)]] = [
                [(7, 6, flameYellow), (8, 5, flameOrange), (7, 4, flameRed)],
                [(8, 6, flameYellow), (7, 5, flameOrange), (8, 4, flameRed)],
                [(7, 6, flameYellow), (8, 6, flameOrange), (7, 5, flameOrange), (8, 4, flameRed)],
                [(8, 6, flameYellow), (7, 6, flameOrange), (8, 5, flameOrange), (7, 4, flameRed)],
            ]
            for (x, y, c) in tips[frame % 4] { px(ctx, x, y, cell, xOff, c.opacity(tipAlpha)) }
        }
    }

    // MARK: - Sparks (spread across wide view)

    private func drawSparks(ctx: GraphicsContext, cell: CGFloat, cols: Int, xOff: Int, frame: Int) {
        let sparkSets: [[(Int, Int)]] = [
            [(6, 5), (10, 4), (4, 7), (-3, 3), (17, 5)],
            [(10, 6), (5, 3), (11, 8), (-5, 5), (19, 4)],
            [(4, 4), (11, 5), (6, 3), (-2, 6), (18, 3)],
            [(11, 3), (5, 6), (9, 3), (-4, 4), (20, 6)],
        ]
        for (x, y) in sparkSets[frame % 4] {
            let ax = x + xOff
            if ax >= 0 && ax < cols {
                p(ctx, ax, y, cell, flameYellow.opacity(0.6))
            }
        }
    }

    // MARK: - Embers

    private func drawEmberState(ctx: GraphicsContext, cell: CGFloat, xOff: Int, frame: Int) {
        let pulse: [Double] = [1.0, 0.65, 0.45, 0.8]
        let b = pulse[frame % 4]
        for x in 6...9 { px(ctx, x, 11, cell, xOff, emberBright.opacity(b)) }
        px(ctx, 7, 10, cell, xOff, emberDim.opacity(b * 0.6))
        px(ctx, 8, 10, cell, xOff, emberDim.opacity(b * 0.4))
        if frame % 4 == 0 { px(ctx, 7, 9, cell, xOff, flameOrange.opacity(0.35)) }
        if frame % 4 == 2 { px(ctx, 8, 9, cell, xOff, flameOrange.opacity(0.25)) }
        for x in 6...9 { px(ctx, x, 13, cell, xOff, warmGlow.opacity(b * 0.2)) }
    }

    // MARK: - Smoke

    private func drawSmoke(ctx: GraphicsContext, cell: CGFloat, xOff: Int, frame: Int) {
        let d = frame % 2
        px(ctx, 7 + d, 8, cell, xOff, smoke.opacity(0.2))
        px(ctx, 8 - d, 7, cell, xOff, smoke.opacity(0.15))
        px(ctx, 7 + d, 6, cell, xOff, smoke.opacity(0.08))
    }

    // MARK: - Marshmallow

    private func drawMarshmallow(ctx: GraphicsContext, cell: CGFloat, xOff: Int, frame: Int) {
        px(ctx, 12, 10, cell, xOff, stickBrown)
        px(ctx, 11, 9, cell, xOff, stickBrown)
        px(ctx, 12, 9, cell, xOff, stickBrown)
        let toasting = frame % 4 < 2
        px(ctx, 11, 8, cell, xOff, toasting ? mallowBrown : mallowWhite)
        px(ctx, 12, 8, cell, xOff, mallowWhite)
    }
}
