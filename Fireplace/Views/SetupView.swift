import SwiftUI

struct SetupView: View {
    @Bindable var appState: AppState
    var onStart: () -> Void

    @FocusState private var isTaskFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            FireplaceCanvasView(state: .idle)
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
                    .focused($isTaskFieldFocused)
            }

            HStack(spacing: 8) {
                ForEach(appState.availableDurations, id: \.self) { minutes in
                    DurationChip(
                        minutes: minutes,
                        isSelected: appState.selectedDuration == minutes
                    ) {
                        appState.selectedDuration = minutes
                    }
                }
            }

            Button(action: {
                appState.startSession()
                onStart()
            }) {
                Label("Light the fire", systemImage: "flame.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)
        }
        .padding(24)
        .onAppear {
            isTaskFieldFocused = true
        }
    }
}

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
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
        }
        .buttonStyle(.plain)
    }
}


