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
            // Toolbar row — sits in the transparent title bar area
            HStack {
                Spacer()
                if !appState.sessionHistory.sessions.isEmpty, let onShowHistory {
                    Button(action: { onShowHistory() }) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)

            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Text("What are you working on?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Name your task", text: $appState.draftTaskName)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                        .focused($focusedField, equals: .taskName)
                        .onSubmit { focusedField = .duration }
                }

                HStack(spacing: 8) {
                    ForEach(appState.availableDurations, id: \.self) { minutes in
                        DurationChip(
                            minutes: minutes,
                            isSelected: appState.selectedDuration == minutes,
                            isFocused: focusedField == .duration && appState.selectedDuration == minutes
                        ) {
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
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .onAppear { focusedField = .taskName }
    }

    private func moveDuration(by offset: Int) {
        let d = appState.availableDurations
        guard let i = d.firstIndex(of: appState.selectedDuration) else { return }
        appState.selectedDuration = d[max(0, min(d.count - 1, i + offset))]
    }
}

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    var isFocused: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 50, height: 28)
                .background(
                    isSelected ? AnyShapeStyle(.orange) : AnyShapeStyle(.quaternary),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isFocused ? Color.orange.opacity(0.6) : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
