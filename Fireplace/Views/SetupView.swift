import SwiftUI

struct SetupView: View {
    @Bindable var appState: AppState
    var onStart: () -> Void

    @FocusState private var focusedField: SetupField?

    enum SetupField: Hashable {
        case taskName
        case duration
    }

    var body: some View {
        VStack(spacing: 20) {
            FireplaceCanvasView(state: .idle, streakDays: appState.streakDays)
                .frame(width: 140, height: 140)

            VStack(spacing: 12) {
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
        .padding(24)
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
            Text("\(minutes)")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 44, height: 28)
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
