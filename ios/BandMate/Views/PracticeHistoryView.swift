import SwiftUI
import SwiftData

struct PracticeHistoryView: View {
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @State private var selectedSession: PracticeSession?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Practice History")
            .sheet(item: $selectedSession) { session in
                if let feedback = session.feedback {
                    let instrument = Instrument(rawValue: session.instrument) ?? .trumpet
                    let level = SkillLevel(rawValue: session.skillLevel) ?? .beginner
                    NavigationStack {
                        PracticeReportView(
                            feedback: feedback,
                            instrument: instrument,
                            skillLevel: level
                        ) {
                            selectedSession = nil
                        }
                        .navigationTitle("Report")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    selectedSession = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.mic")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No Practice Sessions Yet")
                .font(.title3.bold())
            Text("Record yourself practicing to see your results and progress here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionsList: some View {
        List {
            if !sessions.isEmpty {
                statsHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            ForEach(sessions) { session in
                Button {
                    selectedSession = session
                } label: {
                    SessionRow(session: session)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteSessions)
        }
        .listStyle(.insetGrouped)
    }

    private var statsHeader: some View {
        let avgScore = sessions.isEmpty ? 0 : sessions.map(\.overallScore).reduce(0, +) / sessions.count
        let totalDuration = sessions.map(\.duration).reduce(0, +)

        return HStack(spacing: 12) {
            StatCard(
                icon: "flame.fill",
                value: "\(sessions.count)",
                label: "Sessions",
                color: .orange
            )
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                value: "\(avgScore)",
                label: "Avg Score",
                color: .blue
            )
            StatCard(
                icon: "clock.fill",
                value: formatTotalTime(totalDuration),
                label: "Total Time",
                color: .green
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }

    private func formatTotalTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

struct SessionRow: View {
    let session: PracticeSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text("\(session.overallScore)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(scoreColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.songTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: instrumentIcon)
                            .font(.caption2)
                        Text(session.instrument)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(session.skillLevel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(formatDuration(session.duration))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 4)
    }

    private var scoreColor: Color {
        switch session.overallScore {
        case 80...100: .green
        case 60..<80: .blue
        case 40..<60: .orange
        default: .red
        }
    }

    private var instrumentIcon: String {
        let inst = Instrument(rawValue: session.instrument)
        return inst?.iconName ?? "music.note"
    }

    private func formatDuration(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(value)
                .font(.headline.weight(.heavy).monospacedDigit())
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
    }
}
