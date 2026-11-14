import SwiftUI

enum PartyTheme {
    static let background = Color(red: 0.93, green: 0.95, blue: 0.97)
    static let ink = Color(red: 0.18, green: 0.20, blue: 0.24)
    static let mutedInk = Color(red: 0.40, green: 0.44, blue: 0.50)
    static let redPlayer = Color(red: 0.92, green: 0.22, blue: 0.28)
    static let bluePlayer = Color(red: 0.18, green: 0.45, blue: 0.95)
    static let greenPlayer = Color(red: 0.16, green: 0.72, blue: 0.42)
    static let orangePlayer = Color(red: 0.98, green: 0.55, blue: 0.16)
    static let tileBorder = Color.white
    static let cardShadow = Color.black.opacity(0.08)

    static func playerColor(_ index: Int) -> Color {
        switch index % 4 {
        case 0: return redPlayer
        case 1: return bluePlayer
        case 2: return greenPlayer
        default: return orangePlayer
        }
    }

    static func playerName(_ index: Int) -> String {
        "P\(index + 1)"
    }
}

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
