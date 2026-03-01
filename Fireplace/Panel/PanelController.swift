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

    private var canvasState: FireplaceAnimationState {
        switch appState.phase {
        case .idle: return .idle
        case .lightingUp: return .lightingUp(progress: 0.5)
        case .focusing: return .burning
        case .dyingDown: return .dyingDown(progress: 0.5)
        case .completed: return .embers
        }
    }

    var body: some View {
        ZStack {
            FireplaceCanvasView(
                state: canvasState,
                showMarshmallow: appState.isMarshmallow,
                streakDays: appState.streakDays,
                timeProgress: focusTimer.progress
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                Group {
                    switch appState.phase {
                    case .idle:
                        SetupOverlay(appState: appState, onStart: onClose)
                    case .lightingUp:
                        LightingUpOverlay()
                    case .focusing:
                        FocusingOverlay(appState: appState, focusTimer: focusTimer, onClose: onClose)
                    case .dyingDown:
                        DyingDownOverlay()
                    case .completed:
                        CompletionOverlay(appState: appState)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280, height: 400)
    }
}

// MARK: - Overlay views (float on top of the campfire scene)

struct SetupOverlay: View {
    @Bindable var appState: AppState
    var onStart: () -> Void
    @FocusState private var focusedField: SetupField?

    enum SetupField: Hashable { case taskName, duration }

    var body: some View {
        VStack(spacing: 10) {
            Text("What are you working on?")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)

            TextField("Name your task", text: $appState.draftTaskName)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(8)
                .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(.white)
                .focused($focusedField, equals: .taskName)
                .onSubmit { focusedField = .duration }

            HStack(spacing: 8) {
                ForEach(appState.availableDurations, id: \.self) { minutes in
                    Button { appState.selectedDuration = minutes } label: {
                        Text("\(minutes)")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 28)
                            .background(
                                appState.selectedDuration == minutes ? Color.orange : Color.white.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .focused($focusedField, equals: .duration)
            .onKeyPress(.leftArrow) { moveDuration(by: -1); return .handled }
            .onKeyPress(.rightArrow) { moveDuration(by: 1); return .handled }
            .onKeyPress(.return) {
                if focusedField == .duration { appState.startSession(); onStart(); return .handled }
                return .ignored
            }

            Button(action: { appState.startSession(); onStart() }) {
                Label("Light the fire", systemImage: "flame.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: .command)

            if appState.streakDays > 0 {
                Text("\(appState.streakDays) day streak \u{1F525}")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .onAppear { focusedField = .taskName }
    }

    private func moveDuration(by offset: Int) {
        let d = appState.availableDurations
        guard let i = d.firstIndex(of: appState.selectedDuration) else { return }
        appState.selectedDuration = d[max(0, min(d.count - 1, i + offset))]
    }
}

struct LightingUpOverlay: View {
    var body: some View {
        Text("Lighting the fire...")
            .font(.headline)
            .foregroundStyle(.white.opacity(0.8))
            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FocusingOverlay: View {
    @Bindable var appState: AppState
    var focusTimer: FocusTimer
    var onClose: () -> Void

    private var taskName: String {
        if case .focusing(let s) = appState.phase { return s.taskName }
        return ""
    }

    private var timeString: String {
        let t = Int(focusTimer.remainingSeconds)
        return "\(t / 60):\(String(format: "%02d", t % 60))"
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("Your current task is")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)

            Text(taskName)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 3)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: focusTimer.progress)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                Text(timeString)
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 16) {
                Button("Extinguish") { appState.extinguishEarly() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                Button("Hide") { onClose() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DyingDownOverlay: View {
    var body: some View {
        Text("The fire is dying down...")
            .font(.headline)
            .foregroundStyle(.white.opacity(0.8))
            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CompletionOverlay: View {
    @Bindable var appState: AppState
    @FocusState private var isJournalFocused: Bool

    private var taskName: String {
        if case .completed(let s) = appState.phase { return s.taskName }
        return ""
    }

    private var session: FocusSession? {
        if case .completed(let s) = appState.phase { return s }
        return nil
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("The fire has gone out")
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)

            Text("\u{201C}\(taskName)\u{201D}")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)

            Text("Did you finish?")
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                Button("Yes \u{2713}") { finishSession(finished: true) }
                    .buttonStyle(.borderedProminent)
                    .tint(.green.opacity(0.8))
                    .controlSize(.regular)

                Button("Not yet") { finishSession(finished: false) }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.3))
                    .controlSize(.regular)
            }

            TextField("How did it go?", text: $appState.journalEntry)
                .textFieldStyle(.plain)
                .font(.caption)
                .padding(6)
                .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 5))
                .foregroundStyle(.white)
                .focused($isJournalFocused)

            Button("Start another \u{2192}") { finishSession(finished: false) }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.3))
                .font(.caption)

            if appState.sessionHistory.thisWeekCount > 0 {
                Text("\(appState.sessionHistory.thisWeekCount) sessions this week \u{00B7} \(appState.sessionHistory.thisWeekMinutes) min")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    private func finishSession(finished: Bool) {
        if let s = session {
            appState.sessionHistory.record(s, finished: finished, journal: appState.journalEntry)
        }
        appState.reset()
    }
}
