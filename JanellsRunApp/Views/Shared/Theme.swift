import SwiftUI

enum Theme {
    static let teal = Color(red: 0, green: 0.502, blue: 0.502)
    static let offWhite = Color(red: 0.973, green: 0.973, blue: 0.973)
    static let tableGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondarySystemBackground
            : UIColor(red: 0.851, green: 0.851, blue: 0.851, alpha: 1)
    })
    static let darkBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : .black
    })
    static let improvement = Color.green
    static let regression = Color.red
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
