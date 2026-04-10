import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var selectedTab: Int = 0
    @State private var showWelcomeTransition: Bool = false
    @State private var gamification = GamificationManager.shared
    @State private var showAchievementToast: Bool = false
    @State private var toastAchievement: Achievement?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack {
            mainContent
                .opacity(hasSeenWelcome && !showWelcomeTransition ? 1 : 0)

            if !hasSeenWelcome {
                WelcomeView {
                    hasSeenWelcome = true
                }
            }

            if showAchievementToast, let achievement = toastAchievement {
                VStack {
                    AchievementToastView(achievement: achievement)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                    Spacer()
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showAchievementToast)
                .allowsHitTesting(false)
            }
        }
        .onChange(of: gamification.newlyUnlockedAchievement?.id) { _, newId in
            guard let newId, let achievement = gamification.newlyUnlockedAchievement else { return }
            toastAchievement = achievement
            withAnimation { showAchievementToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation { showAchievementToast = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    gamification.newlyUnlockedAchievement = nil
                }
            }
        }
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView()
            }
            Tab("Tools", systemImage: "tuningfork", value: 1) {
                ToolsView()
            }
            Tab("Library", systemImage: "books.vertical.fill", value: 2) {
                LibraryView()
            }
            Tab("Progress", systemImage: "chart.bar.fill", value: 3) {
                PracticeHistoryView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
