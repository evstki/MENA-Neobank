import SwiftUI

enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case usd = "USD"
    case aed = "AED"
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

    static let allCases: [AppCurrency] = [.usd, .aed]

    var id: Self { self }

    var symbol: String {
        switch self {
        case .usd, .cad, .aud: "$"
        case .aed: "AED"
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

    func formatted(_ amount: Double, hidesCents: Bool) -> String {
        let fractionDigits = hidesCents || amount.rounded() == amount ? 0 : 2
        let style = FloatingPointFormatStyle<Double>()
            .grouping(.automatic)
            .precision(.fractionLength(fractionDigits))
        let number = abs(amount).formatted(style)
        let sign = amount < 0 ? "-" : ""
        if self == .aed {
            return "\(sign)\(number)\u{00A0}\(symbol)"
        }
        return "\(sign)\(symbol)\(number)"
    }

    func converted(_ amount: Double, to targetCurrency: AppCurrency) -> Double {
        guard self != targetCurrency else { return amount }
        let amountInUSD = amount / unitsPerUSDDollar
        return amountInUSD * targetCurrency.unitsPerUSDDollar
    }

    private var unitsPerUSDDollar: Double {
        switch self {
        case .usd: 1.00
        case .aed: 3.6725
        case .eur: 0.92
        case .gbp: 0.79
        case .jpy: 150.0
        case .cny: 7.25
        case .chf: 0.88
        case .cad: 1.36
        case .aud: 1.53
        case .inr: 83.5
        case .krw: 1_330.0
        case .rub: 90.0
        case .brl: 5.00
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
        case .white: ThemeRGB(0.96, 0.96, 0.98)
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
    let accentForeground: Color
    let toggleTint: Color
    let background: Color
    let surface: Color
    let elevatedSurface: Color
    let selectedSurface: Color

    init(accent: AppAccentColor) {
        let accentRGB = accent.baseRGB
        let backgroundRGB = ThemeRGB(8.0 / 255.0, 11.0 / 255.0, 22.0 / 255.0)
            .mixed(with: accentRGB, amount: 0.07)
            .mixed(with: ThemeRGB(0, 0, 0), amount: 0.4375)
        let surfaceRGB = ThemeRGB(0.11, 0.115, 0.15)
            .mixed(with: accentRGB, amount: 0.11)
            .mixed(with: ThemeRGB(0, 0, 0), amount: 0.10)
        let elevatedRGB = ThemeRGB(0.16, 0.165, 0.20)
            .mixed(with: accentRGB, amount: 0.14)

        self.accent = accentRGB.color
        accentForeground = accent == .white ? .black : .white
        toggleTint = accent == .white ? ThemeRGB(0.58, 0.58, 0.62).color : accentRGB.color
        background = backgroundRGB.color
        surface = surfaceRGB.color
        elevatedSurface = elevatedRGB.color
        selectedSurface = surfaceRGB.mixed(with: accentRGB, amount: 0.24).color
    }
}

private struct AppAccentColorKey: EnvironmentKey {
    static let defaultValue = AppAccentColor.blue
}

private struct AppCurrencyKey: EnvironmentKey {
    static let defaultValue = AppCurrency.usd
}

private struct AppHidesCentsKey: EnvironmentKey {
    static let defaultValue = true
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

    var appHidesCents: Bool {
        get { self[AppHidesCentsKey.self] }
        set { self[AppHidesCentsKey.self] = newValue }
    }
}

private struct AppThemePaletteKey: EnvironmentKey {
    static let defaultValue = AppThemePalette(accent: .blue)
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

enum AppSurfaceMetrics {
    static let cornerRadius: CGFloat = 16.8
    static let blockSpacing: CGFloat = 8
}

private struct AppFloatingSurfaceModifier: ViewModifier {
    @Environment(\.appThemePalette) private var palette
    let radius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .compositingGroup()
                .clipShape(.rect(cornerRadius: radius))
                .glassEffect(
                    .regular.tint(palette.surface).interactive(),
                    in: .rect(cornerRadius: radius)
                )
        } else {
            content.background(palette.surface, in: .rect(cornerRadius: radius))
        }
    }
}

extension View {
    func appFloatingSurface(radius: CGFloat) -> some View {
        modifier(AppFloatingSurfaceModifier(radius: radius))
    }

    func appThemedScreenBackground() -> some View {
        modifier(AppThemedScreenBackgroundModifier())
    }

    func appThemedSurfaceRow(opacity: Double = 1) -> some View {
        modifier(AppThemedSurfaceRowModifier(opacity: opacity))
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
    let opacity: Double

    func body(content: Content) -> some View {
        content.listRowBackground(palette.surface.opacity(opacity))
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
