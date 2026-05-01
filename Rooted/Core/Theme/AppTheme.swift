import SwiftUI

enum AppTheme {
    enum Colors {
        static let backgroundTop = Color(hex: "#F8EDEB")
        static let backgroundBottom = Color(hex: "#E3D5CA")
        static let card = Color.white.opacity(0.68)
        static let cardBorder = Color.white.opacity(0.50)
        static let accent = Color(hex: "#D97757")
        static let accentSoft = Color(hex: "#F1C7B5")
        static let highlight = Color(hex: "#6D597A")
        static let success = Color(hex: "#6B9D7C")
        static let primaryText = Color(hex: "#2B1D1A")
        static let secondaryText = Color(hex: "#6B5B57")
        static let chipBackground = Color.white.opacity(0.72)
    }

    static let screenGradient = LinearGradient(
        colors: [Colors.backgroundTop, Colors.backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
