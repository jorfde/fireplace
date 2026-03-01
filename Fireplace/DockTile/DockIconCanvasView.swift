import SwiftUI

struct DockIconCanvasView: View {
    let state: FireplaceAnimationState
    var showMarshmallow: Bool = false
    var streakDays: Int = 0

    private let fps: Double = 4
    private let gridSize: Int = 32

    // Palette
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

    private let iconBg = Color(red: 0.12, green: 0.10, blue: 0.18)

    // Ground: rows 28-31  |  Logs: rows 26-28  |  Fire: rows 8-25

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
            Canvas { ctx, size in
                let cw = size.width / CGFloat(gridSize)
                let ch = size.height / CGFloat(gridSize)
                let frame = Int(context.date.timeIntervalSinceReferenceDate * fps) % 4

                // Fill with dark background so the icon has the standard macOS shape
                let bgRect = CGRect(origin: .zero, size: size)
                ctx.fill(Path(roundedRect: bgRect, cornerSize: CGSize(width: size.width * 0.22, height: size.height * 0.22), style: .continuous), with: .color(iconBg))

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

    // MARK: - Ground (rows 28-31, flush to bottom)

    private func drawGround(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        for x in 3...28 {
            let c = x % 3 == 0 ? grassLight : (x % 5 == 0 ? grassDark : grass)
            p(ctx, x, 28, cw, ch, c)
            p(ctx, x, 29, cw, ch, grass)
        }
        p(ctx, 2, 28, cw, ch, grassDark)
        p(ctx, 29, 28, cw, ch, grassDark)

        for y in 30...31 {
            for x in 4...27 {
                p(ctx, x, y, cw, ch, y == 30 ? dirt : dirtDark)
            }
        }

        // Grass tufts
        p(ctx, 4, 27, cw, ch, grass)
        p(ctx, 5, 27, cw, ch, grassLight)
        p(ctx, 26, 27, cw, ch, grass)
        p(ctx, 27, 27, cw, ch, grassLight)
    }

    // MARK: - Stone ring

    private func drawStoneRing(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        let stones: [(Int, Int, Color)] = [
            (8, 29, stoneRing), (9, 29, stoneDark), (10, 30, stoneRing),
            (21, 30, stoneRing), (22, 29, stoneDark), (23, 29, stoneRing),
            (8, 30, stoneDark), (23, 30, stoneDark),
            (7, 28, stoneDark), (7, 29, stoneRing),
            (24, 28, stoneDark), (24, 29, stoneRing),
        ]
        for (x, y, c) in stones { p(ctx, x, y, cw, ch, c) }

        if streakDays > 0 {
            let notches: [(Int, Int)] = [(8, 29), (9, 29), (10, 30), (21, 30), (22, 29), (23, 29), (8, 30)]
            let count = min(streakDays, notches.count)
            for i in 0..<count {
                let (x, y) = notches[i]
                p(ctx, x, y, cw, ch, stoneLight)
            }
        }
    }

    // MARK: - Logs (rows 26-28)

    private func drawLogs(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Bottom horizontal log
        for x in 10...21 {
            p(ctx, x, 28, cw, ch, logBrown)
            p(ctx, x, 29, cw, ch, logDark)
        }
        for x in 11...20 {
            p(ctx, x, 27, cw, ch, logLight)
        }
        // Log ends
        p(ctx, 9, 27, cw, ch, logEnd); p(ctx, 9, 28, cw, ch, logBrown); p(ctx, 9, 29, cw, ch, logDark)
        p(ctx, 22, 27, cw, ch, logEnd); p(ctx, 22, 28, cw, ch, logBrown); p(ctx, 22, 29, cw, ch, logDark)

        // Left leaning log
        p(ctx, 10, 26, cw, ch, logDark)
        p(ctx, 11, 26, cw, ch, logBrown); p(ctx, 11, 25, cw, ch, logLight)
        p(ctx, 12, 26, cw, ch, logLight); p(ctx, 12, 25, cw, ch, logBrown)
        p(ctx, 13, 26, cw, ch, logBrown); p(ctx, 13, 25, cw, ch, logLight)

        // Right leaning log
        p(ctx, 18, 25, cw, ch, logLight); p(ctx, 18, 26, cw, ch, logBrown)
        p(ctx, 19, 25, cw, ch, logBrown); p(ctx, 19, 26, cw, ch, logLight)
        p(ctx, 20, 26, cw, ch, logBrown)
        p(ctx, 21, 26, cw, ch, logDark)

        // Cross piece
        for x in 13...18 {
            p(ctx, x, 25, cw, ch, logLight)
            p(ctx, x, 26, cw, ch, logBrown)
        }
    }

    // MARK: - Cold ash

    private func drawColdAsh(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        for x in 14...17 { p(ctx, x, 25, cw, ch, ash) }
        p(ctx, 15, 24, cw, ch, ash.opacity(0.5))
        p(ctx, 16, 24, cw, ch, ash.opacity(0.4))

        let drift = frame % 2
        p(ctx, 15 + drift, 22, cw, ch, smoke.opacity(0.18))
        p(ctx, 16 - drift, 20, cw, ch, smoke.opacity(0.10))
    }

    // MARK: - Lighting up

    private func drawLightingUp(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int, progress: Double) {
        for x in 12...19 { p(ctx, x, 26, cw, ch, emberBright.opacity(progress)) }
        if progress > 0.25 {
            for x in 14...17 { p(ctx, x, 24, cw, ch, flameOrange.opacity(progress)) }
        }
        if progress > 0.5 {
            p(ctx, 15, 22, cw, ch, flameYellow.opacity(progress))
            p(ctx, 16, 22, cw, ch, flameOrange.opacity(progress))
            p(ctx, 14, 23, cw, ch, flameRed.opacity(progress))
            p(ctx, 17, 23, cw, ch, flameRed.opacity(progress))
        }
        if progress > 0.75 {
            p(ctx, 15, 20, cw, ch, flameYellow.opacity(progress))
            p(ctx, 16, 19, cw, ch, flameOrange.opacity(progress * 0.6))
        }
    }

    // MARK: - Fire — large, fills the icon

    private func drawGroundGlow(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let a = frame % 2 == 0 ? 0.4 : 0.28
        for x in 8...23 { p(ctx, x, 30, cw, ch, warmGlow.opacity(a)) }
    }

    private func drawFire(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        // Ember bed (locked)
        for x in 12...19 { p(ctx, x, 26, cw, ch, frame % 2 == 0 ? emberBright : flameOrange) }

        // Deep red base glow
        for x in 11...20 { p(ctx, x, 25, cw, ch, flameDeepRed) }
        for x in 12...19 { p(ctx, x, 25, cw, ch, flameRed) }
        for x in 13...18 { p(ctx, x, 25, cw, ch, flameOrange) }

        // Red outer — wide
        let redFrames: [[(Int, Int)]] = [
            [(9, 23), (10, 22), (10, 24), (11, 24), (20, 24), (21, 24), (21, 22), (22, 23), (9, 21), (22, 21), (10, 20), (21, 20)],
            [(10, 23), (9, 22), (10, 24), (11, 24), (20, 24), (21, 24), (22, 22), (21, 23), (10, 21), (22, 21), (9, 20), (21, 20)],
            [(9, 23), (10, 24), (11, 24), (21, 22), (20, 24), (21, 24), (22, 23), (10, 22), (9, 21), (22, 21), (10, 20), (22, 20)],
            [(10, 23), (10, 24), (11, 24), (22, 22), (20, 24), (21, 24), (21, 23), (9, 22), (10, 21), (21, 21), (9, 20), (21, 20)],
        ]

        // Orange middle — thick
        let orangeFrames: [[(Int, Int)]] = [
            [(12, 24), (13, 24), (18, 24), (19, 24), (11, 23), (12, 23), (19, 23), (20, 23),
             (11, 22), (12, 22), (19, 22), (20, 22), (12, 21), (19, 21), (13, 20), (18, 20),
             (13, 19), (18, 19), (14, 18), (17, 18)],
            [(12, 24), (13, 24), (18, 24), (19, 24), (12, 23), (19, 23), (11, 23), (20, 23),
             (12, 22), (19, 22), (11, 22), (20, 22), (13, 21), (18, 21), (12, 20), (19, 20),
             (14, 19), (17, 19), (13, 18), (18, 18)],
            [(13, 24), (12, 24), (19, 24), (18, 24), (11, 23), (20, 23), (12, 23), (19, 23),
             (11, 22), (20, 22), (12, 22), (19, 22), (12, 21), (19, 21), (13, 20), (18, 20),
             (13, 19), (18, 19), (14, 18), (17, 18)],
            [(12, 24), (19, 24), (13, 24), (18, 24), (12, 23), (19, 23), (11, 23), (20, 23),
             (12, 22), (20, 22), (11, 22), (19, 22), (13, 21), (18, 21), (12, 20), (19, 20),
             (14, 19), (17, 19), (13, 18), (18, 18)],
        ]

        // Yellow core — tall
        let yellowFrames: [[(Int, Int)]] = [
            [(14, 24), (15, 24), (16, 24), (17, 24), (14, 23), (15, 23), (16, 23), (17, 23),
             (14, 22), (15, 22), (16, 22), (17, 22), (14, 21), (15, 21), (16, 21), (17, 21),
             (15, 20), (16, 20), (15, 19), (16, 18), (15, 17)],
            [(14, 24), (15, 24), (16, 24), (17, 24), (14, 23), (15, 23), (16, 23), (17, 23),
             (14, 22), (15, 22), (16, 22), (17, 22), (15, 21), (16, 21), (14, 21), (17, 21),
             (16, 20), (15, 20), (16, 19), (15, 18), (16, 17)],
            [(14, 24), (15, 24), (16, 24), (17, 24), (15, 23), (16, 23), (14, 23), (17, 23),
             (15, 22), (16, 22), (14, 22), (17, 22), (14, 21), (15, 21), (16, 21), (17, 21),
             (15, 20), (16, 20), (15, 19), (16, 18), (15, 17), (16, 16)],
            [(14, 24), (15, 24), (16, 24), (17, 24), (14, 23), (15, 23), (16, 23), (17, 23),
             (14, 22), (15, 22), (16, 22), (17, 22), (15, 21), (16, 21), (14, 21), (17, 21),
             (15, 20), (16, 20), (15, 19), (16, 18), (15, 17)],
        ]

        // White hot
        let whiteFrames: [[(Int, Int)]] = [
            [(15, 22), (16, 21), (15, 20), (16, 19)],
            [(16, 22), (15, 21), (16, 20), (15, 19)],
            [(15, 21), (16, 22), (15, 19), (16, 20)],
            [(16, 21), (15, 22), (16, 19), (15, 20)],
        ]

        // Flame tips — reach high
        let tipFrames: [[(Int, Int, Color)]] = [
            [(15, 16, flameYellow), (16, 15, flameOrange), (15, 14, flameRed), (16, 13, flameDeepRed), (15, 12, flameDeepRed)],
            [(16, 16, flameYellow), (15, 15, flameOrange), (16, 14, flameRed), (15, 13, flameDeepRed), (16, 12, flameDeepRed)],
            [(15, 15, flameYellow), (16, 15, flameYellow), (15, 14, flameOrange), (16, 13, flameRed), (15, 12, flameDeepRed), (16, 11, flameDeepRed)],
            [(16, 16, flameYellow), (15, 15, flameOrange), (16, 14, flameRed), (15, 13, flameDeepRed), (16, 12, flameDeepRed)],
        ]

        let f = frame % 4
        for (x, y) in redFrames[f] { p(ctx, x, y, cw, ch, flameRed) }
        for (x, y) in orangeFrames[f] { p(ctx, x, y, cw, ch, flameOrange) }
        for (x, y) in yellowFrames[f] { p(ctx, x, y, cw, ch, flameYellow) }
        for (x, y) in whiteFrames[f] { p(ctx, x, y, cw, ch, flameWhite) }
        for (x, y, c) in tipFrames[f] { p(ctx, x, y, cw, ch, c) }
    }

    // MARK: - Sparks — spread wide and high

    private func drawSparks(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let sparkSets: [[(Int, Int)]] = [
            [(12, 14), (20, 12), (8, 18), (23, 16)],
            [(21, 16), (9, 12), (23, 20), (12, 10)],
            [(8, 14), (22, 13), (11, 10), (20, 18)],
            [(23, 11), (9, 16), (18, 9), (13, 17)],
        ]
        for (x, y) in sparkSets[frame % 4] {
            p(ctx, x, y, cw, ch, flameYellow.opacity(0.55))
        }
    }

    // MARK: - Dying down

    private func drawDyingDown(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int, progress: Double) {
        let remaining = 1.0 - progress
        for x in 12...19 { p(ctx, x, 26, cw, ch, emberBright.opacity(0.5 + remaining * 0.5)) }
        if remaining > 0.2 {
            for x in 14...17 { p(ctx, x, 24, cw, ch, flameOrange.opacity(remaining)) }
        }
        if remaining > 0.5 {
            p(ctx, 15, 22, cw, ch, flameYellow.opacity(remaining))
            p(ctx, 16, 21, cw, ch, flameRed.opacity(remaining * 0.6))
        }
        if progress > 0.3 {
            let drift = frame % 2
            p(ctx, 15 + drift, 20, cw, ch, smoke.opacity(progress * 0.2))
            p(ctx, 16 - drift, 18, cw, ch, smoke.opacity(progress * 0.12))
        }
    }

    // MARK: - Embers

    private func drawEmberState(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let pulse: [Double] = [1.0, 0.65, 0.45, 0.8]
        let b = pulse[frame % 4]
        for x in 12...19 { p(ctx, x, 26, cw, ch, emberBright.opacity(b)) }
        for x in 13...18 { p(ctx, x, 25, cw, ch, emberDim.opacity(b * 0.6)) }
        p(ctx, 15, 24, cw, ch, emberDim.opacity(b * 0.4))
        p(ctx, 16, 24, cw, ch, emberDim.opacity(b * 0.3))
        if frame % 4 == 0 { p(ctx, 15, 23, cw, ch, flameOrange.opacity(0.3)) }
        if frame % 4 == 2 { p(ctx, 16, 23, cw, ch, flameOrange.opacity(0.2)) }
    }

    // MARK: - Smoke

    private func drawSmoke(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let drift = frame % 2
        p(ctx, 15 + drift, 22, cw, ch, smoke.opacity(0.18))
        p(ctx, 16 - drift, 20, cw, ch, smoke.opacity(0.12))
        p(ctx, 15 + drift, 18, cw, ch, smoke.opacity(0.06))
    }

    // MARK: - Marshmallow

    private func drawMarshmallow(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        p(ctx, 24, 24, cw, ch, stickBrown)
        p(ctx, 25, 24, cw, ch, stickBrown)
        p(ctx, 23, 23, cw, ch, stickBrown)
        p(ctx, 24, 23, cw, ch, stickBrown)
        let toasting = frame % 4 < 2
        p(ctx, 22, 22, cw, ch, toasting ? mallowGold : mallowWhite)
        p(ctx, 23, 22, cw, ch, mallowWhite)
        p(ctx, 22, 23, cw, ch, mallowWhite)
    }
}
