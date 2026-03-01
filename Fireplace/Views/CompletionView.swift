import SwiftUI

struct CompletionView: View {
    @Bindable var appState: AppState
    @FocusState private var isJournalFocused: Bool

    private var taskName: String {
        if case .completed(let session) = appState.phase {
            return session.taskName
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 16) {
            FireplaceCanvasView(state: .embers, streakDays: appState.streakDays)
                .frame(width: 130, height: 130)

            VStack(spacing: 6) {
                Text("The fire has gone out")
                    .font(.headline)

                Text("\u{201C}\(taskName)\u{201D}")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text("Did you finish?")
                .font(.body)

            HStack(spacing: 12) {
                Button("Yes ✓") {
                    appState.reset()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green.opacity(0.8))
                .controlSize(.large)

                Button("Not yet") {
                    appState.reset()
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

            Button("Start another →") {
                appState.reset()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .font(.subheadline)
        }
        .padding(20)
    }
}
