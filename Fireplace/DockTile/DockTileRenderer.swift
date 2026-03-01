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

    private let iconSize: CGFloat = 1024

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
        NSApp.applicationIconImage = image
    }

    private func renderIconImage() -> NSImage {
        let renderer = ImageRenderer(content:
            DockIconCanvasView(state: currentState, showMarshmallow: showMarshmallow, streakDays: streakDays)
                .frame(width: iconSize, height: iconSize)
        )
        renderer.scale = 1.0

        if let cgImage = renderer.cgImage {
            return NSImage(cgImage: cgImage, size: CGSize(width: iconSize, height: iconSize))
        }
        return NSImage(size: CGSize(width: iconSize, height: iconSize))
    }
}
