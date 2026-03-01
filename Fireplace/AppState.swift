import SwiftUI
import Foundation

struct FocusSession {
    let taskName: String
    let duration: TimeInterval
    let startTime: Date
}

enum FocusPhase: Equatable {
    case idle
    case lightingUp(FocusSession)
    case focusing(FocusSession)
    case dyingDown(FocusSession)
    case completed(FocusSession)

    static func == (lhs: FocusPhase, rhs: FocusPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.lightingUp, .lightingUp): return true
        case (.focusing, .focusing): return true
        case (.dyingDown, .dyingDown): return true
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
    var journalEntry: String = ""
    var soundEnabled: Bool = true
    let sessionHistory = SessionHistory()

    var availableDurations: [Int] { [15, 25, 45, 60] }

    var currentTaskName: String? {
        switch phase {
        case .lightingUp(let s), .focusing(let s), .dyingDown(let s), .completed(let s):
            return s.taskName
        case .idle: return nil
        }
    }

    var currentSession: FocusSession? {
        switch phase {
        case .lightingUp(let s), .focusing(let s), .dyingDown(let s), .completed(let s):
            return s
        case .idle: return nil
        }
    }

    var isMarshmallow: Bool {
        currentTaskName?.lowercased().contains("marshmallow") == true
    }

    func startSession() {
        let session = FocusSession(
            taskName: draftTaskName.isEmpty ? "Untitled" : draftTaskName,
            duration: TimeInterval(selectedDuration * 60),
            startTime: .now
        )
        phase = .lightingUp(session)
    }

    func finishLightingUp() {
        if case .lightingUp(let session) = phase {
            phase = .focusing(session)
        }
    }

    func beginDyingDown() {
        if case .focusing(let session) = phase {
            phase = .dyingDown(session)
        }
    }

    func completeSession() {
        switch phase {
        case .focusing(let session), .dyingDown(let session):
            phase = .completed(session)
        default: break
        }
    }

    func extinguishEarly() {
        switch phase {
        case .lightingUp(let s), .focusing(let s), .dyingDown(let s):
            phase = .completed(s)
        default: break
        }
    }

    func reset() {
        draftTaskName = ""
        journalEntry = ""
        phase = .idle
    }

    func restartWithMoreTime(duration: Int) {
        if case .completed(let s) = phase {
            let newSession = FocusSession(
                taskName: s.taskName,
                duration: TimeInterval(duration * 60),
                startTime: .now
            )
            journalEntry = ""
            phase = .lightingUp(newSession)
        }
    }

    // MARK: - Streak

    var streakDays: Int {
        StreakTracker.currentStreak
    }

    func recordSessionForStreak() {
        StreakTracker.recordSession()
    }
}

enum StreakTracker {
    private static let lastDateKey = "FireplaceLastSessionDate"
    private static let streakKey = "FireplaceStreakCount"

    static var currentStreak: Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }

    static func recordSession() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        if let lastRaw = UserDefaults.standard.object(forKey: lastDateKey) as? Date {
            let lastDay = cal.startOfDay(for: lastRaw)
            let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if diff == 0 {
                return
            } else if diff == 1 {
                let streak = UserDefaults.standard.integer(forKey: streakKey) + 1
                UserDefaults.standard.set(streak, forKey: streakKey)
            } else {
                UserDefaults.standard.set(1, forKey: streakKey)
            }
        } else {
            UserDefaults.standard.set(1, forKey: streakKey)
        }
        UserDefaults.standard.set(today, forKey: lastDateKey)
    }
}
