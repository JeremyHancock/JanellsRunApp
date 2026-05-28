import SwiftUI

struct ProfileView: View {
    let authService: AuthService
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var feedbackType: FeedbackType?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()

                List {
                    Section {
                        HStack(spacing: 14) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authService.userName ?? "Runner")
                                    .font(.headline)
                                if let email = authService.userEmail {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Distance Unit") {
                        @Bindable var prefs = preferences
                        Picker("Unit", selection: $prefs.distanceUnit) {
                            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Appearance") {
                        @Bindable var prefs = preferences
                        Picker("Appearance", selection: $prefs.appearance) {
                            ForEach(AppAppearance.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Feedback") {
                        Button {
                            feedbackType = .bug
                        } label: {
                            Label("Report a Bug", systemImage: "ladybug")
                        }
                        Button {
                            feedbackType = .feature
                        } label: {
                            Label("Request a Feature", systemImage: "lightbulb")
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showDeleteAccountConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Account")
                                Spacer()
                            }
                        }
                    } footer: {
                        Text("Permanently deletes your account and all running data.")
                    }

                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) { authService.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountConfirm) {
                Button("Delete Account", role: .destructive) {
                    try? authService.deleteAccount(modelContext: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your running data. This action cannot be undone.")
            }
            .sheet(item: $feedbackType) { type in
                FeedbackSheet(feedbackType: type, userName: authService.userName)
            }
        }
    }
}
