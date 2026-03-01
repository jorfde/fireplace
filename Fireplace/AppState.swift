import SwiftUI

struct FocusSession {
    let taskName: String
    let duration: TimeInterval
    let startTime: Date
}

enum FocusPhase: Equatable {
    case idle
    case focusing(FocusSession)
    case completed(FocusSession)

    static func == (lhs: FocusPhase, rhs: FocusPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.focusing, .focusing): return true
        case (.completed, .completed): return true
        default: return false
        }
    }
}

@Observable
final class AppState {
    var phase: FocusPhase = .idle
    var draftTaskName: String = ""
    var selectedDuration: Int = 25

    var availableDurations: [Int] { [15, 25, 45, 60] }

    func startSession() {
        let session = FocusSession(
            taskName: draftTaskName.isEmpty ? "Untitled" : draftTaskName,
            duration: TimeInterval(selectedDuration * 60),
            startTime: .now
        )
        phase = .focusing(session)
    }

    func completeSession() {
        if case .focusing(let session) = phase {
            phase = .completed(session)
        }
    }

    func reset() {
        draftTaskName = ""
        phase = .idle
    }
}
