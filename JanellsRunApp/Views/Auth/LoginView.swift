import SwiftUI
import AuthenticationServices

struct LoginView: View {
    let authService: AuthService

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("richmond-silhouette")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 280)
                .padding(.bottom, 24)

            Text("Janell's Run App")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.teal)
                .padding(.bottom, 8)

            Text("Track your races, PRs, and progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 48)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                authService.handleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .frame(maxWidth: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
