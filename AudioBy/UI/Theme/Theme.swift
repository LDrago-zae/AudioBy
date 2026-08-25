import SwiftUI

public enum Theme {
    // MARK: - App Backgrounds
    public static let appBackground = Color(red: 0.96, green: 0.97, blue: 0.98) // #F5F7FA
    public static let surfaceWhite = Color.white
    public static let surfaceSubtle = Color(red: 0.93, green: 0.94, blue: 0.96)
    public static let surfaceDark = Color(red: 0.10, green: 0.10, blue: 0.14)
    public static let cardDark = Color(red: 0.14, green: 0.14, blue: 0.19)

    // MARK: - Dark Matrix Palette
    public static let matrixBackground = Color(red: 0.05, green: 0.07, blue: 0.08)
    public static let matrixCardBorder = Color.white.opacity(0.12)
    public static let matrixDotInactive = Color.white.opacity(0.12)
    public static let matrixDotActive = Color(red: 0.45, green: 0.88, blue: 0.65) // Light glowing green

    // MARK: - Brand & Accents
    public static let brandGreen = Color(red: 0.06, green: 0.78, blue: 0.42) // #10C76B
    public static let brandGreenLight = Color(red: 0.35, green: 0.90, blue: 0.60)
    public static let brandGreenDark = Color(red: 0.03, green: 0.55, blue: 0.28)
    public static let brandCyan = Color(red: 0.15, green: 0.75, blue: 0.85)

    // Aliases
    public static let accent = brandGreen
    public static let accentSecondary = brandGreenLight

    // MARK: - Text Colors
    public static let textDark = Color(red: 0.08, green: 0.10, blue: 0.12)
    public static let textMuted = Color(red: 0.50, green: 0.54, blue: 0.58)
    public static let textLightMuted = Color(red: 0.70, green: 0.73, blue: 0.76)
    public static let textWhite = Color.white
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.70)
    public static let textTertiary = Color.white.opacity(0.45)

    // MARK: - Gradients
    public static let matrixGradient = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.16, blue: 0.12),
            Color(red: 0.04, green: 0.06, blue: 0.08)
        ],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )

    public static let activeGreenGradient = LinearGradient(
        colors: [brandGreenLight, brandGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let accentGradient = activeGreenGradient

    public static let dockBackground = Color(red: 0.07, green: 0.08, blue: 0.10)

    // MARK: - Acrylic Shelf Colors
    public static let foundationShelfTint = Color(red: 0.30, green: 0.85, blue: 0.60, opacity: 0.55)
    public static let buildShelfTint = Color(red: 0.40, green: 0.78, blue: 0.45, opacity: 0.55)
    public static let proveShelfTint = Color(red: 0.45, green: 0.65, blue: 0.95, opacity: 0.55)

    public static let glassSurface = Color.white.opacity(0.08)
    public static let glassBorder = Color.white.opacity(0.15)
}

// MARK: - Metallic Screw View
public struct MetallicScrewView: View {
    public var size: CGFloat = 10

    public init(size: CGFloat = 10) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.95),
                            Color(white: 0.70),
                            Color(white: 0.85),
                            Color(white: 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)

            // Inner cross / slot
            Rectangle()
                .fill(Color(white: 0.35))
                .frame(width: size * 0.6, height: size * 0.15)
                .cornerRadius(0.5)

            Rectangle()
                .fill(Color(white: 0.35))
                .frame(width: size * 0.15, height: size * 0.6)
                .cornerRadius(0.5)
        }
    }
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public init(hex: String) {
        self.init(hexString: hex)
    }
}
