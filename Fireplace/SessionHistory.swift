import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let taskName: String
    let duration: TimeInterval
    let date: Date
    var finished: Bool
    var journalEntry: String

    init(taskName: String, duration: TimeInterval, finished: Bool = false, journalEntry: String = "") {
        self.id = UUID()
        self.taskName = taskName
        self.duration = duration
        self.date = .now
        self.finished = finished
        self.journalEntry = journalEntry
    }

    var durationMinutes: Int { Int(duration / 60) }
}

@Observable
final class SessionHistory {
    private(set) var sessions: [SessionRecord] = []
    private let key = "FireplaceSessionHistory"

    init() { load() }

    var thisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date > weekAgo }.count
    }

    var thisWeekMinutes: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date > weekAgo }.reduce(0) { $0 + $1.durationMinutes }
    }

    func record(_ session: FocusSession, finished: Bool, journal: String) {
        let actualDuration = min(Date.now.timeIntervalSince(session.startTime), session.duration)
        let record = SessionRecord(
            taskName: session.taskName,
            duration: actualDuration,
            finished: finished,
            journalEntry: journal
        )
        sessions.insert(record, at: 0)
        if sessions.count > 100 { sessions = Array(sessions.prefix(100)) }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data)
        else { return }
        sessions = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
