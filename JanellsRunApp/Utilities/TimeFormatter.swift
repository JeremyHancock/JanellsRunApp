import Foundation

enum TimeFormatter {
    static func formatted(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func totalSeconds(hours: Int, minutes: Int, seconds: Int) -> Int {
        hours * 3600 + minutes * 60 + seconds
    }
}
