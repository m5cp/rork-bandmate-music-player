import SwiftUI

struct AccessibilityView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerBadge(icon: "accessibility", color: .blue, title: "Accessibility", date: "Our commitment to inclusion")

                PolicyCard(icon: "eye.fill", iconColor: .blue, title: "VoiceOver Support") {
                    Text("KITB is built with full VoiceOver support. All interactive elements, buttons, and content have descriptive labels so screen reader users can navigate and use every feature of the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "textformat.size", iconColor: .purple, title: "Dynamic Type") {
                    Text("All text in KITB respects your system text size preferences. Whether you prefer larger or smaller text, the app adapts automatically through Apple's Dynamic Type system to maintain readability.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "circle.lefthalf.filled", iconColor: .orange, title: "Dark Mode & High Contrast") {
                    Text("KITB fully supports Light Mode, Dark Mode, and system-level high contrast settings. The app uses semantic colors that automatically adapt to your chosen appearance, ensuring comfortable viewing in any lighting condition.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "hand.tap.fill", iconColor: .green, title: "Touch Targets") {
                    Text("All buttons and interactive elements meet or exceed Apple's minimum 44×44 point touch target guidelines, making the app easy to use for everyone, including users with motor impairments.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "waveform.path", iconColor: .red, title: "Reduce Motion") {
                    Text("KITB respects the \"Reduce Motion\" accessibility setting. When enabled, animations are replaced with simple fades or removed entirely, ensuring a comfortable experience for users sensitive to motion.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PolicyCard(icon: "ipad.and.iphone", iconColor: .teal, title: "iPad & iPhone") {
                    Text("KITB is designed to work beautifully on both iPhone and iPad. On iPad, the app takes advantage of the larger screen with adaptive layouts, side-by-side views, and optimized spacing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                feedbackSection
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Accessibility Feedback")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }

            Text("If you encounter any accessibility issues or have suggestions for how we can make KITB more inclusive, please reach out. We're committed to making music practice accessible to all students.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Text("contact@m5capital.org")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.blue, .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: 16)
        )
    }
}
