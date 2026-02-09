import SwiftUI

struct ThemeTokens {
    struct Colors {
        let bgPrimary = Color(hex: "#FFFFFF")
        let bgSecondary = Color(hex: "#F5F5F5")
        let bgElevated = Color(hex: "#FFFFFF")
        let textPrimary = Color(hex: "#0B0B0B")
        let textSecondary = Color(hex: "#6B6B6B")
        let border = Color(hex: "#D8D8D8")
        let divider = Color(hex: "#ECECEC")
        let successAccent = Color(hex: "#16A34A")
    }

    struct Spacing {
        let unit: CGFloat = 8
        let cardPadding: CGFloat = 16
        let screenHorizontal: CGFloat = 20
    }

    struct Radius {
        let card: CGFloat = 12
        let control: CGFloat = 10
        let pill: CGFloat = 999
    }

    struct Typography {
        let h1 = Font.system(size: 32, weight: .bold, design: .default)
        let h2 = Font.system(size: 24, weight: .bold, design: .default)
        let h3 = Font.system(size: 20, weight: .semibold, design: .default)
        let body = Font.system(size: 17, weight: .regular, design: .default)
        let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
        let caption = Font.system(size: 13, weight: .regular, design: .default)
        let metric = Font.system(size: 24, weight: .semibold, design: .default)
    }

    let colors = Colors()
    let spacing = Spacing()
    let radius = Radius()
    let typography = Typography()
}

struct CelebrationStyle {
    let springDuration: Double = 0.26
    let standardDuration: Double = 0.18
    let lowBounce: CGFloat = 0.22
    let monochromeParticles = true
}

struct ShareCardStyle {
    let background = Color(hex: "#0B0B0B")
    let foreground = Color(hex: "#FFFFFF")
    let successAccent = Color(hex: "#16A34A")
}

struct AppTheme {
    let tokens = ThemeTokens()
    let celebration = CelebrationStyle()
    let shareCard = ShareCardStyle()

    static let athleticMinimal = AppTheme()
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.athleticMinimal
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
