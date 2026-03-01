import SwiftUI

struct DockIconCanvasView: View {
    let state: FireplaceAnimationState
    var showMarshmallow: Bool = false
    var streakDays: Int = 0

    private let fps: Double = 4
    private let gridSize: Int = 32

    // Palette
    private let clear = Color.clear
    private let grass = Color(red: 0.18, green: 0.35, blue: 0.15)
    private let grassLight = Color(red: 0.25, green: 0.45, blue: 0.20)
    private let grassDark = Color(red: 0.12, green: 0.25, blue: 0.10)
    private let dirt = Color(red: 0.30, green: 0.20, blue: 0.12)
    private let dirtDark = Color(red: 0.22, green: 0.15, blue: 0.08)
    private let stoneRing = Color(red: 0.48, green: 0.44, blue: 0.42)
    private let stoneDark = Color(red: 0.35, green: 0.32, blue: 0.30)
    private let stoneLight = Color(red: 0.58, green: 0.54, blue: 0.50)
    private let logBrown = Color(red: 0.45, green: 0.25, blue: 0.12)
    private let logLight = Color(red: 0.58, green: 0.35, blue: 0.18)
    private let logDark = Color(red: 0.30, green: 0.16, blue: 0.08)
    private let logEnd = Color(red: 0.38, green: 0.20, blue: 0.10)
    private let flameWhite = Color(red: 1.0, green: 0.96, blue: 0.85)
    private let flameYellow = Color(red: 1.0, green: 0.80, blue: 0.22)
    private let flameOrange = Color(red: 1.0, green: 0.48, blue: 0.12)
    private let flameRed = Color(red: 0.88, green: 0.22, blue: 0.10)
    private let flameDeepRed = Color(red: 0.65, green: 0.12, blue: 0.05)
    private let emberBright = Color(red: 1.0, green: 0.38, blue: 0.08)
    private let emberDim = Color(red: 0.65, green: 0.18, blue: 0.06)
    private let ash = Color(red: 0.42, green: 0.38, blue: 0.36)
    private let smoke = Color(red: 0.55, green: 0.52, blue: 0.55)
    private let warmGlow = Color(red: 0.40, green: 0.15, blue: 0.05)
    private let stickBrown = Color(red: 0.50, green: 0.32, blue: 0.15)
    private let mallowWhite = Color(red: 0.95, green: 0.92, blue: 0.88)
    private let mallowGold = Color(red: 0.75, green: 0.55, blue: 0.25)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
            Canvas { ctx, size in
                let cw = size.width / CGFloat(gridSize)
                let ch = size.height / CGFloat(gridSize)
                let frame = Int(context.date.timeIntervalSinceReferenceDate * fps) % 4

                // Transparent background — no fill
                drawGround(ctx: ctx, cw: cw, ch: ch)
                drawStoneRing(ctx: ctx, cw: cw, ch: ch)
                drawLogs(ctx: ctx, cw: cw, ch: ch)

                switch state {
                case .idle:
                    drawColdAsh(ctx: ctx, cw: cw, ch: ch, frame: frame)
                case .lightingUp(let progress):
                    drawLightingUp(ctx: ctx, cw: cw, ch: ch, frame: frame, progress: progress)
                case .burning:
                    drawGroundGlow(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawFire(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawSparks(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    if showMarshmallow { drawMarshmallow(ctx: ctx, cw: cw, ch: ch, frame: frame) }
                case .dyingDown(let progress):
                    drawDyingDown(ctx: ctx, cw: cw, ch: ch, frame: frame, progress: progress)
                case .embers:
                    drawEmberState(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawSmoke(ctx: ctx, cw: cw, ch: ch, frame: frame)
                }
            }
        }
    }

    private func p(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ cw: CGFloat, _ ch: CGFloat, _ color: Color) {
        let rect = CGRect(x: CGFloat(x) * cw, y: CGFloat(y) * ch, width: cw + 0.5, height: ch + 0.5)
        ctx.fill(Path(rect), with: .color(color))
    }

    // Fill a 2×2 block for chunkier elements
    private func p2(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ cw: CGFloat, _ ch: CGFloat, _ color: Color) {
        p(ctx, x, y, cw, ch, color)
        p(ctx, x+1, y, cw, ch, color)
        p(ctx, x, y+1, cw, ch, color)
        p(ctx, x+1, y+1, cw, ch, color)
    }

    // MARK: - Ground (rows 24-31, centered)

    private func drawGround(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Grass strip — rows 24-25
        for x in 4...27 {
            let c = x % 3 == 0 ? grassLight : (x % 5 == 0 ? grassDark : grass)
            p(ctx, x, 24, cw, ch, c)
            p(ctx, x, 25, cw, ch, grass)
        }
        // Tapered edges
        p(ctx, 3, 24, cw, ch, grassDark)
        p(ctx, 28, 24, cw, ch, grassDark)

        // Dirt — rows 26-29
        for y in 26...29 {
            for x in 5...26 {
                p(ctx, x, y, cw, ch, y % 2 == 0 ? dirt : dirtDark)
            }
        }

        // Grass tufts
        p(ctx, 5, 23, cw, ch, grass)
        p(ctx, 6, 23, cw, ch, grassLight)
        p(ctx, 25, 23, cw, ch, grass)
        p(ctx, 26, 23, cw, ch, grassLight)
        p(ctx, 3, 23, cw, ch, grassDark)
        p(ctx, 28, 23, cw, ch, grassDark)
    }

    // MARK: - Stone ring

    private func drawStoneRing(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Bottom arc of stones
        let bottomStones: [(Int, Int, Color)] = [
            (9, 25, stoneRing), (10, 26, stoneDark), (11, 26, stoneRing), (12, 26, stoneLight),
            (19, 26, stoneLight), (20, 26, stoneRing), (21, 26, stoneDark), (22, 25, stoneRing),
            (9, 26, stoneDark), (22, 26, stoneDark),
            // Side stones
            (8, 24, stoneDark), (8, 25, stoneRing),
            (23, 24, stoneDark), (23, 25, stoneRing),
        ]
        for (x, y, c) in bottomStones { p(ctx, x, y, cw, ch, c) }

        // Streak notches
        if streakDays > 0 {
            let notchSpots: [(Int, Int)] = [(9, 25), (10, 26), (12, 26), (19, 26), (21, 26), (22, 25), (9, 26)]
            let count = min(streakDays, notchSpots.count)
            for i in 0..<count {
                let (x, y) = notchSpots[i]
                p(ctx, x, y, cw, ch, stoneLight)
            }
        }
    }

    // MARK: - Logs (chunky, detailed)

    private func drawLogs(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Bottom horizontal log
        for x in 11...20 {
            p(ctx, x, 24, cw, ch, logBrown)
            p(ctx, x, 25, cw, ch, logDark)
        }
        for x in 12...19 {
            p(ctx, x, 23, cw, ch, logLight)
        }
        // Log ends (round detail)
        p(ctx, 10, 23, cw, ch, logEnd)
        p(ctx, 10, 24, cw, ch, logBrown)
        p(ctx, 10, 25, cw, ch, logDark)
        p(ctx, 21, 23, cw, ch, logEnd)
        p(ctx, 21, 24, cw, ch, logBrown)
        p(ctx, 21, 25, cw, ch, logDark)

        // Left leaning log /
        p(ctx, 11, 22, cw, ch, logDark)
        p(ctx, 12, 22, cw, ch, logBrown)
        p(ctx, 12, 21, cw, ch, logLight)
        p(ctx, 13, 22, cw, ch, logLight)
        p(ctx, 13, 21, cw, ch, logBrown)
        p(ctx, 14, 22, cw, ch, logBrown)
        p(ctx, 14, 21, cw, ch, logLight)

        // Right leaning log \
        p(ctx, 17, 21, cw, ch, logLight)
        p(ctx, 17, 22, cw, ch, logBrown)
        p(ctx, 18, 21, cw, ch, logBrown)
        p(ctx, 18, 22, cw, ch, logLight)
        p(ctx, 19, 22, cw, ch, logBrown)
        p(ctx, 20, 22, cw, ch, logDark)

        // Cross piece
        p(ctx, 14, 21, cw, ch, logLight)
        p(ctx, 15, 21, cw, ch, logLight)
        p(ctx, 15, 22, cw, ch, logBrown)
        p(ctx, 16, 21, cw, ch, logLight)
        p(ctx, 16, 22, cw, ch, logBrown)
        p(ctx, 17, 21, cw, ch, logLight)
    }

    // MARK: - Cold ash

    private func drawColdAsh(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        p(ctx, 14, 21, cw, ch, ash)
        p(ctx, 15, 21, cw, ch, ash)
        p(ctx, 16, 21, cw, ch, ash)
        p(ctx, 15, 20, cw, ch, ash.opacity(0.5))

        // Smoke wisp
        let drift = frame % 2
        p(ctx, 15 + drift, 18, cw, ch, smoke.opacity(0.18))
        p(ctx, 16 - drift, 16, cw, ch, smoke.opacity(0.10))
    }

    // MARK: - Lighting up

    private func drawLightingUp(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int, progress: Double) {
        for x in 13...18 {
            p(ctx, x, 22, cw, ch, emberBright.opacity(progress))
        }
        if progress > 0.25 {
            p(ctx, 15, 20, cw, ch, flameOrange.opacity(progress))
            p(ctx, 16, 20, cw, ch, flameOrange.opacity(progress))
        }
        if progress > 0.5 {
            p(ctx, 15, 19, cw, ch, flameYellow.opacity(progress))
            p(ctx, 16, 19, cw, ch, flameOrange.opacity(progress))
        }
        if progress > 0.75 {
            p(ctx, 15, 18, cw, ch, flameYellow.opacity(progress))
            p(ctx, 16, 17, cw, ch, flameOrange.opacity(progress * 0.6))
        }
    }

    // MARK: - Fire (burning) — big, layered, stable base

    private func drawGroundGlow(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let a = frame % 2 == 0 ? 0.4 : 0.28
        for x in 10...21 {
            p(ctx, x, 26, cw, ch, warmGlow.opacity(a))
        }
    }

    private func drawFire(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        // Ember bed (stable, never moves)
        for x in 13...18 {
            p(ctx, x, 22, cw, ch, frame % 2 == 0 ? emberBright : flameOrange)
        }

        // Red outer flames
        let redFrames: [[(Int, Int)]] = [
            [(11, 20), (12, 20), (19, 20), (20, 20), (11, 19), (20, 19), (12, 18), (19, 18)],
            [(12, 20), (20, 20), (11, 19), (19, 19), (11, 20), (20, 19), (12, 18), (19, 18)],
            [(11, 20), (19, 20), (12, 19), (20, 19), (20, 20), (12, 20), (11, 18), (20, 18)],
            [(12, 20), (20, 20), (11, 20), (19, 20), (12, 19), (20, 19), (11, 18), (19, 18)],
        ]

        // Orange middle
        let orangeFrames: [[(Int, Int)]] = [
            [(13, 20), (14, 20), (17, 20), (18, 20), (13, 19), (18, 19), (14, 19), (17, 19), (14, 18), (17, 18), (15, 17), (16, 17)],
            [(13, 20), (14, 20), (17, 20), (18, 20), (14, 19), (17, 19), (13, 19), (18, 19), (15, 18), (16, 18), (14, 17), (17, 17)],
            [(14, 20), (13, 20), (18, 20), (17, 20), (13, 19), (18, 19), (14, 19), (17, 19), (13, 18), (17, 18), (15, 17), (16, 17)],
            [(13, 20), (18, 20), (14, 20), (17, 20), (14, 19), (17, 19), (13, 19), (18, 19), (16, 18), (18, 18), (15, 17), (16, 17)],
        ]

        // Yellow core
        let yellowFrames: [[(Int, Int)]] = [
            [(15, 19), (16, 19), (15, 18), (16, 18), (15, 17), (16, 16)],
            [(15, 19), (16, 19), (16, 18), (15, 18), (16, 17), (15, 16)],
            [(15, 19), (16, 19), (15, 18), (16, 18), (16, 17), (15, 17), (16, 16)],
            [(15, 19), (16, 19), (15, 18), (16, 18), (15, 17), (16, 16)],
        ]

        // White hot core
        let whiteFrames: [[(Int, Int)]] = [
            [(15, 18), (16, 17)],
            [(16, 18), (15, 17)],
            [(15, 17), (16, 18)],
            [(16, 17), (15, 18)],
        ]

        // Flame tips
        let tipFrames: [[(Int, Int, Color)]] = [
            [(15, 15, flameYellow), (16, 14, flameOrange), (15, 13, flameRed), (15, 12, flameDeepRed)],
            [(16, 15, flameYellow), (15, 14, flameOrange), (16, 13, flameRed), (16, 12, flameDeepRed)],
            [(15, 14, flameYellow), (16, 14, flameYellow), (15, 13, flameOrange), (16, 12, flameRed), (15, 11, flameDeepRed)],
            [(16, 15, flameYellow), (15, 14, flameOrange), (16, 13, flameRed), (15, 12, flameDeepRed)],
        ]

        let f = frame % 4
        for (x, y) in redFrames[f] { p(ctx, x, y, cw, ch, flameRed) }
        for (x, y) in orangeFrames[f] { p(ctx, x, y, cw, ch, flameOrange) }
        for (x, y) in yellowFrames[f] { p(ctx, x, y, cw, ch, flameYellow) }
        for (x, y) in whiteFrames[f] { p(ctx, x, y, cw, ch, flameWhite) }
        for (x, y, c) in tipFrames[f] { p(ctx, x, y, cw, ch, c) }

        // Deep red at base sides
        p(ctx, 12, 21, cw, ch, flameDeepRed)
        p(ctx, 19, 21, cw, ch, flameDeepRed)
        p(ctx, 13, 21, cw, ch, flameRed)
        p(ctx, 18, 21, cw, ch, flameRed)
        for x in 14...17 { p(ctx, x, 21, cw, ch, flameOrange) }
    }

    // MARK: - Sparks

    private func drawSparks(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let sparkSets: [[(Int, Int)]] = [
            [(13, 13), (20, 12), (10, 16)],
            [(20, 15), (11, 11), (22, 17)],
            [(10, 12), (21, 14), (13, 10)],
            [(22, 11), (11, 15), (18, 10)],
        ]
        for (x, y) in sparkSets[frame % 4] {
            p(ctx, x, y, cw, ch, flameYellow.opacity(0.55))
        }
    }

    // MARK: - Dying down

    private func drawDyingDown(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int, progress: Double) {
        let remaining = 1.0 - progress

        for x in 13...18 {
            p(ctx, x, 22, cw, ch, emberBright.opacity(0.5 + remaining * 0.5))
        }
        if remaining > 0.2 {
            p(ctx, 15, 20, cw, ch, flameOrange.opacity(remaining))
            p(ctx, 16, 20, cw, ch, flameOrange.opacity(remaining))
        }
        if remaining > 0.5 {
            p(ctx, 15, 19, cw, ch, flameYellow.opacity(remaining))
            p(ctx, 16, 18, cw, ch, flameRed.opacity(remaining * 0.6))
        }
        if progress > 0.3 {
            let drift = frame % 2
            p(ctx, 15 + drift, 17, cw, ch, smoke.opacity(progress * 0.2))
            p(ctx, 16 - drift, 15, cw, ch, smoke.opacity(progress * 0.12))
        }
    }

    // MARK: - Embers

    private func drawEmberState(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let pulse: [Double] = [1.0, 0.65, 0.45, 0.8]
        let b = pulse[frame % 4]

        for x in 13...18 {
            p(ctx, x, 22, cw, ch, emberBright.opacity(b))
        }
        p(ctx, 15, 21, cw, ch, emberDim.opacity(b * 0.6))
        p(ctx, 16, 21, cw, ch, emberDim.opacity(b * 0.4))

        if frame % 4 == 0 { p(ctx, 15, 20, cw, ch, flameOrange.opacity(0.3)) }
        if frame % 4 == 2 { p(ctx, 16, 20, cw, ch, flameOrange.opacity(0.2)) }
    }

    // MARK: - Smoke

    private func drawSmoke(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let drift = frame % 2
        p(ctx, 15 + drift, 18, cw, ch, smoke.opacity(0.18))
        p(ctx, 16 - drift, 16, cw, ch, smoke.opacity(0.12))
        p(ctx, 15 + drift, 14, cw, ch, smoke.opacity(0.06))
    }

    // MARK: - Marshmallow

    private func drawMarshmallow(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        // Stick from the right
        p(ctx, 23, 20, cw, ch, stickBrown)
        p(ctx, 24, 20, cw, ch, stickBrown)
        p(ctx, 22, 19, cw, ch, stickBrown)
        p(ctx, 23, 19, cw, ch, stickBrown)

        // Marshmallow
        let toasting = frame % 4 < 2
        p(ctx, 21, 18, cw, ch, toasting ? mallowGold : mallowWhite)
        p(ctx, 22, 18, cw, ch, mallowWhite)
        p(ctx, 21, 19, cw, ch, mallowWhite)
    }
}
