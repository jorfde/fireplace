import Foundation
import Combine

@Observable
final class FocusTimer {
    private(set) var remainingSeconds: TimeInterval = 0
    private(set) var isRunning = false
    private var cancellable: AnyCancellable?

    var onComplete: (() -> Void)?

    var progress: Double {
        guard let total = totalDuration, total > 0 else { return 0 }
        return 1.0 - (remainingSeconds / total)
    }

    private var totalDuration: TimeInterval?

    func start(duration: TimeInterval) {
        totalDuration = duration
        remainingSeconds = duration
        isRunning = true

        cancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.remainingSeconds = max(0, self.remainingSeconds - 1)
                if self.remainingSeconds <= 0 {
                    self.stop()
                    self.onComplete?()
                }
            }
    }

    func stop() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }
}
