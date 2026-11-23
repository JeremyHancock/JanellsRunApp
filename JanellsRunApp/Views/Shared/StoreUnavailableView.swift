import SwiftUI

/// Shown at launch when the run data can't be opened, in place of a crash.
/// Nothing is deleted or changed; retrying just tries to open it again.
struct StoreUnavailableView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 48))
                .foregroundStyle(Theme.teal)
            Text("Couldn't open your runs")
                .font(.title3.weight(.semibold))
            Text("Your data hasn't been changed. Try again, and if this keeps happening, restart your iPhone or check for an app update.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .font(.headline)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Theme.teal)
                .foregroundStyle(Theme.offWhite)
                .clipShape(Capsule())
                .padding(.top, 8)
        }
        .padding(32)
    }
}
