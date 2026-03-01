import SwiftUI

struct HistoryView: View {
    let sessions: [SessionRecord]
    var onBack: () -> Void

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

                // Balance the back button
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
                    LazyVStack(spacing: 1) {
                        ForEach(sessions) { session in
                            SessionRow(session: session)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: SessionRecord

    private var dateString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(session.date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(session.date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
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
