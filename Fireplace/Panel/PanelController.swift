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
            case .focusing:
                FocusingView(onClose: onClose)
            case .completed:
                CompletionView(appState: appState)
            }
        }
        .frame(width: 280, height: 360)
    }
}

struct FocusingView: View {
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            FireplaceCanvasView(state: .burning)
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
