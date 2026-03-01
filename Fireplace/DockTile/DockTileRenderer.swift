import AppKit
import SwiftUI

@MainActor
final class DockTileRenderer {
    private let frameInterval: TimeInterval = 0.25
    private var currentState: FireplaceAnimationState = .idle
    private var frameIndex: Int = 0
    private var animationTimer: Timer?

    func updateState(_ state: FireplaceAnimationState) {
        currentState = state

        switch state {
        case .idle:
            stopAnimation()
            renderFrame()
        case .burning, .embers:
            if animationTimer == nil { startAnimation() }
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
        let size = CGSize(width: 128, height: 128)
        let renderer = ImageRenderer(content:
            FireplaceCanvasView(state: currentState)
                .frame(width: 128, height: 128)
        )
        renderer.scale = 2.0

        if let cgImage = renderer.cgImage {
            return NSImage(cgImage: cgImage, size: size)
        }
        return NSImage(size: size)
    }
}
