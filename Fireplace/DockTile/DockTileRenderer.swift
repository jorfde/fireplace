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

    // Icon spec: 1024×1024 canvas, 880×880 plate centered, ~190px corner radius
    private let canvasSize: CGFloat = 1024
    private let plateSize: CGFloat = 880
    private let plateRadius: CGFloat = 190

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
        let image = renderIconImage()
        let imageView = NSImageView(image: image)
        NSApp.dockTile.contentView = imageView
        NSApp.dockTile.display()
    }

    private func renderIconImage() -> NSImage {
        // Render the scene at plate size
        let renderer = ImageRenderer(content:
            DockIconCanvasView(state: currentState, showMarshmallow: showMarshmallow, streakDays: streakDays)
                .frame(width: plateSize, height: plateSize)
                .clipShape(RoundedRectangle(cornerRadius: plateRadius, style: .continuous))
        )
        renderer.scale = 1.0

        // Composite onto 1024×1024 transparent canvas, centered
        let finalImage = NSImage(size: CGSize(width: canvasSize, height: canvasSize))
        finalImage.lockFocus()

        // Clear to transparent
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize).fill()

        if let cgImage = renderer.cgImage {
            let plateImage = NSImage(cgImage: cgImage, size: CGSize(width: plateSize, height: plateSize))
            let inset = (canvasSize - plateSize) / 2
            plateImage.draw(in: NSRect(x: inset, y: inset, width: plateSize, height: plateSize))
        }

        finalImage.unlockFocus()
        return finalImage
    }
}

