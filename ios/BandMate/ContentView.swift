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
            Tab("Samples", systemImage: "music.note.list", value: 1) {
                SampleLibraryView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: 2) {
                PracticeHistoryView()
            }
            Tab("Library", systemImage: "books.vertical.fill", value: 3) {
                LibraryView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 4) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
