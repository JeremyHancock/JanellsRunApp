import UIKit

enum FeedbackType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case bug = "Bug Report"
    case feature = "Feature Request"

    var apiValue: String {
        switch self {
        case .bug: return "bug"
        case .feature: return "feature"
        }
    }
}

enum FeedbackService {
    // Update this after deploying the Cloudflare Worker
    static let workerURL = URL(string: "https://janells-run-feedback.jeremyhancock32.workers.dev")!

    static func submit(type: FeedbackType, title: String, description: String, userName: String?) async throws {
        var deviceInfo = "\(deviceModel()), iOS \(UIDevice.current.systemVersion), v\(appVersion())"
        if let name = userName, !name.isEmpty {
            deviceInfo = "\(name) — \(deviceInfo)"
        }

        let payload: [String: String] = [
            "type": type.apiValue,
            "title": title,
            "description": description,
            "deviceInfo": deviceInfo,
        ]

        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
            if let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = body["error"] as? String {
                throw FeedbackError.serverError(error)
            }
            throw FeedbackError.submitFailed
        }
    }

    private static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        return machine
    }

    private static func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    enum FeedbackError: LocalizedError {
        case submitFailed
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .submitFailed: return "Could not submit feedback. Please try again."
            case .serverError(let msg): return msg
            }
        }
    }
}
