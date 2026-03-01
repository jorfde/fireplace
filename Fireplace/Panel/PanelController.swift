import AppKit
import SwiftUI

final class PanelController {
    private var panel: FloatingPanel?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func showPanel() {
        if panel == nil {
            let contentRect = NSRect(x: 0, y: 0, width: 280, height: 360)
            let newPanel = FloatingPanel(contentRect: contentRect)

            let hostingView = NSHostingView(
                rootView: PanelContentView(appState: appState, onClose: { [weak self] in
                    self?.hidePanel()
                })
            )
            newPanel.contentView = hostingView
            panel = newPanel
        }

        positionPanel()
        panel?.makeKeyAndOrderFront(nil)
    }

    func hidePanel() {
        panel?.orderOut(nil)
    }

    func togglePanel() {
        if let panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func positionPanel() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let panelSize = panel?.frame.size ?? NSSize(width: 280, height: 360)

        let dockHeight = visibleFrame.minY - screenFrame.minY
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.minY + dockHeight + 20

        panel?.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct PanelContentView: View {
    @Bindable var appState: AppState
    var onClose: () -> Void

    var body: some View {
        Group {
            switch appState.phase {
            case .idle:
                SetupView(appState: appState, onStart: onClose)
            case .lightingUp:
                LightingUpView()
            case .focusing:
                FocusingView(appState: appState, onClose: onClose)
            case .dyingDown:
                DyingDownView()
            case .completed:
                CompletionView(appState: appState)
            }
        }
        .frame(width: 280, height: 380)
    }
}

struct LightingUpView: View {
    var body: some View {
        VStack(spacing: 16) {
            FireplaceCanvasView(state: .lightingUp(progress: 0.5))
                .frame(width: 160, height: 160)

            Text("Lighting the fire...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}

struct FocusingView: View {
    @Bindable var appState: AppState
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            FireplaceCanvasView(state: .burning, showMarshmallow: appState.isMarshmallow, streakDays: appState.streakDays)
                .frame(width: 160, height: 160)

            Text("The fire is burning...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Hide") {
                onClose()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .font(.subheadline)
        }
        .padding(24)
    }
}

struct DyingDownView: View {
    var body: some View {
        VStack(spacing: 16) {
            FireplaceCanvasView(state: .dyingDown(progress: 0.5))
                .frame(width: 160, height: 160)

            Text("The fire is dying down...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}
