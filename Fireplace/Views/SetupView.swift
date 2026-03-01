import SwiftUI

struct SetupView: View {
    @Bindable var appState: AppState
    var onStart: () -> Void
    var onShowHistory: (() -> Void)? = nil

    @FocusState private var focusedField: SetupField?

    enum SetupField: Hashable {
        case taskName
        case duration
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Spacer()
                if !appState.sessionHistory.sessions.isEmpty, let onShowHistory {
                    Button(action: { onShowHistory() }) {
                        PixelText(text: "...", pixelSize: 1.5, color: PixelTheme.textDim)
                    }
                    .buttonStyle(.plain)
                    .help("Session history")
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 20)
            .padding(.bottom, 8)

            FireplaceCanvasView(state: .idle, streakDays: appState.streakDays)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .padding(.horizontal, 12)

            VStack(spacing: 14) {
                PixelText(text: "What's on your mind?", pixelSize: 1.5, color: PixelTheme.textDim)

                PixelTextField(placeholder: "Name your task", text: $appState.draftTaskName)
                    .focused($focusedField, equals: .taskName)
                    .onSubmit { focusedField = .duration }

                HStack(spacing: 6) {
                    ForEach(appState.availableDurations, id: \.self) { minutes in
                        PixelChip(label: "\(minutes)m", isSelected: appState.selectedDuration == minutes) {
                            appState.selectedDuration = minutes
                        }
                    }
                }
                .focused($focusedField, equals: .duration)
                .onKeyPress(.leftArrow) { moveDuration(by: -1); return .handled }
                .onKeyPress(.rightArrow) { moveDuration(by: 1); return .handled }
                .onKeyPress(.return) {
                    if focusedField == .duration { appState.startSession(); onStart(); return .handled }
                    return .ignored
                }

                PixelButton(label: "Light the fire", color: PixelTheme.accent, pixelSize: 2, fullWidth: true) {
                    appState.startSession()
                    onStart()
                }

                if appState.streakDays > 0 {
                    PixelText(text: "\(appState.streakDays) day streak", pixelSize: 1.2, color: PixelTheme.accent, opacity: 0.6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(PixelTheme.bg)
        .onAppear { focusedField = .taskName }
    }

    private func moveDuration(by offset: Int) {
        let d = appState.availableDurations
        guard let i = d.firstIndex(of: appState.selectedDuration) else { return }
        appState.selectedDuration = d[max(0, min(d.count - 1, i + offset))]
    }
}
