import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String)] = [
        (
            "figure.run",
            "Track Your Runs",
            "Log runs manually, import from Apple Health, or load from a CSV file."
        ),
        (
            "trophy.fill",
            "Race History & PRs",
            "View personal records and track your progress across race events over time."
        ),
        (
            "icloud.fill",
            "Sync Everywhere",
            "Your data syncs automatically across all your devices with iCloud."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 64))
                            .foregroundStyle(Theme.teal)
                            .padding(.bottom, 8)

                        Text(page.title)
                            .font(.title.weight(.bold))
                            .foregroundStyle(Theme.teal)

                        Text(page.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    onComplete()
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundStyle(Theme.offWhite)
                    .frame(maxWidth: 280)
                    .frame(height: 50)
                    .background(Theme.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }
}
