import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var selectedTab: Int = 0
    @State private var showWelcomeTransition: Bool = false
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
