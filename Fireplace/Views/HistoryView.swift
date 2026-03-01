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
                    PixelText(text: "< Back", pixelSize: 1.5, color: PixelTheme.textDim)
                }
                .buttonStyle(.plain)

                Spacer()

                PixelText(text: "History", pixelSize: 2, color: PixelTheme.text)

                Spacer()

                Color.clear.frame(width: 50, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if sessions.isEmpty {
                Spacer()
                PixelText(text: "No sessions yet", pixelSize: 1.5, color: PixelTheme.textDim)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        DotCalendarView(sessions: sessions)
                            .padding(.horizontal, 12)

                        ForEach(Array(groupedByDay.enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 4) {
                                PixelText(text: group.0, pixelSize: 1.2, color: PixelTheme.textDim)
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
        .background(PixelTheme.bg)
    }
}

// MARK: - 30-day calendar view

struct DotCalendarView: View {
    let sessions: [SessionRecord]

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private struct Cell: Identifiable {
        let id: Int
        let dayNumber: Int
        let sessionCount: Int
        let isToday: Bool
        let isEmpty: Bool
    }

    private var monthLabel: String {
        let cal = Calendar.current
        let today = Date.now
        // Use a week into the range to avoid single-day edge months
        guard let meaningful = cal.date(byAdding: .day, value: -22, to: today) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        let startMonth = fmt.string(from: meaningful)
        let endMonth = fmt.string(from: today)
        let year = cal.component(.year, from: today)
        return startMonth == endMonth ? "\(startMonth) \(year)" : "\(startMonth) – \(endMonth) \(year)"
    }

    private var cells: [Cell] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let rangeStart = cal.date(byAdding: .day, value: -29, to: today) else { return [] }

        // Weekday of rangeStart: convert to Mon=0..Sun=6
        let wd = cal.component(.weekday, from: rangeStart) // 1=Sun..7=Sat
        let mondayIndex = (wd + 5) % 7 // Mon=0, Tue=1, ..., Sun=6

        var result: [Cell] = []

        // Leading empty cells to align first day to correct column
        for i in 0..<mondayIndex {
            result.append(Cell(id: -(i + 1), dayNumber: 0, sessionCount: 0, isToday: false, isEmpty: true))
        }

        // 30 actual days
        for offset in 0..<30 {
            guard let date = cal.date(byAdding: .day, value: offset, to: rangeStart) else { continue }
            let dayStart = cal.startOfDay(for: date)
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
            let count = sessions.filter { $0.date >= dayStart && $0.date < dayEnd }.count
            let dayNum = cal.component(.day, from: date)
            let isToday = cal.isDateInToday(date)
            result.append(Cell(id: offset, dayNumber: dayNum, sessionCount: count, isToday: isToday, isEmpty: false))
        }

        return result
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(monthLabel)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(PixelTheme.textDim)
                Spacer()
            }

            // Weekday headers
            HStack(spacing: 2) {
                ForEach(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(PixelTheme.textDim)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: cols, spacing: 3) {
                ForEach(cells) { cell in
                    if cell.isEmpty {
                        Color.clear.frame(height: 24)
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(cellColor(count: cell.sessionCount))
                                .frame(height: 24)

                            Text("\(cell.dayNumber)")
                                .font(.system(size: 9, weight: cell.isToday ? .bold : .regular, design: .monospaced))
                                .foregroundStyle(cell.sessionCount > 0 ? PixelTheme.text : PixelTheme.textDim)
                        }
                        .overlay(pixelBorder(color: cell.isToday ? PixelTheme.accent : PixelTheme.border.opacity(0.3)))
                    }
                }
            }
        }
        .padding(10)
        .background(PixelTheme.cardBg)
        .overlay(pixelBorder(color: PixelTheme.border))
    }

    private func cellColor(count: Int) -> Color {
        switch count {
        case 0: return PixelTheme.bg
        case 1: return PixelTheme.accent.opacity(0.35)
        case 2: return PixelTheme.accent.opacity(0.55)
        default: return PixelTheme.accent.opacity(0.8)
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
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(PixelTheme.text)
                    .lineLimit(1)

                Spacer()

                Text(session.finished ? "\u{2713}" : "\u{2717}")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(session.finished ? PixelTheme.success : PixelTheme.textDim)
            }

            HStack {
                Text(dateString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(PixelTheme.textDim)

                Text("\u{00B7}")
                    .foregroundStyle(PixelTheme.border)

                Text("\(session.durationMinutes)m")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(PixelTheme.textDim)

                if !session.journalEntry.isEmpty {
                    Text("\u{00B7}")
                        .foregroundStyle(PixelTheme.border)

                    Text(session.journalEntry)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(PixelTheme.text.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(PixelTheme.cardBg)
        .overlay(pixelBorder(color: PixelTheme.border.opacity(0.5)))
    }
}
