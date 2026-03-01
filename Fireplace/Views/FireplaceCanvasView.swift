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

    // GBA Pokémon palette — warm, saturated, chunky
    private let bgDark = Color(red: 0.08, green: 0.05, blue: 0.10)       // night sky
    private let bgMid = Color(red: 0.14, green: 0.09, blue: 0.16)        // indoor shadow
    private let stone = Color(red: 0.45, green: 0.40, blue: 0.42)        // hearth stone
    private let stoneDark = Color(red: 0.30, green: 0.27, blue: 0.30)    // stone shadow
    private let stoneLight = Color(red: 0.58, green: 0.53, blue: 0.50)   // stone highlight
    private let brickRed = Color(red: 0.55, green: 0.22, blue: 0.18)     // brick accent
    private let logBrown = Color(red: 0.40, green: 0.22, blue: 0.10)     // log dark
    private let logLight = Color(red: 0.55, green: 0.33, blue: 0.15)     // log highlight
    private let logBark = Color(red: 0.30, green: 0.16, blue: 0.08)      // bark shadow
    private let flameWhite = Color(red: 1.0, green: 0.95, blue: 0.80)    // flame hottest
    private let flameYellow = Color(red: 1.0, green: 0.78, blue: 0.20)   // flame bright
    private let flameOrange = Color(red: 1.0, green: 0.45, blue: 0.10)   // flame mid
    private let flameRed = Color(red: 0.85, green: 0.20, blue: 0.08)     // flame outer
    private let emberBright = Color(red: 1.0, green: 0.35, blue: 0.05)   // ember hot
    private let emberDim = Color(red: 0.70, green: 0.18, blue: 0.05)     // ember cool
    private let ash = Color(red: 0.38, green: 0.34, blue: 0.32)          // cold ash
    private let ashLight = Color(red: 0.48, green: 0.44, blue: 0.40)     // ash highlight
    private let warmGlow = Color(red: 0.30, green: 0.12, blue: 0.05)     // ambient glow on floor

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
            Canvas { ctx, size in
                let cw = size.width / CGFloat(gridSize)
                let ch = size.height / CGFloat(gridSize)
                let frame = Int(context.date.timeIntervalSinceReferenceDate * fps) % 4

                drawBackground(ctx: ctx, cw: cw, ch: ch)
                drawHearth(ctx: ctx, cw: cw, ch: ch)
                drawLogs(ctx: ctx, cw: cw, ch: ch)

                switch state {
                case .idle:
                    drawIdleAsh(ctx: ctx, cw: cw, ch: ch, frame: frame)
                case .burning:
                    drawFloorGlow(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawBurningFire(ctx: ctx, cw: cw, ch: ch, frame: frame)
                    drawSparks(ctx: ctx, cw: cw, ch: ch, frame: frame)
                case .embers:
                    drawDyingEmbers(ctx: ctx, cw: cw, ch: ch, frame: frame)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func p(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ cw: CGFloat, _ ch: CGFloat, _ color: Color) {
        let rect = CGRect(x: CGFloat(x) * cw, y: CGFloat(y) * ch, width: cw + 0.5, height: ch + 0.5)
        ctx.fill(Path(rect), with: .color(color))
    }

    // MARK: - Background

    private func drawBackground(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                p(ctx, x, y, cw, ch, y < 8 ? bgDark : bgMid)
            }
        }
    }

    // MARK: - Hearth (stone fireplace frame)

    private func drawHearth(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Back wall of fireplace
        for x in 3...12 { p(ctx, x, 8, cw, ch, stoneDark) }
        for x in 3...12 { p(ctx, x, 9, cw, ch, stoneDark) }

        // Floor / base platform
        for x in 2...13 { p(ctx, x, 14, cw, ch, stone) }
        for x in 2...13 { p(ctx, x, 15, cw, ch, stoneDark) }

        // Left pillar
        for y in 8...13 {
            p(ctx, 2, y, cw, ch, stone)
            p(ctx, 3, y, cw, ch, y % 2 == 0 ? brickRed : stone)
        }

        // Right pillar
        for y in 8...13 {
            p(ctx, 12, y, cw, ch, y % 2 == 1 ? brickRed : stone)
            p(ctx, 13, y, cw, ch, stone)
        }

        // Top mantle
        for x in 2...13 { p(ctx, x, 7, cw, ch, stoneLight) }
        for x in 1...14 { p(ctx, x, 6, cw, ch, stone) }
        p(ctx, 1, 7, cw, ch, stone)
        p(ctx, 14, 7, cw, ch, stone)

        // Highlight on mantle edge
        p(ctx, 3, 6, cw, ch, stoneLight)
        p(ctx, 5, 6, cw, ch, stoneLight)
        p(ctx, 8, 6, cw, ch, stoneLight)
        p(ctx, 11, 6, cw, ch, stoneLight)
    }

    // MARK: - Logs (cute chunky logs sitting in the hearth)

    private func drawLogs(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat) {
        // Bottom log — thick, horizontal
        for x in 5...10 { p(ctx, x, 13, cw, ch, logBrown) }
        for x in 5...10 { p(ctx, x, 12, cw, ch, logLight) }
        p(ctx, 5, 12, cw, ch, logBark)
        p(ctx, 10, 12, cw, ch, logBark)
        // Log end rings (cute detail)
        p(ctx, 4, 12, cw, ch, logBrown)
        p(ctx, 4, 13, cw, ch, logBark)
        p(ctx, 11, 12, cw, ch, logBrown)
        p(ctx, 11, 13, cw, ch, logBark)

        // Top-left angled log
        p(ctx, 5, 11, cw, ch, logBark)
        p(ctx, 6, 11, cw, ch, logBrown)
        p(ctx, 6, 10, cw, ch, logLight)
        p(ctx, 7, 11, cw, ch, logLight)

        // Top-right angled log
        p(ctx, 9, 11, cw, ch, logBrown)
        p(ctx, 10, 11, cw, ch, logBark)
        p(ctx, 9, 10, cw, ch, logLight)
        p(ctx, 8, 11, cw, ch, logLight)
    }

    // MARK: - Idle: cold hearth with ash

    private func drawIdleAsh(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        p(ctx, 6, 11, cw, ch, ash)
        p(ctx, 7, 11, cw, ch, ashLight)
        p(ctx, 8, 11, cw, ch, ash)
        p(ctx, 7, 10, cw, ch, ash)
        p(ctx, 8, 10, cw, ch, ashLight)
        // Tiny smoke wisp that drifts (cute idle detail)
        let smokeX = 7 + (frame % 2)
        let smokeY = 9 - (frame / 2)
        if smokeY >= 6 {
            p(ctx, smokeX, smokeY, cw, ch, ash.opacity(0.3))
        }
    }

    // MARK: - Burning: full Pokémon-style fire

    private func drawFloorGlow(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        for x in 4...11 {
            p(ctx, x, 14, cw, ch, warmGlow.opacity(frame % 2 == 0 ? 0.6 : 0.4))
        }
        p(ctx, 3, 13, cw, ch, warmGlow.opacity(0.2))
        p(ctx, 12, 13, cw, ch, warmGlow.opacity(0.2))
    }

    private func drawBurningFire(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        // Ember bed at the base
        let emberBase: [(Int, Int)] = [(6, 11), (7, 11), (8, 11), (9, 11)]
        for (x, y) in emberBase {
            p(ctx, x, y, cw, ch, frame % 2 == 0 ? emberBright : flameOrange)
        }

        // Red outer flame — shifts each frame for that GBA flicker
        let redPatterns: [[(Int, Int)]] = [
            [(5, 10), (6, 10), (9, 10), (10, 10), (5, 9), (10, 9)],
            [(5, 10), (6, 10), (10, 10), (9, 10), (6, 9), (10, 9)],
            [(6, 10), (5, 10), (9, 10), (10, 10), (5, 9), (9, 9)],
            [(5, 10), (10, 10), (6, 10), (9, 10), (6, 9), (10, 9)],
        ]
        for (x, y) in redPatterns[frame % 4] {
            p(ctx, x, y, cw, ch, flameRed)
        }

        // Orange mid flame
        let orangePatterns: [[(Int, Int)]] = [
            [(7, 10), (8, 10), (6, 9), (9, 9), (7, 9), (8, 9), (7, 8), (8, 8)],
            [(7, 10), (8, 10), (7, 9), (8, 9), (6, 9), (9, 9), (8, 8), (7, 8)],
            [(7, 10), (8, 10), (7, 9), (8, 9), (9, 9), (6, 8), (7, 8), (8, 8)],
            [(7, 10), (8, 10), (7, 9), (8, 9), (6, 9), (8, 8), (9, 8), (7, 8)],
        ]
        for (x, y) in orangePatterns[frame % 4] {
            p(ctx, x, y, cw, ch, flameOrange)
        }

        // Yellow bright core
        let yellowPatterns: [[(Int, Int)]] = [
            [(7, 9), (8, 9), (7, 8), (8, 7)],
            [(7, 9), (8, 9), (8, 8), (7, 7)],
            [(8, 9), (7, 8), (8, 8), (8, 7)],
            [(7, 9), (8, 8), (7, 8), (7, 7)],
        ]
        for (x, y) in yellowPatterns[frame % 4] {
            p(ctx, x, y, cw, ch, flameYellow)
        }

        // White-hot center pixel (dances around)
        let whitePatterns: [[(Int, Int)]] = [
            [(7, 8)],
            [(8, 8)],
            [(8, 7)],
            [(7, 7)],
        ]
        for (x, y) in whitePatterns[frame % 4] {
            p(ctx, x, y, cw, ch, flameWhite)
        }

        // Flame tip — reaches up high
        let tipPatterns: [[(Int, Int, Color)]] = [
            [(7, 7, flameYellow), (8, 6, flameOrange), (7, 5, flameRed)],
            [(8, 7, flameYellow), (7, 6, flameOrange), (8, 5, flameRed)],
            [(7, 6, flameYellow), (8, 6, flameYellow), (7, 5, flameOrange), (8, 4, flameRed)],
            [(8, 7, flameYellow), (8, 6, flameOrange), (7, 5, flameRed)],
        ]
        for (x, y, c) in tipPatterns[frame % 4] {
            p(ctx, x, y, cw, ch, c)
        }
    }

    private func drawSparks(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        let sparkPatterns: [[(Int, Int)]] = [
            [(6, 6), (9, 5)],
            [(9, 7), (6, 4)],
            [(5, 5), (10, 6)],
            [(10, 4), (5, 7)],
        ]
        for (x, y) in sparkPatterns[frame % 4] {
            p(ctx, x, y, cw, ch, flameYellow.opacity(0.7))
        }
    }

    // MARK: - Embers: dying fire with pulsing glow

    private func drawDyingEmbers(ctx: GraphicsContext, cw: CGFloat, ch: CGFloat, frame: Int) {
        // Warm glow on floor
        for x in 5...10 {
            p(ctx, x, 14, cw, ch, warmGlow.opacity(frame % 3 == 0 ? 0.3 : 0.15))
        }

        // Ember bed pulsing
        let brightness: [Double] = [1.0, 0.7, 0.5, 0.8]
        let b = brightness[frame % 4]

        let emberPositions: [(Int, Int)] = [(6, 11), (7, 11), (8, 11), (9, 11)]
        for (x, y) in emberPositions {
            p(ctx, x, y, cw, ch, emberBright.opacity(b))
        }

        // A couple glowing pixels above
        p(ctx, 7, 10, cw, ch, emberDim.opacity(b * 0.7))
        p(ctx, 8, 10, cw, ch, emberDim.opacity(b * 0.5))

        // Tiny last flame flicker on some frames
        if frame % 4 == 0 {
            p(ctx, 7, 9, cw, ch, flameOrange.opacity(0.4))
        } else if frame % 4 == 2 {
            p(ctx, 8, 9, cw, ch, flameOrange.opacity(0.3))
        }

        // Thin smoke wisps rising
        let smokeX = frame % 2 == 0 ? 7 : 8
        p(ctx, smokeX, 8, cw, ch, ash.opacity(0.25))
        p(ctx, smokeX + (frame % 2 == 0 ? 0 : -1), 7, cw, ch, ash.opacity(0.15))
    }
}
