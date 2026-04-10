import WidgetKit
import SwiftUI

nonisolated struct PracticeEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let longestStreak: Int
    let sessions: Int
    let minutes: Int
    let achievements: Int
    let totalAchievements: Int
    let practicedToday: Bool
}

nonisolated struct PracticeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PracticeEntry {
        PracticeEntry(date: .now, streak: 5, longestStreak: 12, sessions: 23, minutes: 180, achievements: 6, totalAchievements: 14, practicedToday: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (PracticeEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PracticeEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> PracticeEntry {
        let shared = UserDefaults(suiteName: "group.app.rork.sjsw8khf25sdj5xwh0897")
        let streak = shared?.integer(forKey: "widget_streak") ?? 0
        let longestStreak = shared?.integer(forKey: "widget_longestStreak") ?? 0
        let sessions = shared?.integer(forKey: "widget_sessions") ?? 0
        let minutes = shared?.integer(forKey: "widget_minutes") ?? 0
        let achievements = shared?.integer(forKey: "widget_achievements") ?? 0
        let totalAchievements = shared?.integer(forKey: "widget_totalAchievements") ?? 14
        let lastUpdate = shared?.object(forKey: "widget_lastUpdate") as? Date
        let practicedToday = lastUpdate.map { Calendar.current.isDateInToday($0) } ?? false

        return PracticeEntry(
            date: .now,
            streak: streak,
            longestStreak: longestStreak,
            sessions: sessions,
            minutes: minutes,
            achievements: achievements,
            totalAchievements: totalAchievements,
            practicedToday: practicedToday
        )
    }
}

struct SmallWidgetView: View {
    let entry: PracticeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
                Spacer()
                if entry.practicedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.streak)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(entry.streak > 0 ? .orange : .primary)
                Text(entry.streak == 1 ? "day streak" : "day streak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct MediumWidgetView: View {
    let entry: PracticeEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
                    Text("KITB")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.streak)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(entry.streak > 0 ? .orange : .primary)
                    Text("day streak")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                StatRow(icon: "music.mic", value: "\(entry.sessions)", label: "Sessions", color: .blue)
                StatRow(icon: "clock.fill", value: formatMinutes(entry.minutes), label: "Practiced", color: .green)
                StatRow(icon: "trophy.fill", value: "\(entry.achievements)/\(entry.totalAchievements)", label: "Badges", color: .yellow)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.orange.opacity(0.06), Color.yellow.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func formatMinutes(_ m: Int) -> String {
        if m >= 60 {
            return "\(m / 60)h \(m % 60)m"
        }
        return "\(m)m"
    }
}

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.weight(.heavy).monospacedDigit())
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

struct LargeWidgetView: View {
    let entry: PracticeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
                    Text("KITB Practice")
                        .font(.subheadline.weight(.bold))
                }
                Spacer()
                if entry.practicedToday {
                    Text("Practiced today")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.green.opacity(0.15), in: .capsule)
                } else {
                    Text("Not yet today")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.orange.opacity(0.15), in: .capsule)
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(entry.streak)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(entry.streak > 0 ? .orange : .primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("day")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("streak")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 10)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text("Best: \(entry.longestStreak) days")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 10)
            }

            Divider()

            HStack(spacing: 0) {
                LargeStatBlock(icon: "music.mic", value: "\(entry.sessions)", label: "Sessions", color: .blue)
                LargeStatBlock(icon: "clock.fill", value: formatMinutes(entry.minutes), label: "Total Time", color: .green)
                LargeStatBlock(icon: "trophy.fill", value: "\(entry.achievements)", label: "Badges", color: .yellow)
            }

            Spacer(minLength: 0)

            Text("Keep practicing to grow your streak!")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.orange.opacity(0.06), Color.yellow.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func formatMinutes(_ m: Int) -> String {
        if m >= 60 {
            return "\(m / 60)h \(m % 60)m"
        }
        return "\(m)m"
    }
}

struct LargeStatBlock: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
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
    }
}

struct KITBWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: PracticeProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct KITBWidget: Widget {
    let kind: String = "KITBWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PracticeProvider()) { entry in
            KITBWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Practice Streak")
        .description("Track your daily practice streak and progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
