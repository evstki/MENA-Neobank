import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "Auto"
    case light = "Light"
    case dark = "Dark"

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum SDTheme {
    static let background = Color(uiColor: .systemBackground)
    static let calendarBackground = Color(uiColor: .systemGroupedBackground)
    static let sheet = Color(uiColor: .systemBackground)
    static let panel = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedPanel = Color(uiColor: .tertiarySystemGroupedBackground)
    static let field = Color(uiColor: .secondarySystemFill)
    static let separator = Color(uiColor: .separator)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(uiColor: .tertiaryLabel)
    static let accent = Color(red: 0.38, green: 0.50, blue: 1.00)
    static let activeGreen = Color(red: 0.53, green: 0.82, blue: 0.23)
    static let mutedGreen = activeGreen.opacity(0.16)
    static let chartRed = Color(red: 0.95, green: 0.28, blue: 0.23)
    static let chartBlue = Color(red: 0.10, green: 0.56, blue: 0.81)
}

extension Font {
    static func sdRounded(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension View {
    func sdPanel(radius: CGFloat = 10) -> some View {
        background(SDTheme.panel, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func sdCardBorder(radius: CGFloat = 10) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.5)
        }
    }
}

struct AmbientGlow: View {
    var warmOpacity: Double = 0.16
    var coolOpacity: Double = 0.13

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [Color(red: 0.31, green: 0.22, blue: 0.68).opacity(warmOpacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: proxy.size.width * 0.70
                )
                .frame(width: proxy.size.width * 1.20, height: proxy.size.width * 1.20)
                .position(x: proxy.size.width * 0.66, y: proxy.size.height * 0.33)

                RadialGradient(
                    colors: [Color(red: 0.08, green: 0.33, blue: 0.47).opacity(coolOpacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: proxy.size.width * 0.72
                )
                .frame(width: proxy.size.width * 1.25, height: proxy.size.width * 1.25)
                .position(x: proxy.size.width * 0.30, y: proxy.size.height * 0.57)
            }
        }
        .allowsHitTesting(false)
    }
}
