import SwiftUI

struct CompletionView: View {
    @Bindable var appState: AppState

    private var taskName: String {
        if case .completed(let session) = appState.phase {
            return session.taskName
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 20) {
            FireplaceCanvasView(state: .embers)
                .frame(width: 140, height: 140)

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

            Button("Start another →") {
                appState.reset()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .font(.subheadline)
        }
        .padding(24)
    }
}
