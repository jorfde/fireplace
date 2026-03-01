import AppKit
import SwiftUI

final class PanelController {
    private var panel: FloatingPanel?
    private let appState: AppState
    private let focusTimer: FocusTimer
    private var clickMonitor: Any?

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
        startClickMonitor()
    }

    func hidePanel() {
        panel?.orderOut(nil)
        stopClickMonitor()
    }

    func togglePanel() {
        if let panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func startClickMonitor() {
        stopClickMonitor()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.panel, panel.isVisible else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                self.hidePanel()
            }
        }
    }

    private func stopClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
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
    @State private var showingHistory = false

    var body: some View {
        Group {
            if showingHistory {
                HistoryView(sessions: appState.sessionHistory.sessions) {
                    showingHistory = false
                }
            } else {
                switch appState.phase {
                case .idle:
                    SetupView(appState: appState, onStart: onClose, onShowHistory: { showingHistory = true })
                case .lightingUp:
                    TransitionView(state: .lightingUp(progress: 0.5), label: "Lighting the fire...")
                case .focusing:
                    FocusingView(appState: appState, focusTimer: focusTimer, onClose: onClose)
                case .dyingDown:
                    TransitionView(state: .dyingDown(progress: 0.5), label: "Winding down\u{2026}")
                case .completed:
                    CompletionView(appState: appState)
                }
            }
        }
        .frame(width: 280, height: 380)
    }
}

struct TransitionView: View {
    let state: FireplaceAnimationState
    let label: String

    var body: some View {
        VStack(spacing: 0) {
            FireplaceCanvasView(state: state)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .padding(.horizontal, 12)
                .padding(.top, 4)
            Spacer()
            PixelText(text: label, pixelSize: 2, color: PixelTheme.textDim)
            Spacer()
        }
        .background(PixelTheme.bg)
    }
}

struct FocusingView: View {
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
        VStack(spacing: 0) {
            FireplaceCanvasView(
                state: .burning,
                showMarshmallow: appState.isMarshmallow,
                streakDays: appState.streakDays,
                timeProgress: focusTimer.progress
            )
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .padding(.horizontal, 12)
            .padding(.top, 4)

            VStack(spacing: 12) {
                PixelText(text: taskName, pixelSize: 2, color: PixelTheme.text)

                PixelProgressBar(progress: focusTimer.progress, timeString: timeString)
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    PixelButton(label: "Stop", color: PixelTheme.cardBg, textColor: PixelTheme.textDim, pixelSize: 1.5) {
                        appState.extinguishEarly()
                    }

                    Button(action: { appState.soundEnabled.toggle() }) {
                        PixelText(
                            text: appState.soundEnabled ? "SND" : "---",
                            pixelSize: 1.2,
                            color: appState.soundEnabled ? PixelTheme.accent : PixelTheme.textDim
                        )
                    }
                    .buttonStyle(.plain)

                    PixelButton(label: "Hide", color: PixelTheme.cardBg, textColor: PixelTheme.textDim, pixelSize: 1.5) {
                        onClose()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(PixelTheme.bg)
    }
}

struct CompletionView: View {
    @Bindable var appState: AppState
    @FocusState private var isJournalFocused: Bool
    @State private var showKeepGoing = false
    @State private var selectedMoreTime = 15
    @State private var celebrating = true
    @State private var textVisible = false

    private var taskName: String {
        if case .completed(let s) = appState.phase { return s.taskName }
        return ""
    }

    private var session: FocusSession? {
        if case .completed(let s) = appState.phase { return s }
        return nil
    }

    private var focusedMinutes: Int {
        guard let s = session else { return 0 }
        return Int(min(Date.now.timeIntervalSince(s.startTime), s.duration) / 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            FireplaceCanvasView(state: .embers, streakDays: appState.streakDays)
                .frame(maxWidth: .infinity)
                .frame(height: celebrating ? 140 : 130)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .animation(.easeInOut(duration: 1.5), value: celebrating)

            VStack(spacing: 10) {
                VStack(spacing: 6) {
                    PixelText(text: "Burned for \(focusedMinutes) min", pixelSize: 2, color: PixelTheme.accent)
                        .opacity(textVisible ? 1 : 0)
                        .offset(y: textVisible ? 0 : 8)

                    PixelText(text: taskName, pixelSize: 1.5, color: PixelTheme.textDim)
                }

                if showKeepGoing {
                    VStack(spacing: 10) {
                        PixelText(text: "Add more time", pixelSize: 1.5, color: PixelTheme.textDim)

                        HStack(spacing: 6) {
                            ForEach([15, 25, 45, 60], id: \.self) { mins in
                                PixelChip(label: "\(mins)m", isSelected: selectedMoreTime == mins) {
                                    selectedMoreTime = mins
                                }
                            }
                        }

                        PixelButton(label: "Keep going", color: PixelTheme.accent, pixelSize: 2, fullWidth: true) {
                            if let s = session {
                                appState.sessionHistory.record(s, finished: false, journal: appState.journalEntry)
                            }
                            appState.restartWithMoreTime(duration: selectedMoreTime)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    PixelText(text: "How'd it go?", pixelSize: 2, color: PixelTheme.text)

                    HStack(spacing: 8) {
                        PixelButton(label: "Finished", color: PixelTheme.success, pixelSize: 1.5) {
                            finishSession(finished: true)
                        }

                        PixelButton(label: "More time", color: PixelTheme.cardBg, textColor: PixelTheme.text, pixelSize: 1.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showKeepGoing = true
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        PixelText(text: "Any thoughts?", pixelSize: 1.2, color: PixelTheme.textDim)

                        PixelTextField(placeholder: "One sentence...", text: $appState.journalEntry)
                            .focused($isJournalFocused)
                    }
                }

                if appState.sessionHistory.thisWeekCount > 0 {
                    PixelText(
                        text: "\(appState.sessionHistory.thisWeekCount) sessions . \(appState.sessionHistory.thisWeekMinutes) min",
                        pixelSize: 1.2,
                        color: PixelTheme.textDim,
                        opacity: 0.5
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(PixelTheme.bg)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) { textVisible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 1)) { celebrating = false }
            }
        }
    }

    private func finishSession(finished: Bool) {
        if let s = session {
            appState.sessionHistory.record(s, finished: finished, journal: appState.journalEntry)
        }
        appState.reset()
    }
}
