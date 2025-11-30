//
//  LemonMathColors.swift
//  LemonMath
//
//  Design system colors for the Lemon Math app
//

import SwiftUI

// MARK: - Color Palette
struct LemonMathColors {
    // MARK: - Primary Colors
    static let lemonYellow = Color(hex: "FFE135")
    static let lemonLight = Color(hex: "FFF9C4")
    static let lemonDark = Color(hex: "F9A825")

    // MARK: - Accent Colors
    static let accent = Color(hex: "4CAF50")  // Fresh green
    static let accentLight = Color(hex: "81C784")
    static let accentDark = Color(hex: "388E3C")

    // MARK: - Background Colors
    static let background = Color("Background", bundle: nil)
    static let cardBackground = Color("CardBackground", bundle: nil)
    static let secondaryBackground = Color("SecondaryBackground", bundle: nil)

    // MARK: - Text Colors
    static let primaryText = Color("PrimaryText", bundle: nil)
    static let secondaryText = Color("SecondaryText", bundle: nil)
    static let tertiaryText = Color("TertiaryText", bundle: nil)

    // MARK: - Semantic Colors
    static let success = Color(hex: "4CAF50")
    static let warning = Color(hex: "FF9800")
    static let error = Color(hex: "F44336")
    static let info = Color(hex: "2196F3")

    // MARK: - Math Category Colors
    static let algebraColor = Color(hex: "7C4DFF")
    static let geometryColor = Color(hex: "00BCD4")
    static let calculusColor = Color(hex: "FF5722")
    static let trigColor = Color(hex: "E91E63")
    static let statsColor = Color(hex: "009688")
    static let linearAlgebraColor = Color(hex: "3F51B5")
    static let numberTheoryColor = Color(hex: "795548")
    static let arithmeticColor = Color(hex: "607D8B")

    // MARK: - Animation Colors
    static let glowColor = Color(hex: "FFE135").opacity(0.6)
    static let sparkleColor = Color(hex: "FFFFFF")
    static let magicInkColor = Color(hex: "1A237E")

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [lemonYellow, lemonDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accentLight, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [lemonLight.opacity(0.3), Color.white],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white, lemonLight.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let magicGradient = LinearGradient(
        colors: [
            Color(hex: "667eea"),
            Color(hex: "764ba2"),
            Color(hex: "f093fb")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    var uiColor: UIColor {
        UIColor(self)
    }
}

// MARK: - Dynamic Colors for Dark/Light Mode
extension Color {
    static let adaptiveBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "1C1C1E")
            : UIColor(hex: "F8F9FA")
    })

    static let adaptiveCardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "2C2C2E")
            : UIColor.white
    })

    static let adaptivePrimaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(hex: "1A1A1A")
    })

    static let adaptiveSecondaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "ABABAB")
            : UIColor(hex: "6B6B6B")
    })
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
