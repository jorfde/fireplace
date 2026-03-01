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
                    TransitionView(state: .dyingDown(progress: 0.5), label: "The fire is dying down...")
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)
                .padding(.top, 4)

            Text(label)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(20)
        }
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.top, 4)

            VStack(spacing: 14) {
                Text(taskName)
                    .font(.headline)
                    .lineLimit(1)

                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 4)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: focusTimer.progress)
                        .stroke(.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    Text(timeString)
                        .font(.system(.title2, design: .monospaced, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 0) {
                    Button("Extinguish") { appState.extinguishEarly() }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(" \u{00B7} ")
                        .font(.caption)
                        .foregroundStyle(.quaternary)

                    Button("Hide") { onClose() }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .animation(.easeInOut(duration: 1.5), value: celebrating)

            VStack(spacing: 10) {
                VStack(spacing: 6) {
                    Text("The fire has gone out")
                        .font(.headline)

                    Text("You focused for \(focusedMinutes) minute\(focusedMinutes == 1 ? "" : "s")")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.orange)
                        .opacity(textVisible ? 1 : 0)
                        .offset(y: textVisible ? 0 : 8)

                    Text("\u{201C}\(taskName)\u{201D}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if showKeepGoing {
                    // "Keep going" flow
                    VStack(spacing: 10) {
                        Text("Add more time")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach([15, 25, 45, 60], id: \.self) { mins in
                                Button {
                                    selectedMoreTime = mins
                                } label: {
                                    Text("\(mins)m")
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .foregroundStyle(selectedMoreTime == mins ? .white : .secondary)
                                        .frame(width: 44, height: 26)
                                        .background(
                                            selectedMoreTime == mins ? AnyShapeStyle(.orange) : AnyShapeStyle(.quaternary),
                                            in: RoundedRectangle(cornerRadius: 6)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button(action: {
                            if let s = session {
                                appState.sessionHistory.record(s, finished: false, journal: appState.journalEntry)
                            }
                            appState.restartWithMoreTime(duration: selectedMoreTime)
                        }) {
                            Label("Keep going", systemImage: "flame.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.regular)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    // Standard completion flow
                    Text("Did you finish?")
                        .font(.body)

                    HStack(spacing: 12) {
                        Button("Yes \u{2713}") { finishSession(finished: true) }
                            .buttonStyle(.borderedProminent)
                            .tint(.green.opacity(0.8))
                            .controlSize(.large)

                        Button("Not yet") {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showKeepGoing = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    VStack(spacing: 6) {
                        Text("How did it go?")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        TextField("One sentence...", text: $appState.journalEntry)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .padding(6)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 5))
                            .focused($isJournalFocused)
                    }

                    Button("Start another \u{2192}") { finishSession(finished: false) }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tertiary)
                        .font(.subheadline)
                }

                if appState.sessionHistory.thisWeekCount > 0 {
                    Text("\(appState.sessionHistory.thisWeekCount) sessions this week \u{00B7} \(appState.sessionHistory.thisWeekMinutes) min")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .onAppear {
            // Celebration: fade in the focus time after a brief moment
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                textVisible = true
            }
            // End celebration pulse after 2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 1)) {
                    celebrating = false
                }
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
