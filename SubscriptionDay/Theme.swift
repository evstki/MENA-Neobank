import SwiftUI

enum AppCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cny = "CNY"
    case chf = "CHF"
    case cad = "CAD"
    case aud = "AUD"
    case inr = "INR"
    case krw = "KRW"
    case rub = "RUB"
    case brl = "BRL"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .usd, .cad, .aud: "$"
        case .eur: "€"
        case .gbp: "£"
        case .jpy, .cny: "¥"
        case .chf: "CHF "
        case .inr: "₹"
        case .krw: "₩"
        case .rub: "₽"
        case .brl: "R$"
        }
    }

    func formatted(_ amount: Double) -> String {
        let fractionDigits = amount.rounded() == amount ? 0 : 2
        let style = FloatingPointFormatStyle<Double>()
            .grouping(.automatic)
            .precision(.fractionLength(fractionDigits))
        let number = abs(amount).formatted(style)
        let sign = amount < 0 ? "-" : ""
        return "\(sign)\(symbol)\(number)"
    }
}

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

enum AppAccentColor: String, CaseIterable, Identifiable {
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case orange = "Orange"
    case green = "Green"
    case teal = "Teal"
    case white = "White"

    var id: Self { self }
    var title: String { rawValue }

    var color: Color {
        baseRGB.color
    }

    var uiColor: UIColor { UIColor(color) }

    var swatchImage: UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16))
        return renderer.image { context in
            context.cgContext.setFillColor(uiColor.cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 14, height: 14))
            if self == .white {
                context.cgContext.setStrokeColor(UIColor.systemGray3.cgColor)
                context.cgContext.setLineWidth(1)
                context.cgContext.strokeEllipse(in: CGRect(x: 1.5, y: 1.5, width: 13, height: 13))
            }
        }
        .withRenderingMode(.alwaysOriginal)
    }

    fileprivate var baseRGB: ThemeRGB {
        switch self {
        case .blue: ThemeRGB(0.38, 0.50, 1.00)
        case .purple: ThemeRGB(0.62, 0.40, 0.95)
        case .pink: ThemeRGB(0.95, 0.32, 0.64)
        case .orange: ThemeRGB(0.95, 0.52, 0.20)
        case .green: ThemeRGB(0.27, 0.70, 0.42)
        case .teal: ThemeRGB(0.18, 0.65, 0.70)
        case .white: ThemeRGB(1.00, 1.00, 1.00)
        }
    }

    fileprivate var lightModeAccentRGB: ThemeRGB {
        switch self {
        case .blue: ThemeRGB(0.329, 0.433, 0.866)
        case .purple: ThemeRGB(0.556, 0.359, 0.852)
        case .pink: ThemeRGB(0.789, 0.266, 0.532)
        case .orange: ThemeRGB(0.700, 0.383, 0.147)
        case .green: ThemeRGB(0.203, 0.525, 0.315)
        case .teal: ThemeRGB(0.142, 0.511, 0.550)
        case .white: ThemeRGB(0.22, 0.23, 0.27)
        }
    }
}

private struct ThemeRGB {
    let red: Double
    let green: Double
    let blue: Double

    init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    var color: Color { Color(red: red, green: green, blue: blue) }

    func mixed(with other: ThemeRGB, amount: Double) -> ThemeRGB {
        ThemeRGB(
            red + (other.red - red) * amount,
            green + (other.green - green) * amount,
            blue + (other.blue - blue) * amount
        )
    }
}

struct AppThemePalette {
    let accent: Color
    let toggleTint: Color
    let background: Color
    let surface: Color
    let elevatedSurface: Color
    let selectedSurface: Color

    init(accent: AppAccentColor, colorScheme: ColorScheme) {
        let accentRGB = accent.baseRGB

        switch colorScheme {
        case .dark:
            let backgroundRGB = ThemeRGB(8.0 / 255.0, 11.0 / 255.0, 22.0 / 255.0)
                .mixed(with: accentRGB, amount: 0.07)
                .mixed(with: ThemeRGB(0, 0, 0), amount: 0.4375)
            let surfaceRGB = ThemeRGB(0.11, 0.115, 0.15)
                .mixed(with: accentRGB, amount: 0.11)
            let elevatedRGB = ThemeRGB(0.16, 0.165, 0.20)
                .mixed(with: accentRGB, amount: 0.14)

            self.accent = accentRGB.color
            toggleTint = accent == .white
                ? ThemeRGB(0.42, 0.44, 0.50).color
                : accentRGB.color
            background = backgroundRGB.color
            surface = surfaceRGB.color
            elevatedSurface = elevatedRGB.color
            selectedSurface = surfaceRGB.mixed(with: accentRGB, amount: 0.24).color

        default:
            let backgroundRGB = ThemeRGB(0.949, 0.949, 0.969)
                .mixed(with: accentRGB, amount: 0.045)
            let surfaceRGB = ThemeRGB(1, 1, 1)
                .mixed(with: accentRGB, amount: 0.055)
            let elevatedRGB = ThemeRGB(0.975, 0.975, 0.985)
                .mixed(with: accentRGB, amount: 0.085)

            self.accent = accent.lightModeAccentRGB.color
            toggleTint = accent.lightModeAccentRGB.color
            background = backgroundRGB.color
            surface = surfaceRGB.color
            elevatedSurface = elevatedRGB.color
            selectedSurface = surfaceRGB.mixed(with: accentRGB, amount: 0.16).color
        }
    }
}

private struct AppAccentColorKey: EnvironmentKey {
    static let defaultValue = AppAccentColor.blue
}

private struct AppCurrencyKey: EnvironmentKey {
    static let defaultValue = AppCurrency.usd
}

extension EnvironmentValues {
    var appAccentColor: AppAccentColor {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }

    var appCurrency: AppCurrency {
        get { self[AppCurrencyKey.self] }
        set { self[AppCurrencyKey.self] = newValue }
    }
}

private struct AppThemePaletteKey: EnvironmentKey {
    static let defaultValue = AppThemePalette(accent: .blue, colorScheme: .light)
}

extension EnvironmentValues {
    var appThemePalette: AppThemePalette {
        get { self[AppThemePaletteKey.self] }
        set { self[AppThemePaletteKey.self] = newValue }
    }
}

enum SDTheme {
    static let background = Color(uiColor: .systemBackground)
    static let sheet = Color(uiColor: .systemBackground)
    static let panel = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedPanel = Color(uiColor: .tertiarySystemGroupedBackground)
    static let field = Color(uiColor: .secondarySystemFill)
    static let separator = Color(uiColor: .separator)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(uiColor: .tertiaryLabel)
    static let activeGreen = Color(red: 0.53, green: 0.82, blue: 0.23)
    static let mutedGreen = activeGreen.opacity(0.16)
    static let chartRed = Color(red: 0.95, green: 0.28, blue: 0.23)
    static let chartBlue = Color(red: 0.10, green: 0.56, blue: 0.81)
}

extension Font {
    static func sdRounded(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .nunito(size: size, weight: weight)
    }
}

extension View {
    func appThemedScreenBackground() -> some View {
        modifier(AppThemedScreenBackgroundModifier())
    }

    func appThemedSurfaceRow() -> some View {
        modifier(AppThemedSurfaceRowModifier())
    }

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

private struct AppThemedScreenBackgroundModifier: ViewModifier {
    @Environment(\.appThemePalette) private var palette

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
    }
}

private struct AppThemedSurfaceRowModifier: ViewModifier {
    @Environment(\.appThemePalette) private var palette

    func body(content: Content) -> some View {
        content.listRowBackground(palette.surface)
    }
}

struct AmbientGlow: View {
    @Environment(\.appThemePalette) private var palette
    var warmOpacity: Double = 0.16
    var coolOpacity: Double = 0.13

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [palette.accent.opacity(warmOpacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: proxy.size.width * 0.70
                )
                .frame(width: proxy.size.width * 1.20, height: proxy.size.width * 1.20)
                .position(x: proxy.size.width * 0.66, y: proxy.size.height * 0.33)

                RadialGradient(
                    colors: [palette.accent.opacity(coolOpacity * 0.72), .clear],
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
