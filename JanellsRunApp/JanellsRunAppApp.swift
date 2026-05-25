import SwiftUI
import SwiftData

@main
struct JanellsRunAppApp: App {
    @State private var authService = AuthService()
    @State private var preferences = UserPreferences()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Run.self,
            RaceEvent.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private var isSignedIn: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return authService.isSignedIn
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isSignedIn {
                    ContentView(authService: authService)
                        .onAppear {
                            #if DEBUG
                            SampleData.loadIfNeeded(into: sharedModelContainer.mainContext)
                            #endif
                        }
                } else {
                    LoginView(authService: authService)
                }
            }
            .preferredColorScheme(preferences.appearance.colorScheme)
        }
        .environment(preferences)
        .modelContainer(sharedModelContainer)
    }
}
