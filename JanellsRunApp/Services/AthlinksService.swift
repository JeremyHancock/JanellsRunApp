import Foundation

enum AthlinksService {
    static func fetchResults(athleteID: String) async throws -> [AthlinksResult] {
        var request = URLRequest(url: AthlinksImporter.resultsURL(athleteID: athleteID))
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://www.athlinks.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.athlinks.com/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AthlinksImporter.ImportError.badResponse
        }
        return try AthlinksImporter.parse(data: data)
    }
}
