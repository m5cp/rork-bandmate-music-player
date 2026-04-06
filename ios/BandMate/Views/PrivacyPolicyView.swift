import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerBadge(icon: "lock.shield.fill", color: .blue, title: "Privacy Policy", date: "Last updated: April 2026")

                PolicyCard(icon: "doc.text.magnifyingglass", iconColor: .blue, title: "What We Collect") {
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBullet(icon: "camera.fill", text: "Sheet music images — sent to our secure servers for analysis. Images are processed temporarily and are not stored permanently.")
                        PolicyBullet(icon: "music.note.list", text: "Song data you save — stored locally on your device and synced to your account for cross-device access.")
                        PolicyBullet(icon: "mic.fill", text: "Practice recordings — audio recordings sent to AI for performance feedback. Recordings are processed temporarily and are not permanently stored.")
                        PolicyBullet(icon: "gearshape.fill", text: "App preferences — your instrument choice, skill level, and appearance settings stored locally on your device.")
                    }
                }

                PolicyCard(icon: "hand.raised.fill", iconColor: .green, title: "What We Don't Collect") {
                    VStack(alignment: .leading, spacing: 10) {
                        NoBullet(text: "Personal identification information (name, age, address)")
                        NoBullet(text: "Location data")
                        NoBullet(text: "Contact information or address book")
                        NoBullet(text: "Browsing history or usage analytics tied to your identity")
                        NoBullet(text: "Financial or payment information (handled by Apple)")
                    }
                }

                PolicyCard(icon: "server.rack", iconColor: .purple, title: "Data Processing") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When you scan sheet music or record a practice session, data is transmitted securely (via HTTPS) to our servers for AI analysis. This data is:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 8) {
                            PolicyBullet(icon: "clock.fill", text: "Processed in real-time and discarded after analysis")
                            PolicyBullet(icon: "lock.fill", text: "Encrypted in transit using industry-standard TLS")
                            PolicyBullet(icon: "trash.fill", text: "Not sold, shared, or distributed to third parties")
                        }
                        .padding(.top, 4)
                    }
                }

                PolicyCard(icon: "iphone", iconColor: .orange, title: "On-Device Storage") {
                    Text("Your saved songs, practice history, and preferences are stored locally on your device using Apple's secure storage frameworks. If you delete the app, this data will be removed from your device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "figure.and.child.holdinghands", iconColor: .teal, title: "Children's Privacy") {
                    Text("KITB is designed for use by students, including minors. We do not knowingly collect personal information from children. All data processing is limited to the functionality of the app (sheet music analysis, practice feedback) and does not involve profiling or targeted advertising.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                contactFooter
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contactFooter: some View {
        VStack(spacing: 8) {
            Text("Questions about your privacy?")
                .font(.subheadline.weight(.semibold))
            Text("contact@m5capital.org")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding(.top, 8)
    }
}

struct PolicyBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 18)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct NoBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .frame(width: 18)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

func headerBadge(icon: String, color: Color, title: String, date: String) -> some View {
    VStack(spacing: 12) {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 72, height: 72)
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.top, 20)

        VStack(spacing: 4) {
            Text(title)
                .font(.title3.bold())
            Text(date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
