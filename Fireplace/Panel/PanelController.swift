import AppKit
import SwiftUI

final class PanelController {
    private var panel: FloatingPanel?
    private let appState: AppState
    private let focusTimer: FocusTimer

    init(appState: AppState, focusTimer: FocusTimer) {
        self.appState = appState
        self.focusTimer = focusTimer
    }

    func showPanel() {
        if panel == nil {
            let contentRect = NSRect(x: 0, y: 0, width: 280, height: 380)
            let newPanel = FloatingPanel(contentRect: contentRect)

            let hostingView = NSHostingView(
                rootView: PanelContentView(appState: appState, focusTimer: focusTimer, onClose: { [weak self] in
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
        let panelSize = panel?.frame.size ?? NSSize(width: 280, height: 380)

        // Determine Dock position and place panel above the app's Dock icon.
        // Use mouse location as a proxy — applicationShouldHandleReopen fires from
        // a Dock click, so the cursor is over the icon at that moment.
        let mouseLocation = NSEvent.mouseLocation

        let dockOnBottom = visibleFrame.minY > screenFrame.minY + 4
        let dockOnLeft = visibleFrame.minX > screenFrame.minX + 4
        let dockOnRight = visibleFrame.maxX < screenFrame.maxX - 4

        var x: CGFloat
        var y: CGFloat

        if dockOnBottom {
            x = mouseLocation.x - panelSize.width / 2
            y = visibleFrame.minY + 8
        } else if dockOnLeft {
            x = visibleFrame.minX + 8
            y = mouseLocation.y - panelSize.height / 2
        } else if dockOnRight {
            x = visibleFrame.maxX - panelSize.width - 8
            y = mouseLocation.y - panelSize.height / 2
        } else {
            // Fallback: bottom-center
            x = screenFrame.midX - panelSize.width / 2
            y = screenFrame.minY + 80
        }

        // Clamp to screen bounds
        x = max(screenFrame.minX + 8, min(x, screenFrame.maxX - panelSize.width - 8))
        y = max(screenFrame.minY + 8, min(y, screenFrame.maxY - panelSize.height - 8))

        panel?.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct PanelContentView: View {
    @Bindable var appState: AppState
    var focusTimer: FocusTimer
    var onClose: () -> Void

    var body: some View {
        Group {
            switch appState.phase {
            case .idle:
                SetupView(appState: appState, onStart: onClose)
            case .lightingUp:
                LightingUpView()
            case .focusing:
                FocusingView(appState: appState, focusTimer: focusTimer, onClose: onClose)
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
    var focusTimer: FocusTimer
    var onClose: () -> Void

    private var taskName: String {
        if case .focusing(let session) = appState.phase { return session.taskName }
        return ""
    }

    private var timeString: String {
        let total = Int(focusTimer.remainingSeconds)
        let mins = total / 60
        let secs = total % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }

    var body: some View {
        VStack(spacing: 14) {
            FireplaceCanvasView(state: .burning, showMarshmallow: appState.isMarshmallow, streakDays: appState.streakDays)
                .frame(width: 140, height: 140)

            VStack(spacing: 4) {
                Text("Your current task is")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)

                Text(taskName)
                    .font(.headline)
                    .lineLimit(1)
            }

            // Progress ring with time remaining
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 3)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: focusTimer.progress)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                Text(timeString)
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Button("Extinguish early") {
                appState.extinguishEarly()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundStyle(.secondary)

            Button("Hide") {
                onClose()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .font(.subheadline)
        }
        .padding(20)
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
