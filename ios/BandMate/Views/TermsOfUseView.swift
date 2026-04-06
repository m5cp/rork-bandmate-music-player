import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerBadge(icon: "doc.text.fill", color: .indigo, title: "Terms of Use", date: "Last updated: April 2026")

                PolicyCard(icon: "book.fill", iconColor: .blue, title: "1. Educational Use") {
                    Text("KITB is designed exclusively for educational purposes to help students learn and practice reading sheet music. It is intended as a supplemental tool to support music education — not as a replacement for qualified music instruction.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "waveform.badge.exclamationmark", iconColor: .orange, title: "2. Accuracy & Limitations") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Music recognition and AI feedback accuracy may vary depending on:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 8) {
                            PolicyBullet(icon: "photo", text: "Image quality and lighting conditions when scanning sheet music")
                            PolicyBullet(icon: "music.note", text: "Complexity of the musical notation and arrangements")
                            PolicyBullet(icon: "mic", text: "Audio recording quality and background noise during practice sessions")
                            PolicyBullet(icon: "cpu", text: "AI model limitations in interpreting musical performance")
                        }

                        Text("Always verify AI-generated results against your original sheet music and consult your music teacher for authoritative guidance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }

                PolicyCard(icon: "person.fill.checkmark", iconColor: .green, title: "3. User Responsibilities") {
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBullet(icon: "doc.on.doc", text: "You are responsible for ensuring you have the right to scan and use any sheet music. Do not scan copyrighted material without proper permission or license.")
                        PolicyBullet(icon: "checkmark.shield", text: "Use this app only for lawful, educational purposes.")
                        PolicyBullet(icon: "person.2", text: "If you are a minor, use this app with the knowledge and consent of a parent or guardian.")
                    }
                }

                PolicyCard(icon: "creditcard.fill", iconColor: .purple, title: "4. Subscriptions & Payments") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subscriptions are billed through your Apple ID and managed via App Store. All payments are handled securely by Apple — we never see or store your payment information.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("You may cancel your subscription at any time through your Apple ID settings. Cancellation takes effect at the end of your current billing period.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                PolicyCard(icon: "xmark.shield.fill", iconColor: .red, title: "5. Disclaimer of Warranties") {
                    Text("This app is provided \"as is\" and \"as available\" without warranties of any kind, whether express or implied. We do not guarantee that the app will be error-free, uninterrupted, or that results will be accurate. Use of the app is at your own risk.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "exclamationmark.octagon.fill", iconColor: .orange, title: "6. Limitation of Liability") {
                    Text("To the fullest extent permitted by law, KITB and its developers shall not be liable for any direct, indirect, incidental, consequential, or punitive damages arising from the use of this app, including but not limited to any reliance on AI-generated feedback, music recognition results, or practice assessments.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "arrow.triangle.2.circlepath", iconColor: .teal, title: "7. Changes to Terms") {
                    Text("We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the revised terms. We encourage you to review these terms periodically.")
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
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contactFooter: some View {
        VStack(spacing: 8) {
            Text("Questions about these terms?")
                .font(.subheadline.weight(.semibold))
            Text("contact@m5capital.org")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding(.top, 8)
    }
}
