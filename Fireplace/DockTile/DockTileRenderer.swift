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
        let image = renderIconImage()
        let imageView = NSImageView(image: image)
        NSApp.dockTile.contentView = imageView
        NSApp.dockTile.display()
    }

    private func renderIconImage() -> NSImage {
        let size: CGFloat = 128
        let renderer = ImageRenderer(content:
            DockIconCanvasView(state: currentState, showMarshmallow: showMarshmallow, streakDays: streakDays)
                .frame(width: size, height: size)
        )
        renderer.scale = 2.0

        if let cgImage = renderer.cgImage {
            return NSImage(cgImage: cgImage, size: CGSize(width: size, height: size))
        }
        return NSImage(size: CGSize(width: size, height: size))
    }
}
