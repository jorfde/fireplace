import AVFoundation
import Foundation

@Observable
final class CracklingSound {
    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?
    private(set) var isPlaying = false

    private var volume: Float = 0.0
    private let targetVolume: Float = 0.15
    private let fadeDuration: TimeInterval = 1.5

    func play() {
        guard !isPlaying else { return }
        isPlaying = true

        if player == nil {
            generateAndPrepare()
        }

        player?.numberOfLoops = -1
        player?.volume = 0
        player?.play()
        fadeIn()
    }

    func stop() {
        guard isPlaying else { return }
        fadeOut { [weak self] in
            self?.player?.stop()
            self?.isPlaying = false
        }
    }

    private func fadeIn() {
        fadeTimer?.invalidate()
        volume = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.volume = min(self.volume + Float(0.05 / self.fadeDuration) * self.targetVolume, self.targetVolume)
            self.player?.volume = self.volume
            if self.volume >= self.targetVolume { timer.invalidate() }
        }
    }

    private func fadeOut(completion: @escaping () -> Void) {
        fadeTimer?.invalidate()

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.volume = max(self.volume - Float(0.05 / self.fadeDuration) * self.targetVolume, 0)
            self.player?.volume = self.volume
            if self.volume <= 0 {
                timer.invalidate()
                completion()
            }
        }
    }

    private func generateAndPrepare() {
        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let frameCount = Int(sampleRate * duration)

        var samples = [Float](repeating: 0, count: frameCount)

        // Procedural crackling: random bursts of filtered noise
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            // Base: very quiet pink-ish noise
            let sample = Float.random(in: -0.08...0.08)

            // Occasional crackle pops
            let crackleChance = sin(t * 3.7) * 0.5 + 0.5
            if Float.random(in: 0...1) < Float(crackleChance) * 0.003 {
                let burst = Int.random(in: 50...400)
                let burstEnd = min(i + burst, frameCount)
                for j in i..<burstEnd {
                    let env = 1.0 - Float(j - i) / Float(burst)
                    samples[j] += Float.random(in: -0.3...0.3) * env * env
                }
            }

            samples[i] += sample
        }

        // Simple low-pass smoothing
        for i in 1..<frameCount {
            samples[i] = samples[i] * 0.3 + samples[i - 1] * 0.7
        }

        // Encode as WAV
        let wavData = encodeWAV(samples: samples, sampleRate: Int(sampleRate))

        do {
            player = try AVAudioPlayer(data: wavData)
            player?.prepareToPlay()
        } catch {
            // Silently fail — sound is not critical
        }
    }

    private func encodeWAV(samples: [Float], sampleRate: Int) -> Data {
        let numChannels: Int = 1
        let bitsPerSample: Int = 16
        let byteRate = sampleRate * numChannels * bitsPerSample / 8
        let blockAlign = numChannels * bitsPerSample / 8
        let dataSize = samples.count * blockAlign

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(numChannels).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })

        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return data
    }
}
