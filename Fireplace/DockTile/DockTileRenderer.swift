import AppKit
import SwiftUI

@MainActor
final class DockTileRenderer {
    private let frameInterval: TimeInterval = 0.25
    private var currentState: FireplaceAnimationState = .idle
    private var showMarshmallow = false
    private var streakDays = 0
    private var frameIndex: Int = 0
    private var animationTimer: Timer?

    func updateState(_ state: FireplaceAnimationState, marshmallow: Bool = false, streak: Int = 0) {
        currentState = state
        showMarshmallow = marshmallow
        streakDays = streak

        switch state {
        case .idle:
            stopAnimation()
            renderFrame()
        case .burning, .embers, .lightingUp, .dyingDown:
            if animationTimer == nil { startAnimation() }
            renderFrame()
        }
    }

    private func startAnimation() {
        stopAnimation()
        animationTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.frameIndex = ((self?.frameIndex ?? 0) + 1) % 4
                self?.renderFrame()
            }
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func renderFrame() {
        let image = renderFireplaceToImage()
        let imageView = NSImageView(image: image)
        NSApp.dockTile.contentView = imageView
        NSApp.dockTile.display()
    }

    private func renderFireplaceToImage() -> NSImage {
        let tileSize = CGSize(width: 128, height: 128)
        let canvasSize: CGFloat = 96
        let renderer = ImageRenderer(content:
            FireplaceCanvasView(state: currentState, showMarshmallow: showMarshmallow, streakDays: streakDays)
                .frame(width: canvasSize, height: canvasSize)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        )
        renderer.scale = 2.0

        let finalImage = NSImage(size: tileSize)
        finalImage.lockFocus()

        if let cgImage = renderer.cgImage {
            let insetImage = NSImage(cgImage: cgImage, size: CGSize(width: canvasSize, height: canvasSize))
            let origin = NSPoint(x: (tileSize.width - canvasSize) / 2, y: (tileSize.height - canvasSize) / 2)
            insetImage.draw(in: NSRect(origin: origin, size: CGSize(width: canvasSize, height: canvasSize)))
        }

        finalImage.isTemplate = false
        finalImage.unlockFocus()
        return finalImage
    }
}
