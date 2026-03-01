import SwiftUI

enum FireplaceAnimationState {
    case idle
    case burning
    case embers
}

struct FireplaceCanvasView: View {
    let state: FireplaceAnimationState

    private let fps: Double = 4
    private let gridSize: Int = 16

    // Cute campfire palette — warm & saturated, GBA-era
    private let skyTop = Color(red: 0.05, green: 0.05, blue: 0.15)
    private let skyBot = Color(red: 0.08, green: 0.07, blue: 0.18)
    private let star = Color(red: 0.95, green: 0.92, blue: 0.70)
    private let grass = Color(red: 0.18, green: 0.35, blue: 0.15)
    private let grassLight = Color(red: 0.25, green: 0.45, blue: 0.20)
    private let dirt = Color(red: 0.30, green: 0.20, blue: 0.12)
    private let stoneRing = Color(red: 0.45, green: 0.42, blue: 0.40)
    private let stoneDark = Color(red: 0.32, green: 0.30, blue: 0.28)
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

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
            Canvas { ctx, size in
                let cw = size.width / CGFloat(gridSize)
                let ch = size.height / CGFloat(gridSize)
                let frame = Int(context.date.timeIntervalSinceReferenceDate * fps) % 4

                drawSky(ctx: ctx, cw: cw, ch: ch, frame: frame)
                drawGround(ctx: ctx, cw: cw, ch: ch)
                drawStoneRing(ctx: ctx, cw: cw, ch: ch)
                drawLogs(ctx: ctx, cw: cw, ch: ch)

                switch state {
                case .idle:
                    drawColdAsh(ctx: ctx, cw: cw, ch: ch, frame: frame)
                case .burning:
                    drawGroundGlow(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawFire(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawSparks(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawStars(ctx: ctx, cw: cw, ch: ch, glow: true, frame: frame)
                case .embers:
                    drawEmberState(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawSmoke(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawStars(ctx: ctx, cw: cw, ch: ch, glow: false, frame: frame)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func p(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ cw: CGFloat, _ ch: CGFloat, _ color: Color) {
        let rect = CGRect(x: CGFloat(x) * cw, y: CGFloat(y) * ch, width: cw + 0.5, height: ch + 0.5)
        ctx.fill(Path(rect), with: .color(color))
    }

    // MARK: - Sky

    private func drawSky(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                p(ctx, x, y, cw, ch, y < 6 ? skyTop : skyBot)
            }
        }
        // Stars only drawn in idle (burning/embers draw their own)
        if state == .idle {
            drawStars(ctx: ctx, cw: cw, ch: ch, glow: false, frame: frame)
        }
    }

    private func drawStars(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, glow: Bool, frame: Int) {
        let positions: [(Int, Int)] = [(2, 1), (12, 2), (5, 3), (14, 0), (9, 1), (0, 4)]
        for (i, (x, y)) in positions.enumerated() {
            let twinkle = (frame + i) % 4 == 0
            p(ctx, x, y, cw, ch, star.opacity(twinkle ? 0.5 : 0.85))
        }
        // One bright star
        if glow {
            p(ctx, 2, 1, cw, ch, star.opacity(frame % 2 == 0 ? 1.0 : 0.7))
        }
    }

    // MARK: - Ground

    private func drawGround(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Grass line
        for x in 0..<gridSize {
            p(ctx, x, 12, cw, ch, x % 3 == 0 ? grassLight : grass)
        }
        // Dirt under campfire
        for x in 0..<gridSize {
            p(ctx, x, 13, cw, ch, dirt)
            p(ctx, x, 14, cw, ch, dirt)
            p(ctx, x, 15, cw, ch, dirt)
        }
        // Grass tufts
        p(ctx, 1, 11, cw, ch, grass)
        p(ctx, 2, 11, cw, ch, grassLight)
        p(ctx, 13, 11, cw, ch, grass)
        p(ctx, 14, 11, cw, ch, grassLight)
    }

    // MARK: - Stone ring

    private func drawStoneRing(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        let stones: [(Int, Int, Color)] = [
            (4, 12, stoneRing), (5, 13, stoneDark), (6, 13, stoneRing),
            (9, 13, stoneDark), (10, 13, stoneRing), (11, 12, stoneDark),
            (4, 13, stoneRing), (11, 13, stoneRing),
        ]
        for (x, y, c) in stones { p(ctx, x, y, cw, ch, c) }
    }

    // MARK: - Logs (cute crossed arrangement)

    private func drawLogs(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Left log (leaning right) /
        p(ctx, 5, 12, cw, ch, logDark)
        p(ctx, 6, 11, cw, ch, logBrown)
        p(ctx, 6, 12, cw, ch, logLight)
        p(ctx, 7, 11, cw, ch, logBrown)
        p(ctx, 7, 12, cw, ch, logBrown)

        // Right log (leaning left) \
        p(ctx, 8, 11, cw, ch, logBrown)
        p(ctx, 8, 12, cw, ch, logBrown)
        p(ctx, 9, 11, cw, ch, logBrown)
        p(ctx, 9, 12, cw, ch, logLight)
        p(ctx, 10, 12, cw, ch, logDark)

        // Cross piece on top
        p(ctx, 7, 11, cw, ch, logLight)
        p(ctx, 8, 11, cw, ch, logLight)
    }

    // MARK: - Cold ash (idle)

    private func drawColdAsh(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        p(ctx, 7, 11, cw, ch, ash)
        p(ctx, 8, 11, cw, ch, ash)
        p(ctx, 7, 10, cw, ch, ash.opacity(0.5))

        // Cute tiny smoke wisp drifting
        let drift = frame % 2
        p(ctx, 7 + drift, 9, cw, ch, smoke.opacity(0.2))
        p(ctx, 8 - drift, 8, cw, ch, smoke.opacity(0.12))
    }

    // MARK: - Ground glow (burning)

    private func drawGroundGlow(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let glowAlpha = frame % 2 == 0 ? 0.5 : 0.35
        for x in 5...10 {
            p(ctx, x, 13, cw, ch, warmGlow.opacity(glowAlpha))
        }
        p(ctx, 4, 12, cw, ch, warmGlow.opacity(0.15))
        p(ctx, 11, 12, cw, ch, warmGlow.opacity(0.15))
        // Light on grass
        p(ctx, 3, 12, cw, ch, warmGlow.opacity(0.08))
        p(ctx, 12, 12, cw, ch, warmGlow.opacity(0.08))
    }

    // MARK: - Fire (burning) — big, warm, cheerful

    private func drawFire(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        // Ember base
        for x in 6...9 {
            p(ctx, x, 11, cw, ch, frame % 2 == 0 ? emberBright : flameOrange)
        }

        // Red outer
        let redFrames: [[(Int, Int)]] = [
            [(5, 10), (10, 10), (5, 9), (10, 9), (6, 10), (9, 10)],
            [(6, 10), (10, 10), (5, 9), (10, 9), (5, 10), (9, 10)],
            [(5, 10), (9, 10), (6, 9), (10, 9), (10, 10), (6, 10)],
            [(6, 10), (10, 10), (5, 10), (9, 10), (5, 9), (10, 9)],
        ]
        for (x, y) in redFrames[frame % 4] { p(ctx, x, y, cw, ch, flameRed) }

        // Orange middle
        let orangeFrames: [[(Int, Int)]] = [
            [(7, 10), (8, 10), (6, 9), (9, 9), (7, 9), (8, 9), (7, 8), (8, 8)],
            [(7, 10), (8, 10), (7, 9), (8, 9), (6, 9), (9, 9), (8, 8), (7, 8)],
            [(7, 10), (8, 10), (6, 9), (9, 9), (7, 9), (8, 9), (6, 8), (8, 8)],
            [(7, 10), (8, 10), (7, 9), (8, 9), (6, 9), (9, 9), (9, 8), (7, 8)],
        ]
        for (x, y) in orangeFrames[frame % 4] { p(ctx, x, y, cw, ch, flameOrange) }

        // Yellow core
        let yellowFrames: [[(Int, Int)]] = [
            [(7, 9), (8, 9), (7, 8), (8, 7)],
            [(7, 9), (8, 9), (8, 8), (7, 7)],
            [(8, 9), (7, 8), (8, 8), (8, 7), (7, 7)],
            [(7, 9), (8, 8), (7, 8), (7, 7)],
        ]
        for (x, y) in yellowFrames[frame % 4] { p(ctx, x, y, cw, ch, flameYellow) }

        // White-hot dancing pixel
        let whitePositions: [(Int, Int)] = [(7, 8), (8, 7), (8, 8), (7, 7)]
        let (wx, wy) = whitePositions[frame % 4]
        p(ctx, wx, wy, cw, ch, flameWhite)

        // Flame tip reaching up
        let tips: [[(Int, Int, Color)]] = [
            [(7, 6, flameYellow), (8, 5, flameOrange), (7, 4, flameRed)],
            [(8, 6, flameYellow), (7, 5, flameOrange), (8, 4, flameRed)],
            [(7, 6, flameYellow), (8, 6, flameOrange), (7, 5, flameOrange), (8, 4, flameRed)],
            [(8, 6, flameYellow), (7, 6, flameOrange), (8, 5, flameOrange), (7, 4, flameRed)],
        ]
        for (x, y, c) in tips[frame % 4] { p(ctx, x, y, cw, ch, c) }
    }

    // MARK: - Sparks

    private func drawSparks(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let sparkSets: [[(Int, Int)]] = [
            [(6, 5), (10, 4), (4, 7)],
            [(10, 6), (5, 3), (11, 8)],
            [(4, 4), (11, 5), (6, 3)],
            [(11, 3), (5, 6), (9, 3)],
        ]
        for (x, y) in sparkSets[frame % 4] {
            p(ctx, x, y, cw, ch, flameYellow.opacity(0.6))
        }
    }

    // MARK: - Embers (completed)

    private func drawEmberState(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let pulse: [Double] = [1.0, 0.65, 0.45, 0.8]
        let b = pulse[frame % 4]

        // Glowing ember bed
        for x in 6...9 {
            p(ctx, x, 11, cw, ch, emberBright.opacity(b))
        }
        // Dim warmth above
        p(ctx, 7, 10, cw, ch, emberDim.opacity(b * 0.6))
        p(ctx, 8, 10, cw, ch, emberDim.opacity(b * 0.4))

        // Tiny flicker on some frames
        if frame % 4 == 0 { p(ctx, 7, 9, cw, ch, flameOrange.opacity(0.35)) }
        if frame % 4 == 2 { p(ctx, 8, 9, cw, ch, flameOrange.opacity(0.25)) }

        // Subtle ground glow
        for x in 6...9 {
            p(ctx, x, 13, cw, ch, warmGlow.opacity(b * 0.2))
        }
    }

    // MARK: - Smoke wisps (embers)

    private func drawSmoke(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let drift = frame % 2
        p(ctx, 7 + drift, 8, cw, ch, smoke.opacity(0.2))
        p(ctx, 8 - drift, 7, cw, ch, smoke.opacity(0.15))
        p(ctx, 7 + drift, 6, cw, ch, smoke.opacity(0.08))
    }
}
