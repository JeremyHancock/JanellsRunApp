import AuthenticationServices
import SwiftData
import SwiftUI

@Observable
final class AuthService {
    var isSignedIn = false

    private let userIDKey = "appleUserID"
    private let userNameKey = "appleUserName"
    private let userEmailKey = "appleUserEmail"

    var userName: String? { KeychainHelper.read(key: userNameKey) }
    var userEmail: String? { KeychainHelper.read(key: userEmailKey) }

    init() {
        if let userID = storedUserID {
            checkCredentialState(userID: userID)
        }
    }

    private var storedUserID: String? {
        KeychainHelper.read(key: userIDKey)
    }

    func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                KeychainHelper.save(key: userIDKey, value: credential.user)
                if let fullName = credential.fullName {
                    let name = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    if !name.isEmpty {
                        KeychainHelper.save(key: userNameKey, value: name)
                    }
                }
                if let email = credential.email {
                    KeychainHelper.save(key: userEmailKey, value: email)
                }
                isSignedIn = true
            }
        case .failure:
            isSignedIn = false
        }
    }

    func signOut() {
        KeychainHelper.delete(key: userIDKey)
        isSignedIn = false
    }

    func deleteAccount(modelContext: ModelContext) throws {
        try modelContext.delete(model: Run.self)
        try modelContext.delete(model: RaceEvent.self)
        try modelContext.save()

        KeychainHelper.delete(key: userIDKey)
        KeychainHelper.delete(key: userNameKey)
        KeychainHelper.delete(key: userEmailKey)

        UserDefaults.standard.removeObject(forKey: "distanceUnit")
        UserDefaults.standard.removeObject(forKey: "appearance")

        isSignedIn = false
    }

    private func checkCredentialState(userID: String) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
            DispatchQueue.main.async {
                self.isSignedIn = (state == .authorized)
                if state == .revoked || state == .notFound {
                    KeychainHelper.delete(key: self.userIDKey)
                }
            }
        }
    }
}

enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
