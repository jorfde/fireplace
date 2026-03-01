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

// MARK: - 30-day calendar view

struct DotCalendarView: View {
    let sessions: [SessionRecord]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private var calendarDays: [CalendarDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // Go back 29 days (30 days total including today)
        guard let startDate = cal.date(byAdding: .day, value: -29, to: today) else { return [] }

        // Find the Monday on or before startDate for grid alignment
        let startWeekday = cal.component(.weekday, from: startDate)
        // weekday: 1=Sun, 2=Mon... Convert to Mon=0
        let mondayOffset = (startWeekday + 5) % 7
        guard let gridStart = cal.date(byAdding: .day, value: -mondayOffset, to: startDate) else { return [] }

        var days: [CalendarDay] = []
        var current = gridStart

        // Fill grid until we pass today
        while current <= today {
            let count = sessionCount(for: current)
            let inRange = current >= startDate && current <= today
            let isToday = cal.isDateInToday(current)
            let dayNum = cal.component(.day, from: current)
            let month = cal.component(.month, from: current)

            days.append(CalendarDay(
                date: current,
                dayNumber: dayNum,
                month: month,
                sessionCount: count,
                inRange: inRange,
                isToday: isToday
            ))

            current = cal.date(byAdding: .day, value: 1, to: current)!
        }

        return days
    }

    private var monthLabel: String {
        let cal = Calendar.current
        let today = Date.now
        guard let start = cal.date(byAdding: .day, value: -29, to: today) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        let startMonth = fmt.string(from: start)
        let endMonth = fmt.string(from: today)
        let year = cal.component(.year, from: today)
        if startMonth == endMonth {
            return "\(startMonth) \(year)"
        }
        return "\(startMonth) – \(endMonth) \(year)"
    }

    private func sessionCount(for date: Date) -> Int {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        return sessions.filter { $0.date >= dayStart && $0.date < dayEnd }.count
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(monthLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            // Day-of-week headers
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.quaternary)
                        .frame(height: 12)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(calendarDays) { day in
                    if day.inRange {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(cellColor(count: day.sessionCount))
                                .frame(height: 24)

                            Text("\(day.dayNumber)")
                                .font(.system(size: 9, weight: day.isToday ? .bold : .regular, design: .rounded))
                                .foregroundStyle(day.sessionCount > 0 ? .white : .secondary)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(day.isToday ? Color.orange.opacity(0.7) : .clear, lineWidth: 1.5)
                        )
                    } else {
                        Color.clear.frame(height: 24)
                    }
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private func cellColor(count: Int) -> Color {
        switch count {
        case 0: return .secondary.opacity(0.08)
        case 1: return .orange.opacity(0.35)
        case 2: return .orange.opacity(0.55)
        default: return .orange.opacity(0.8)
        }
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let month: Int
    let sessionCount: Int
    let inRange: Bool
    let isToday: Bool
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
