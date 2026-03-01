import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section("Sound") {
                Toggle("Crackling sound during focus", isOn: $appState.soundEnabled)

                Text("A soft procedural crackling that fades in when the fire lights and fades out when it dies.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 140)
    }
}
