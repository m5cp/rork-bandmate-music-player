import SwiftUI

struct AboutKITBView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                missionSection
                whyKITBSection
                whoItsForSection
                importantNoteSection
                versionSection
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About KITB")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 24)

            VStack(spacing: 6) {
                Text("KITB")
                    .font(.system(size: 32, weight: .black, design: .default).width(.expanded))
                    .tracking(6)

                Text("Kids In The Band")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var missionSection: some View {
        PolicyCard(icon: "heart.fill", iconColor: .red, title: "Our Mission") {
            Text("KITB was designed to help kids in the band hear what the music notes should sound like when reading sheet music. Whether you're in middle school or high school, beginner or advanced — KITB gives you a personal practice companion that's always ready when you are.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var whyKITBSection: some View {
        PolicyCard(icon: "sparkles", iconColor: .purple, title: "Why KITB?") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Learning music can feel intimidating. Playing the wrong note in front of your class or teacher can be embarrassing. We built KITB so students can:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    BulletPoint(icon: "ear.fill", color: .blue, text: "Hear what the music should sound like before playing it")
                    BulletPoint(icon: "music.note", color: .green, text: "Practice at their own pace without pressure")
                    BulletPoint(icon: "face.smiling.fill", color: .orange, text: "Build confidence without the fear of embarrassment in front of peers or teachers")
                    BulletPoint(icon: "mic.fill", color: .red, text: "Record themselves and get AI-powered feedback on their performance")
                    BulletPoint(icon: "arrow.up.right", color: .purple, text: "Improve steadily with personalized practice tips")
                }
            }
        }
    }

    private var whoItsForSection: some View {
        PolicyCard(icon: "person.2.fill", iconColor: .teal, title: "Who It's For") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(audiences, id: \.title) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(item.color)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.bold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var importantNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("Important")
                    .font(.headline.bold())
            }

            Text("KITB is a supplemental learning tool. It is not designed to teach you how to play a musical instrument, and it does not replace instruction from a qualified, certified music teacher. Always work with your band director or private instructor for proper technique, posture, and musical development.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var versionSection: some View {
        HStack {
            Text("Version")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var audiences: [(icon: String, color: Color, title: String, detail: String)] {
        [
            ("music.note.list", .blue, "Band Students", "Middle school and high school musicians learning to read and play sheet music"),
            ("star.fill", .yellow, "Beginners to Advanced", "Adaptive skill levels with AI feedback tailored to where you are"),
            ("figure.walk", .green, "Self-Paced Learners", "Practice on your own time, at your own speed, without judgment"),
            ("person.crop.circle.fill", .purple, "Parents & Educators", "A safe, focused tool to support music education at home or school")
        ]
    }
}

struct BulletPoint: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PolicyCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline.bold())
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }
}
