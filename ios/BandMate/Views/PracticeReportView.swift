import SwiftUI

struct PracticeReportView: View {
    let feedback: PracticeFeedback
    let instrument: Instrument
    let skillLevel: SkillLevel
    let onPracticeAgain: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var animateScore: Bool = false
    @State private var showDetails: Bool = false
    @State private var showShareSheet: Bool = false

    private var isRegular: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ScrollView {
            if isRegular {
                HStack(alignment: .top, spacing: 32) {
                    VStack(spacing: 24) {
                        scoreHeader
                        skillLevelBadge
                        encouragementCard
                        actionButtons
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 24) {
                        focusAreasSection
                        strengthsSection
                        improvementsSection
                        tipsSection
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 24) {
                    scoreHeader
                    skillLevelBadge
                    focusAreasSection
                    strengthsSection
                    improvementsSection
                    tipsSection
                    encouragementCard
                    actionButtons
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(0.2)) {
                animateScore = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                showDetails = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [buildExportText()])
        }
    }

    private var scoreHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.quaternarySystemFill), lineWidth: 10)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: animateScore ? CGFloat(feedback.overallScore) / 100 : 0)
                    .stroke(scoreColor.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(animateScore ? feedback.overallScore : 0)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.8), value: animateScore)
                    Text("/ 100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(feedback.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }

    private var skillLevelBadge: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: skillLevel.iconName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
                Text("\(skillLevel.rawValue) Level Report")
                    .font(.subheadline.weight(.bold))
            }

            Text(skillLevel.reportDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.08), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }

    private var focusAreasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Focus Areas", systemImage: "target")
                .font(.headline.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(feedback.focusAreas) { area in
                    FocusAreaCard(area: area, color: instrument.category.color)
                        .opacity(showDetails ? 1 : 0)
                        .offset(y: showDetails ? 0 : 12)
                }
            }
        }
    }

    private var strengthsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Strengths", systemImage: "hand.thumbsup.fill")
                .font(.headline.bold())
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(feedback.strengths.enumerated()), id: \.offset) { _, strength in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding(.top, 1)
                        Text(strength)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.08), in: .rect(cornerRadius: 14))
        }
        .opacity(showDetails ? 1 : 0)
    }

    private var improvementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Areas to Improve", systemImage: "arrow.up.right")
                .font(.headline.bold())
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(feedback.improvements.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .padding(.top, 1)
                        Text(item)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08), in: .rect(cornerRadius: 14))
        }
        .opacity(showDetails ? 1 : 0)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Practice Tips", systemImage: "lightbulb.fill")
                .font(.headline.bold())
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(feedback.tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.yellow.gradient, in: Circle())
                            .padding(.top, 1)
                        Text(tip)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.08), in: .rect(cornerRadius: 14))
        }
        .opacity(showDetails ? 1 : 0)
    }

    private var encouragementCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(instrument.category.color)

            Text(feedback.encouragement)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(instrument.category.color.opacity(0.08), in: .rect(cornerRadius: 14))
        .opacity(showDetails ? 1 : 0)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                    Text("Export Report")
                        .font(.headline)
                }
                .foregroundStyle(instrument.category.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(instrument.category.color.opacity(0.12), in: .capsule)
            }

            Button {
                onPracticeAgain()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                    Text("Practice Again")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(instrument.category.color.gradient, in: .capsule)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var scoreColor: Color {
        switch feedback.overallScore {
        case 80...100: .green
        case 60..<80: .blue
        case 40..<60: .orange
        default: .red
        }
    }

    private func buildExportText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateStr = dateFormatter.string(from: feedback.date)

        var text = """
        🎵 BandMate Practice Report
        ━━━━━━━━━━━━━━━━━━━━━━━━━━
        Date: \(dateStr)
        Instrument: \(instrument.rawValue)
        Skill Level: \(skillLevel.rawValue)
        Overall Score: \(feedback.overallScore)/100

        📝 Summary
        \(feedback.summary)

        """

        if !feedback.focusAreas.isEmpty {
            text += "\n📊 Focus Areas\n"
            for area in feedback.focusAreas {
                text += "  • \(area.name): \(area.score)/100 — \(area.detail)\n"
            }
        }

        if !feedback.strengths.isEmpty {
            text += "\n✅ Strengths\n"
            for s in feedback.strengths {
                text += "  • \(s)\n"
            }
        }

        if !feedback.improvements.isEmpty {
            text += "\n🔼 Areas to Improve\n"
            for i in feedback.improvements {
                text += "  • \(i)\n"
            }
        }

        if !feedback.tips.isEmpty {
            text += "\n💡 Practice Tips\n"
            for (idx, tip) in feedback.tips.enumerated() {
                text += "  \(idx + 1). \(tip)\n"
            }
        }

        text += "\n✨ \(feedback.encouragement)\n"
        text += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━\nGenerated by BandMate"

        return text
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct FocusAreaCard: View {
    let area: FocusArea
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(area.name)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                Spacer()
                Text("\(area.score)")
                    .font(.subheadline.weight(.heavy).monospacedDigit())
                    .foregroundStyle(areaColor)
            }

            ProgressView(value: Double(area.score), total: 100)
                .tint(areaColor)

            Text(area.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
    }

    private var areaColor: Color {
        switch area.score {
        case 80...100: .green
        case 60..<80: .blue
        case 40..<60: .orange
        default: .red
        }
    }
}
