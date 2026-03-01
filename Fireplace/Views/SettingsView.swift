import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    var soundEngine: AmbientSoundEngine

    var body: some View {
        Form {
            Section("Ambient Sound") {
                Toggle("Sound during focus", isOn: $appState.soundEnabled)

                if appState.soundEnabled {
                    ForEach(AmbientLayer.allCases) { layer in
                        SoundLayerRow(layer: layer, engine: soundEngine)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: appState.soundEnabled ? 300 : 100)
    }
}

struct SoundLayerRow: View {
    let layer: AmbientLayer
    var engine: AmbientSoundEngine

    private var isEnabled: Bool { engine.enabledLayers.contains(layer) }
    private var volume: Float { engine.volumes[layer] ?? 0 }

    var body: some View {
        HStack(spacing: 12) {
            Toggle(layer.rawValue, isOn: Binding(
                get: { isEnabled },
                set: { engine.updateLayer(layer, enabled: $0, volume: $0 ? max(volume, 0.1) : 0) }
            ))

            if isEnabled {
                Slider(value: Binding(
                    get: { volume },
                    set: { engine.updateLayer(layer, enabled: true, volume: $0) }
                ), in: 0.01...0.5)
                .frame(width: 120)
            }
        }
    }
}
