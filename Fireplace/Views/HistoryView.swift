import SwiftUI

struct HistoryView: View {
    let sessions: [SessionRecord]
    var onBack: () -> Void

    private var groupedByDay: [(String, [SessionRecord])] {
        let cal = Calendar.current
        let formatter = DateFormatter()

        var groups: [(String, [SessionRecord])] = []
        var currentKey = ""
        var currentGroup: [SessionRecord] = []

        for session in sessions {
            if cal.isDateInToday(session.date) {
                formatter.dateFormat = "'Today'"
            } else if cal.isDateInYesterday(session.date) {
                formatter.dateFormat = "'Yesterday'"
            } else {
                formatter.dateFormat = "EEEE, MMM d"
            }
            let key = formatter.string(from: session.date)

            if key != currentKey {
                if !currentGroup.isEmpty {
                    groups.append((currentKey, currentGroup))
                }
                currentKey = key
                currentGroup = [session]
            } else {
                currentGroup.append(session)
            }
        }
        if !currentGroup.isEmpty {
            groups.append((currentKey, currentGroup))
        }
        return groups
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("History")
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 50, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if sessions.isEmpty {
                Spacer()
                Text("No sessions yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        DotCalendarView(sessions: sessions)
                            .padding(.horizontal, 12)

                        ForEach(Array(groupedByDay.enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.0)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)

                                ForEach(group.1) { session in
                                    SessionRow(session: session)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

// MARK: - 30-day dot calendar

struct DotCalendarView: View {
    let sessions: [SessionRecord]

    private let days = 30
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var activeDays: Set<Int> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var active = Set<Int>()
        for session in sessions {
            let sessionDay = cal.startOfDay(for: session.date)
            if let diff = cal.dateComponents([.day], from: sessionDay, to: today).day, diff >= 0, diff < days {
                active.insert(diff)
            }
        }
        return active
    }

    private func sessionCount(daysAgo: Int) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let targetDay = cal.date(byAdding: .day, value: -daysAgo, to: today) else { return 0 }
        let nextDay = cal.date(byAdding: .day, value: 1, to: targetDay)!
        return sessions.filter { $0.date >= targetDay && $0.date < nextDay }.count
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Last 30 days")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach((0..<days).reversed(), id: \.self) { daysAgo in
                    let count = sessionCount(daysAgo: daysAgo)
                    Circle()
                        .fill(dotColor(count: count))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private func dotColor(count: Int) -> Color {
        switch count {
        case 0: return .secondary.opacity(0.15)
        case 1: return .orange.opacity(0.4)
        case 2: return .orange.opacity(0.65)
        default: return .orange.opacity(0.9)
        }
    }
}

// MARK: - Session row

struct SessionRow: View {
    let session: SessionRecord

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.taskName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Spacer()

                Text(session.finished ? "\u{2713}" : "\u{2717}")
                    .font(.caption)
                    .foregroundStyle(session.finished ? .green : .secondary)
            }

            HStack {
                Text(dateString)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text("\u{00B7}")
                    .foregroundStyle(.quaternary)

                Text("\(session.durationMinutes)m")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if !session.journalEntry.isEmpty {
                    Text("\u{00B7}")
                        .foregroundStyle(.quaternary)

                    Text(session.journalEntry)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
    }
}
