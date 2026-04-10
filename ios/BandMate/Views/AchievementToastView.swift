import SwiftUI

struct AchievementToastView: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked!")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(.yellow)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.1, blue: 0.0), Color(red: 0.2, green: 0.12, blue: 0.02)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: .rect(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(colors: [.yellow.opacity(0.5), .orange.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .padding(.horizontal, 20)
        .sensoryFeedback(.success, trigger: achievement.id)
    }
}
