import SwiftUI

struct ShareableScoreCard: View {
    let score: Int
    let instrument: Instrument
    let songTitle: String
    let streak: Int
    let focusAreas: [FocusArea]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KITB")
                            .font(.system(size: 14, weight: .black, design: .default).width(.expanded))
                            .tracking(4)
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Practice Report")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.orange)
                            Text("\(streak) day streak")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.1), in: .capsule)
                    }
                }

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.1), lineWidth: 8)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100)
                            .stroke(scoreGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(score)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("/ 100")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    Text(songTitle)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: instrument.iconName)
                            .font(.caption2.weight(.bold))
                        Text(instrument.rawValue)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.1), in: .capsule)
                }

                if !focusAreas.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(focusAreas.prefix(4)) { area in
                            VStack(spacing: 4) {
                                Text("\(area.score)")
                                    .font(.system(.caption, design: .rounded).weight(.heavy))
                                    .foregroundStyle(areaColor(area.score))
                                Text(shortName(area.name))
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.06), in: .rect(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.06, blue: 0.18), Color(red: 0.12, green: 0.08, blue: 0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
        .frame(width: 300)
    }

    private var scoreGradient: LinearGradient {
        switch score {
        case 80...100:
            LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 60..<80:
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 40..<60:
            LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func areaColor(_ score: Int) -> Color {
        switch score {
        case 80...100: .green
        case 60..<80: .blue
        case 40..<60: .orange
        default: .red
        }
    }

    private func shortName(_ name: String) -> String {
        if name.count <= 8 { return name }
        let words = name.split(separator: " ")
        if let first = words.first { return String(first) }
        return String(name.prefix(8))
    }
}

@MainActor
func renderShareableCard(score: Int, instrument: Instrument, songTitle: String, streak: Int, focusAreas: [FocusArea]) -> UIImage {
    let view = ShareableScoreCard(
        score: score,
        instrument: instrument,
        songTitle: songTitle,
        streak: streak,
        focusAreas: focusAreas
    )

    let controller = UIHostingController(rootView: view)
    let targetSize = CGSize(width: 300, height: 340)
    controller.view.bounds = CGRect(origin: .zero, size: targetSize)
    controller.view.backgroundColor = .clear

    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
}
