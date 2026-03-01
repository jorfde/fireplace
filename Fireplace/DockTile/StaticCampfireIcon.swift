import SwiftUI

struct StaticCampfireIcon: View {
    private let gridSize: Int = 32

    private let skyTop = Color(red: 0.06, green: 0.05, blue: 0.16)
    private let skyMid = Color(red: 0.09, green: 0.07, blue: 0.20)
    private let skyBot = Color(red: 0.12, green: 0.10, blue: 0.22)
    private let star = Color(red: 0.95, green: 0.92, blue: 0.70)
    private let grass = Color(red: 0.16, green: 0.32, blue: 0.13)
    private let grassLight = Color(red: 0.22, green: 0.42, blue: 0.18)
    private let dirt = Color(red: 0.28, green: 0.18, blue: 0.10)
    private let dirtDark = Color(red: 0.20, green: 0.13, blue: 0.07)
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
    private let stoneRing = Color(red: 0.48, green: 0.44, blue: 0.42)
    private let stoneDark = Color(red: 0.35, green: 0.32, blue: 0.30)
    private let warmGlow = Color(red: 0.40, green: 0.15, blue: 0.05)

    var body: some View {
        Canvas { ctx, size in
            let cw = size.width / CGFloat(gridSize)
            let ch = size.height / CGFloat(gridSize)

            // Sky
            for y in 0..<gridSize {
                for x in 0..<gridSize {
                    let c = y < 8 ? skyTop : (y < 16 ? skyMid : skyBot)
                    p(ctx, x, y, cw, ch, c)
                }
            }

            // Stars
            let stars: [(Int, Int)] = [(3,2),(8,4),(14,1),(20,3),(26,2),(5,7),(11,5),(18,6),(24,8),(28,5),(1,10),(30,4)]
            for (x, y) in stars { p(ctx, x, y, cw, ch, star.opacity(0.8)) }

            // Ground
            for x in 0..<gridSize {
                p(ctx, x, 24, cw, ch, x % 3 == 0 ? grassLight : grass)
                p(ctx, x, 25, cw, ch, grass)
            }
            for y in 26...31 {
                for x in 0..<gridSize { p(ctx, x, y, cw, ch, y % 2 == 0 ? dirt : dirtDark) }
            }
            p(ctx, 3, 23, cw, ch, grass); p(ctx, 4, 23, cw, ch, grassLight)
            p(ctx, 27, 23, cw, ch, grass); p(ctx, 28, 23, cw, ch, grassLight)

            // Stone ring
            let stones: [(Int, Int, Color)] = [
                (7,25,stoneRing),(8,25,stoneDark),(9,26,stoneRing),
                (22,26,stoneRing),(23,25,stoneDark),(24,25,stoneRing),
                (7,26,stoneDark),(24,26,stoneDark),(6,24,stoneDark),(6,25,stoneRing),
                (25,24,stoneDark),(25,25,stoneRing),
            ]
            for (x,y,c) in stones { p(ctx, x, y, cw, ch, c) }

            // Logs
            for x in 9...22 { p(ctx, x, 24, cw, ch, logBrown); p(ctx, x, 25, cw, ch, logDark) }
            for x in 10...21 { p(ctx, x, 23, cw, ch, logLight) }
            p(ctx, 8, 23, cw, ch, logEnd); p(ctx, 8, 24, cw, ch, logBrown); p(ctx, 8, 25, cw, ch, logDark)
            p(ctx, 23, 23, cw, ch, logEnd); p(ctx, 23, 24, cw, ch, logBrown); p(ctx, 23, 25, cw, ch, logDark)
            for x in 12...19 { p(ctx, x, 21, cw, ch, logLight); p(ctx, x, 22, cw, ch, logBrown) }

            // Ember bed
            for x in 11...20 { p(ctx, x, 22, cw, ch, emberBright) }

            // Fire base
            for x in 10...21 { p(ctx, x, 21, cw, ch, flameDeepRed) }
            for x in 11...20 { p(ctx, x, 21, cw, ch, flameRed) }
            for x in 12...19 { p(ctx, x, 21, cw, ch, flameOrange) }

            // Red outer
            for (x,y) in [(8,19),(9,18),(9,20),(10,20),(21,20),(22,20),(22,18),(23,19),(8,17),(23,17),(9,16),(22,16),(9,15),(22,15)] {
                p(ctx, x, y, cw, ch, flameRed)
            }

            // Orange
            for (x,y) in [(11,20),(12,20),(19,20),(20,20),(10,19),(11,19),(20,19),(21,19),(10,18),(11,18),(20,18),(21,18),(11,17),(20,17),(12,16),(19,16),(12,15),(19,15),(13,14),(18,14)] {
                p(ctx, x, y, cw, ch, flameOrange)
            }

            // Yellow
            for (x,y) in [(13,20),(14,20),(17,20),(18,20),(13,19),(14,19),(17,19),(18,19),(13,18),(14,18),(17,18),(18,18),(13,17),(14,17),(17,17),(18,17),(14,16),(17,16),(14,15),(17,15),(15,14),(16,13)] {
                p(ctx, x, y, cw, ch, flameYellow)
            }

            // White hot
            for (x,y) in [(15,19),(16,19),(15,18),(16,17),(15,16),(16,15)] {
                p(ctx, x, y, cw, ch, flameWhite)
            }

            // Tips
            for (x,y,c) in [(15,12,flameYellow),(16,11,flameOrange),(15,10,flameRed),(16,9,flameDeepRed),(15,8,flameDeepRed)] as [(Int,Int,Color)] {
                p(ctx, x, y, cw, ch, c)
            }

            // Sparks
            for (x,y) in [(11,10),(21,9),(6,15),(25,13),(14,6)] {
                p(ctx, x, y, cw, ch, flameYellow.opacity(0.55))
            }

            // Ground glow
            for x in 7...24 { p(ctx, x, 26, cw, ch, warmGlow.opacity(0.35)) }
        }
    }

    private func p(_ ctx: GraphicsContext, _ x: Int, _ y: Int, _ cw: CGFloat, _ ch: CGFloat, _ color: Color) {
        ctx.fill(Path(CGRect(x: CGFloat(x) * cw, y: CGFloat(y) * ch, width: cw + 0.5, height: ch + 0.5)), with: .color(color))
    }
}
