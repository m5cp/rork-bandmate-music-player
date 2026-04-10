import SwiftUI
import MessageUI

struct ContactSupportView: View {
    @State private var showMailUnavailable: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                emailCard
                faqSection
                responseTimeCard
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Email Not Available", isPresented: $showMailUnavailable) {
            Button("Copy Email") {
                UIPasteboard.general.string = "contact@m5capital.org"
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mail is not configured on this device. You can copy the email address and send from your preferred email app.")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .teal.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "headphones.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 20)

            VStack(spacing: 4) {
                Text("We're Here to Help")
                    .font(.title3.bold())
                Text("Get support for any issues or questions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emailCard: some View {
        VStack(spacing: 16) {
            Button {
                sendEmail()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.gradient)
                            .frame(width: 44, height: 44)
                        Image(systemName: "envelope.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email Support")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("contact@m5capital.org")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                UIPasteboard.general.string = "contact@m5capital.org"
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 44, height: 44)
                        Image(systemName: "doc.on.doc.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Copy Email Address")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Tap to copy to clipboard")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "doc.on.clipboard")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: false)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.purple)
                Text("Common Questions")
                    .font(.headline.bold())
            }

            VStack(spacing: 12) {
                FAQItem(
                    question: "Why doesn't the music sound right?",
                    answer: "Music recognition accuracy depends on image quality. Try scanning in good lighting with a flat, clear image. Complex or handwritten notation may not be fully recognized."
                )
                FAQItem(
                    question: "How does AI feedback work?",
                    answer: "When you record yourself playing, the audio is analyzed by AI to provide general feedback on pitch, rhythm, and overall performance. This is approximate and not a replacement for teacher evaluation."
                )
                FAQItem(
                    question: "Is KITB free to use?",
                    answer: "Yes! KITB is free to use. Scan sheet music, play it back on your instrument, practice with AI feedback, and use the metronome and tuner — all at no cost."
                )
                FAQItem(
                    question: "Is my data safe?",
                    answer: "Yes. Images and audio are processed temporarily for analysis and are not stored permanently. See our Privacy Policy for full details."
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private var responseTimeCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Response Time")
                    .font(.subheadline.weight(.bold))
                Text("We typically respond within 24–48 hours during business days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private func sendEmail() {
        guard let url = URL(string: "mailto:contact@m5capital.org?subject=KITB%20Support%20Request") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailUnavailable = true
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 12))
    }
}
