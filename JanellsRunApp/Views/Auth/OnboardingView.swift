import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pageCount = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "figure.run",
                    title: "Track Your Runs",
                    description: "Log runs manually, import from Apple Health, or load from a CSV file."
                ).tag(0)

                OnboardingPage(
                    icon: "trophy.fill",
                    title: "Race History & PRs",
                    description: "View personal records and track your progress across race events over time."
                ).tag(1)

                OnboardingPage(
                    icon: "icloud.fill",
                    title: "Sync Everywhere",
                    description: "Your data syncs automatically across all your devices with iCloud."
                ).tag(2)

                GesturesDemoPage().tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: {
                if currentPage < pageCount - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    onComplete()
                }
            }) {
                Text(currentPage < pageCount - 1 ? "Next" : "Get Started")
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

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(Theme.teal)
                .padding(.bottom, 8)

            Text(title)
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.teal)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            Spacer()
            Spacer()
        }
    }
}

private struct GesturesDemoPage: View {
    @State private var animationPhase = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Quick Tips")
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.teal)
                .padding(.bottom, 4)

            VStack(spacing: 24) {
                gestureDemo(
                    label: "Long press to edit",
                    icon: "hand.tap.fill",
                    showingHighlight: animationPhase == 1
                )

                gestureDemo(
                    label: "Swipe left to delete",
                    icon: "hand.point.left.fill",
                    showingSwipe: animationPhase == 2
                )
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear { startAnimation() }
    }

    private func gestureDemo(
        label: String,
        icon: String,
        showingHighlight: Bool = false,
        showingSwipe: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Theme.teal)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }

            ZStack(alignment: .trailing) {
                mockRow
                    .offset(x: showingSwipe ? -80 : 0)

                if showingSwipe {
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(.red)
                            .frame(width: 80)
                            .overlay {
                                Image(systemName: "trash.fill")
                                    .foregroundStyle(.white)
                                    .font(.body)
                            }
                    }
                    .transition(.move(edge: .trailing))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                if showingHighlight {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.teal.opacity(0.15))
                }
            }
        }
    }

    private var mockRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Training")
                    .font(.subheadline.weight(.medium))
                Text("3.1 mi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("27:00")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.tableGray.opacity(0.5))
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animationPhase = animationPhase == 0 ? 1 : (animationPhase == 1 ? 2 : 0)
            }
        }
    }
}
