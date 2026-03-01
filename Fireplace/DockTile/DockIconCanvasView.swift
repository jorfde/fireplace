import SwiftUI

struct DockIconCanvasView: View {
    let state: FireplaceAnimationState
    var showMarshmallow: Bool = false
    var streakDays: Int = 0

    private let fps: Double = 4
    private let gridSize: Int = 32

    // Palette
    private let skyTop = Color(red: 0.06, green: 0.05, blue: 0.16)
    private let skyMid = Color(red: 0.09, green: 0.07, blue: 0.20)
    private let skyBot = Color(red: 0.12, green: 0.10, blue: 0.22)
    private let star = Color(red: 0.95, green: 0.92, blue: 0.70)
    private let grass = Color(red: 0.16, green: 0.32, blue: 0.13)
    private let grassLight = Color(red: 0.22, green: 0.42, blue: 0.18)
    private let dirt = Color(red: 0.28, green: 0.18, blue: 0.10)
    private let dirtDark = Color(red: 0.20, green: 0.13, blue: 0.07)
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

    // Layout: fill entire 32×32 grid edge-to-edge
    // Sky: rows 0-23  |  Ground: rows 24-31  |  Logs: rows 22-25  |  Fire: rows 6-22

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
            Canvas { ctx, size in
                let cw = size.width / CGFloat(gridSize)
                let ch = size.height / CGFloat(gridSize)
                let frame = Int(context.date.timeIntervalSinceReferenceDate * fps) % 4

                // Full background — edge to edge, macOS masks it
                drawSky(ctx: ctx, cw: cw, ch: ch)
                drawStars(ctx: ctx, cw: cw, ch: ch, frame: frame)
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

    // MARK: - Sky (fills entire canvas)

    private func drawSky(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let c = y < 8 ? skyTop : (y < 16 ? skyMid : skyBot)
                p(ctx, x, y, cw, ch, c)
            }
        }
    }

    // MARK: - Stars

    private func drawStars(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let positions: [(Int, Int)] = [
            (3, 2), (8, 4), (14, 1), (20, 3), (26, 2), (5, 7),
            (11, 5), (18, 6), (24, 8), (28, 5), (1, 10), (30, 4),
            (7, 11), (22, 10), (16, 8), (27, 12),
        ]
        for (i, (x, y)) in positions.enumerated() {
            let twinkle = (frame + i) % 4 == 0
            p(ctx, x, y, cw, ch, star.opacity(twinkle ? 0.4 : 0.8))
        }
    }

    // MARK: - Ground (rows 24-31, flush to bottom)

    private func drawGround(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        for x in 0..<gridSize {
            p(ctx, x, 24, cw, ch, x % 3 == 0 ? grassLight : grass)
            p(ctx, x, 25, cw, ch, grass)
        }
        for y in 26...31 {
            for x in 0..<gridSize {
                p(ctx, x, y, cw, ch, y % 2 == 0 ? dirt : dirtDark)
            }
        }
        // Tufts
        p(ctx, 3, 23, cw, ch, grass); p(ctx, 4, 23, cw, ch, grassLight)
        p(ctx, 27, 23, cw, ch, grass); p(ctx, 28, 23, cw, ch, grassLight)
    }

    // MARK: - Stone ring

    private func drawStoneRing(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        let stones: [(Int, Int, Color)] = [
            (7, 25, stoneRing), (8, 25, stoneDark), (9, 26, stoneRing),
            (22, 26, stoneRing), (23, 25, stoneDark), (24, 25, stoneRing),
            (7, 26, stoneDark), (24, 26, stoneDark),
            (6, 24, stoneDark), (6, 25, stoneRing),
            (25, 24, stoneDark), (25, 25, stoneRing),
        ]
        for (x, y, c) in stones { p(ctx, x, y, cw, ch, c) }

        if streakDays > 0 {
            let notches: [(Int, Int)] = [(7, 25), (8, 25), (9, 26), (22, 26), (23, 25), (24, 25), (7, 26)]
            for i in 0..<min(streakDays, notches.count) {
                let (x, y) = notches[i]
                p(ctx, x, y, cw, ch, stoneLight)
            }
        }
    }

    // MARK: - Logs (rows 22-25, wide)

    private func drawLogs(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Bottom horizontal log
        for x in 9...22 { p(ctx, x, 24, cw, ch, logBrown) }
        for x in 9...22 { p(ctx, x, 25, cw, ch, logDark) }
        for x in 10...21 { p(ctx, x, 23, cw, ch, logLight) }
        // Ends
        p(ctx, 8, 23, cw, ch, logEnd); p(ctx, 8, 24, cw, ch, logBrown); p(ctx, 8, 25, cw, ch, logDark)
        p(ctx, 23, 23, cw, ch, logEnd); p(ctx, 23, 24, cw, ch, logBrown); p(ctx, 23, 25, cw, ch, logDark)

        // Left leaning
        p(ctx, 9, 22, cw, ch, logDark); p(ctx, 10, 22, cw, ch, logBrown); p(ctx, 10, 21, cw, ch, logLight)
        p(ctx, 11, 22, cw, ch, logLight); p(ctx, 11, 21, cw, ch, logBrown)
        p(ctx, 12, 22, cw, ch, logBrown); p(ctx, 12, 21, cw, ch, logLight)

        // Right leaning
        p(ctx, 19, 21, cw, ch, logLight); p(ctx, 19, 22, cw, ch, logBrown)
        p(ctx, 20, 21, cw, ch, logBrown); p(ctx, 20, 22, cw, ch, logLight)
        p(ctx, 21, 22, cw, ch, logBrown); p(ctx, 22, 22, cw, ch, logDark)

        // Cross piece
        for x in 12...19 { p(ctx, x, 21, cw, ch, logLight); p(ctx, x, 22, cw, ch, logBrown) }
    }

    // MARK: - Cold ash

    private func drawColdAsh(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        for x in 13...18 { p(ctx, x, 21, cw, ch, ash) }
        p(ctx, 15, 20, cw, ch, ash.opacity(0.5))
        p(ctx, 16, 20, cw, ch, ash.opacity(0.4))
        let drift = frame % 2
        p(ctx, 15 + drift, 18, cw, ch, smoke.opacity(0.18))
        p(ctx, 16 - drift, 16, cw, ch, smoke.opacity(0.10))
    }

    // MARK: - Lighting up

    private func drawLightingUp(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int, progress: Double) {
        for x in 11...20 { p(ctx, x, 22, cw, ch, emberBright.opacity(progress)) }
        if progress > 0.25 {
            for x in 13...18 { p(ctx, x, 20, cw, ch, flameOrange.opacity(progress)) }
        }
        if progress > 0.5 {
            p(ctx, 15, 18, cw, ch, flameYellow.opacity(progress))
            p(ctx, 16, 18, cw, ch, flameOrange.opacity(progress))
            p(ctx, 13, 19, cw, ch, flameRed.opacity(progress))
            p(ctx, 18, 19, cw, ch, flameRed.opacity(progress))
        }
        if progress > 0.75 {
            p(ctx, 15, 16, cw, ch, flameYellow.opacity(progress))
            p(ctx, 16, 15, cw, ch, flameOrange.opacity(progress * 0.6))
        }
    }

    // MARK: - Fire — fills most of the icon vertically

    private func drawGroundGlow(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let a = frame % 2 == 0 ? 0.4 : 0.28
        for x in 7...24 { p(ctx, x, 26, cw, ch, warmGlow.opacity(a)) }
        for x in 9...22 { p(ctx, x, 27, cw, ch, warmGlow.opacity(a * 0.5)) }
    }

    private func drawFire(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        // Ember bed (locked)
        for x in 11...20 { p(ctx, x, 22, cw, ch, frame % 2 == 0 ? emberBright : flameOrange) }

        // Deep red base
        for x in 10...21 { p(ctx, x, 21, cw, ch, flameDeepRed) }
        for x in 11...20 { p(ctx, x, 21, cw, ch, flameRed) }
        for x in 12...19 { p(ctx, x, 21, cw, ch, flameOrange) }

        // Red outer — wide and tall
        let redFrames: [[(Int, Int)]] = [
            [(8, 19), (9, 18), (9, 20), (10, 20), (21, 20), (22, 20), (22, 18), (23, 19),
             (8, 17), (23, 17), (9, 16), (22, 16), (9, 15), (22, 15)],
            [(9, 19), (8, 18), (9, 20), (10, 20), (21, 20), (22, 20), (23, 18), (22, 19),
             (9, 17), (23, 17), (8, 16), (22, 16), (9, 15), (22, 15)],
            [(8, 19), (9, 20), (10, 20), (22, 18), (21, 20), (22, 20), (23, 19), (9, 18),
             (8, 17), (23, 17), (9, 16), (23, 16), (10, 15), (22, 15)],
            [(9, 19), (9, 20), (10, 20), (23, 18), (21, 20), (22, 20), (22, 19), (8, 18),
             (9, 17), (22, 17), (8, 16), (23, 16), (9, 15), (23, 15)],
        ]

        // Orange middle — thick
        let orangeFrames: [[(Int, Int)]] = [
            [(11, 20), (12, 20), (19, 20), (20, 20), (10, 19), (11, 19), (20, 19), (21, 19),
             (10, 18), (11, 18), (20, 18), (21, 18), (11, 17), (20, 17),
             (12, 16), (19, 16), (12, 15), (19, 15), (13, 14), (18, 14)],
            [(11, 20), (12, 20), (19, 20), (20, 20), (11, 19), (20, 19), (10, 19), (21, 19),
             (11, 18), (20, 18), (10, 18), (21, 18), (12, 17), (19, 17),
             (11, 16), (20, 16), (13, 15), (18, 15), (12, 14), (19, 14)],
            [(12, 20), (11, 20), (20, 20), (19, 20), (10, 19), (21, 19), (11, 19), (20, 19),
             (10, 18), (21, 18), (11, 18), (20, 18), (11, 17), (20, 17),
             (12, 16), (19, 16), (12, 15), (19, 15), (13, 14), (18, 14)],
            [(11, 20), (20, 20), (12, 20), (19, 20), (11, 19), (20, 19), (10, 19), (21, 19),
             (11, 18), (21, 18), (10, 18), (20, 18), (12, 17), (19, 17),
             (11, 16), (20, 16), (13, 15), (18, 15), (12, 14), (19, 14)],
        ]

        // Yellow core — tall column
        let yellowFrames: [[(Int, Int)]] = [
            [(13, 20), (14, 20), (17, 20), (18, 20), (13, 19), (14, 19), (17, 19), (18, 19),
             (13, 18), (14, 18), (17, 18), (18, 18), (13, 17), (14, 17), (17, 17), (18, 17),
             (14, 16), (17, 16), (14, 15), (17, 15), (15, 14), (16, 13)],
            [(13, 20), (14, 20), (17, 20), (18, 20), (14, 19), (17, 19), (13, 19), (18, 19),
             (14, 18), (17, 18), (13, 18), (18, 18), (14, 17), (17, 17), (13, 17), (18, 17),
             (15, 16), (16, 16), (15, 15), (16, 15), (16, 14), (15, 13)],
            [(13, 20), (14, 20), (17, 20), (18, 20), (13, 19), (18, 19), (14, 19), (17, 19),
             (13, 18), (18, 18), (14, 18), (17, 18), (13, 17), (14, 17), (17, 17), (18, 17),
             (14, 16), (17, 16), (14, 15), (17, 15), (15, 14), (16, 14), (15, 13)],
            [(13, 20), (14, 20), (17, 20), (18, 20), (14, 19), (17, 19), (13, 19), (18, 19),
             (14, 18), (17, 18), (13, 18), (18, 18), (14, 17), (17, 17), (13, 17), (18, 17),
             (15, 16), (16, 16), (15, 15), (16, 15), (15, 14), (16, 13)],
        ]

        // White hot core
        let whiteFrames: [[(Int, Int)]] = [
            [(15, 19), (16, 19), (15, 18), (16, 17), (15, 16), (16, 15)],
            [(15, 19), (16, 19), (16, 18), (15, 17), (16, 16), (15, 15)],
            [(15, 19), (16, 19), (15, 17), (16, 18), (15, 15), (16, 16)],
            [(15, 19), (16, 19), (16, 17), (15, 18), (15, 16), (16, 15)],
        ]

        // Flame tips — reach near the top
        let tipFrames: [[(Int, Int, Color)]] = [
            [(15, 12, flameYellow), (16, 11, flameOrange), (15, 10, flameRed), (16, 9, flameDeepRed), (15, 8, flameDeepRed)],
            [(16, 12, flameYellow), (15, 11, flameOrange), (16, 10, flameRed), (15, 9, flameDeepRed), (16, 8, flameDeepRed)],
            [(15, 11, flameYellow), (16, 11, flameYellow), (15, 10, flameOrange), (16, 9, flameRed), (15, 8, flameDeepRed), (16, 7, flameDeepRed)],
            [(16, 12, flameYellow), (15, 11, flameOrange), (16, 10, flameRed), (15, 9, flameDeepRed), (16, 8, flameDeepRed)],
        ]

        let f = frame % 4
        for (x, y) in redFrames[f] { p(ctx, x, y, cw, ch, flameRed) }
        for (x, y) in orangeFrames[f] { p(ctx, x, y, cw, ch, flameOrange) }
        for (x, y) in yellowFrames[f] { p(ctx, x, y, cw, ch, flameYellow) }
        for (x, y) in whiteFrames[f] { p(ctx, x, y, cw, ch, flameWhite) }
        for (x, y, c) in tipFrames[f] { p(ctx, x, y, cw, ch, c) }
    }

    // MARK: - Sparks — spread across the whole icon

    private func drawSparks(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let sparkSets: [[(Int, Int)]] = [
            [(11, 10), (21, 9), (6, 15), (25, 13), (14, 6)],
            [(22, 13), (7, 9), (24, 17), (10, 7), (19, 5)],
            [(6, 11), (23, 10), (10, 6), (21, 15), (16, 4)],
            [(24, 8), (8, 13), (19, 6), (12, 12), (26, 11)],
        ]
        for (x, y) in sparkSets[frame % 4] {
            p(ctx, x, y, cw, ch, flameYellow.opacity(0.55))
        }
    }

    // MARK: - Dying down

    private func drawDyingDown(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int, progress: Double) {
        let remaining = 1.0 - progress
        for x in 11...20 { p(ctx, x, 22, cw, ch, emberBright.opacity(0.5 + remaining * 0.5)) }
        if remaining > 0.2 {
            for x in 13...18 { p(ctx, x, 20, cw, ch, flameOrange.opacity(remaining)) }
        }
        if remaining > 0.5 {
            p(ctx, 15, 18, cw, ch, flameYellow.opacity(remaining))
            p(ctx, 16, 17, cw, ch, flameRed.opacity(remaining * 0.6))
        }
        if progress > 0.3 {
            let drift = frame % 2
            p(ctx, 15 + drift, 16, cw, ch, smoke.opacity(progress * 0.2))
            p(ctx, 16 - drift, 14, cw, ch, smoke.opacity(progress * 0.12))
        }
    }

    // MARK: - Embers

    private func drawEmberState(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let pulse: [Double] = [1.0, 0.65, 0.45, 0.8]
        let b = pulse[frame % 4]
        for x in 11...20 { p(ctx, x, 22, cw, ch, emberBright.opacity(b)) }
        for x in 12...19 { p(ctx, x, 21, cw, ch, emberDim.opacity(b * 0.6)) }
        p(ctx, 15, 20, cw, ch, emberDim.opacity(b * 0.4))
        p(ctx, 16, 20, cw, ch, emberDim.opacity(b * 0.3))
        if frame % 4 == 0 { p(ctx, 15, 19, cw, ch, flameOrange.opacity(0.3)) }
        if frame % 4 == 2 { p(ctx, 16, 19, cw, ch, flameOrange.opacity(0.2)) }
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
        p(ctx, 25, 20, cw, ch, stickBrown); p(ctx, 26, 20, cw, ch, stickBrown)
        p(ctx, 24, 19, cw, ch, stickBrown); p(ctx, 25, 19, cw, ch, stickBrown)
        let toasting = frame % 4 < 2
        p(ctx, 23, 18, cw, ch, toasting ? mallowGold : mallowWhite)
        p(ctx, 24, 18, cw, ch, mallowWhite)
        p(ctx, 23, 19, cw, ch, mallowWhite)
    }
}
