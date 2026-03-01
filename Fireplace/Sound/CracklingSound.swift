import AVFoundation
import Foundation

enum AmbientLayer: String, CaseIterable, Identifiable {
    case fire = "Crackling Fire"
    case rain = "Rain"
    case wind = "Wind"
    case whiteNoise = "White Noise"

    var id: String { rawValue }
}

@Observable
final class AmbientSoundEngine {
    private var players: [AmbientLayer: AVAudioPlayer] = [:]
    private var fadeTimers: [AmbientLayer: Timer] = [:]

    var volumes: [AmbientLayer: Float] = [
        .fire: 0.15,
        .rain: 0.0,
        .wind: 0.0,
        .whiteNoise: 0.0,
    ]

    var enabledLayers: Set<AmbientLayer> = [.fire]
    private(set) var isPlaying = false

    private let fadeDuration: TimeInterval = 1.5

    func play() {
        guard !isPlaying else { return }
        isPlaying = true

        for layer in AmbientLayer.allCases {
            if players[layer] == nil {
                let data = generateAudio(for: layer)
                players[layer] = try? AVAudioPlayer(data: data)
                players[layer]?.numberOfLoops = -1
                players[layer]?.volume = 0
                players[layer]?.prepareToPlay()
            }
        }

        for layer in enabledLayers {
            players[layer]?.play()
            fadeLayer(layer, to: volumes[layer] ?? 0)
        }
    }

    func stop() {
        guard isPlaying else { return }
        for layer in AmbientLayer.allCases {
            fadeLayer(layer, to: 0) { [weak self] in
                self?.players[layer]?.stop()
            }
        }
        isPlaying = false
    }

    func updateLayer(_ layer: AmbientLayer, enabled: Bool, volume: Float) {
        enabledLayers = enabled ? enabledLayers.union([layer]) : enabledLayers.subtracting([layer])
        volumes[layer] = volume

        if isPlaying {
            if enabled && volume > 0 {
                if players[layer]?.isPlaying != true {
                    players[layer]?.play()
                }
                fadeLayer(layer, to: volume)
            } else {
                fadeLayer(layer, to: 0) { [weak self] in
                    self?.players[layer]?.stop()
                }
            }
        }
    }

    // MARK: - Audio generation

    private func generateAudio(for layer: AmbientLayer) -> Data {
        let sampleRate: Double = 44100
        let duration: Double = 3.0
        let count = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: count)

        switch layer {
        case .fire:
            generateFire(&samples, count: count, sampleRate: sampleRate)
        case .rain:
            generateRain(&samples, count: count, sampleRate: sampleRate)
        case .wind:
            generateWind(&samples, count: count, sampleRate: sampleRate)
        case .whiteNoise:
            generateWhiteNoise(&samples, count: count)
        }

        // Low-pass smoothing
        for i in 1..<count {
            samples[i] = samples[i] * 0.3 + samples[i - 1] * 0.7
        }

        return encodeWAV(samples: samples, sampleRate: Int(sampleRate))
    }

    private func generateFire(_ samples: inout [Float], count: Int, sampleRate: Double) {
        for i in 0..<count {
            let t = Double(i) / sampleRate
            samples[i] = Float.random(in: -0.06...0.06)
            let crackleChance = sin(t * 3.7) * 0.5 + 0.5
            if Float.random(in: 0...1) < Float(crackleChance) * 0.004 {
                let burst = Int.random(in: 80...500)
                for j in i..<min(i + burst, count) {
                    let env = 1.0 - Float(j - i) / Float(burst)
                    samples[j] += Float.random(in: -0.35...0.35) * env * env
                }
            }
        }
    }

    private func generateRain(_ samples: inout [Float], count: Int, sampleRate: Double) {
        for i in 0..<count {
            // Filtered noise with occasional drip sounds
            samples[i] = Float.random(in: -0.12...0.12)
            if Float.random(in: 0...1) < 0.001 {
                let drop = Int.random(in: 20...100)
                for j in i..<min(i + drop, count) {
                    let env = 1.0 - Float(j - i) / Float(drop)
                    let freq = Float.random(in: 800...2000)
                    samples[j] += sin(Float(j) / Float(sampleRate) * freq * .pi * 2) * 0.15 * env
                }
            }
        }
        // Extra smoothing for rain
        for i in 1..<count { samples[i] = samples[i] * 0.4 + samples[i - 1] * 0.6 }
    }

    private func generateWind(_ samples: inout [Float], count: Int, sampleRate: Double) {
        var phase: Float = 0
        for i in 0..<count {
            let t = Float(i) / Float(sampleRate)
            // Slowly modulated noise
            let mod = sin(t * 0.5) * 0.5 + 0.5
            samples[i] = Float.random(in: -0.1...0.1) * (0.3 + mod * 0.7)
            // Low whoosh
            phase += (0.8 + mod * 1.2) / Float(sampleRate) * .pi * 2
            samples[i] += sin(phase) * 0.04 * mod
        }
        // Heavy smoothing
        for _ in 0..<3 {
            for i in 1..<count { samples[i] = samples[i] * 0.2 + samples[i - 1] * 0.8 }
        }
    }

    private func generateWhiteNoise(_ samples: inout [Float], count: Int) {
        for i in 0..<count {
            samples[i] = Float.random(in: -0.15...0.15)
        }
    }

    // MARK: - Fade

    private func fadeLayer(_ layer: AmbientLayer, to target: Float, completion: (() -> Void)? = nil) {
        fadeTimers[layer]?.invalidate()

        fadeTimers[layer] = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self, let player = self.players[layer] else { timer.invalidate(); return }
            let step = Float(0.05 / self.fadeDuration) * max(target, 0.15)
            if player.volume < target {
                player.volume = min(player.volume + step, target)
            } else {
                player.volume = max(player.volume - step, target)
            }
            if abs(player.volume - target) < 0.01 {
                player.volume = target
                timer.invalidate()
                self.fadeTimers[layer] = nil
                completion?()
            }
        }
    }

    // MARK: - WAV encoding

    private func encodeWAV(samples: [Float], sampleRate: Int) -> Data {
        let blockAlign = 2
        let dataSize = samples.count * blockAlign
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * blockAlign).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        for s in samples {
            let i16 = Int16(max(-1, min(1, s)) * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: i16.littleEndian) { Array($0) })
        }
        return data
    }
}
