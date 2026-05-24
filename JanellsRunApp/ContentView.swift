import SwiftUI

struct ContentView: View {
    let authService: AuthService
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            AddRunView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(0)

            RunListView()
                .tabItem {
                    Label("All Runs", systemImage: "list.bullet")
                }
                .tag(1)

            PersonalRecordsView()
                .tabItem {
                    Label("PRs", systemImage: "trophy.fill")
                }
                .tag(2)

            RaceHistoryView()
                .tabItem {
                    Label("Races", systemImage: "flag.fill")
                }
                .tag(3)

            ProfileView(authService: authService)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .tint(Theme.teal)
    }
}
