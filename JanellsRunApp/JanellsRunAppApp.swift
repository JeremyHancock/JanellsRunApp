import OSLog
import SwiftUI
import SwiftData

@main
struct JanellsRunAppApp: App {
    @State private var authService = AuthService()
    @State private var preferences = UserPreferences()
    /// Nil when the store couldn't be opened; the app then shows a retry screen.
    @State private var modelContainer = Self.makeModelContainer()

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "JanellsRunApp", category: "store")

    private static func makeModelContainer() -> ModelContainer? {
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
            logger.error("Could not create ModelContainer: \(error)")
            return nil
        }
    }

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
                if let modelContainer {
                    signedInOrLogin
                        .modelContainer(modelContainer)
                } else {
                    StoreUnavailableView {
                        modelContainer = Self.makeModelContainer()
                    }
                }
            }
            .preferredColorScheme(preferences.appearance.colorScheme)
        }
        .environment(preferences)
    }

    @ViewBuilder
    private var signedInOrLogin: some View {
        if isSignedIn {
            ContentView(authService: authService)
                .onAppear {
                    #if DEBUG
                    if let modelContainer {
                        SampleData.loadIfNeeded(into: modelContainer.mainContext)
                    }
                    #endif
                }
        } else {
            LoginView(authService: authService)
        }
    }
}
