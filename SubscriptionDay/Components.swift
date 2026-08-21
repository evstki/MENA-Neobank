import SwiftUI
import UIKit

struct BundledArtwork: View {
    let name: String

    private static let images: [String: UIImage] = [
        "bitcoin", "card", "coin", "safe", "shield", "two cards", "wallet"
    ].reduce(into: [:]) { images, name in
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else {
            return
        }
        images[name] = image
    }

    var body: some View {
        if let image = Self.images[name] {
            Image(uiImage: image)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
        }
    }
}

struct AppPageHeading: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    @State private var restingTitleMinY: CGFloat?
    @State private var scrollOffset: CGFloat = 0
    @State private var titleHeight: CGFloat = 44

    var body: some View {
        Text(description)
            .appFont(.body, weight: .medium)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topLeading) {
                Text(title)
                    .appFont(.largeTitle, weight: .bold)
                    .foregroundStyle(.primary)
                    .fixedSize()
                    .offset(x: -4, y: -44)
                    .opacity(titleOpacity)
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        geometry.size.height
                    } action: { newHeight in
                        titleHeight = newHeight
                    }
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        geometry.frame(in: .global).minY
                    } action: { newMinY in
                        updateTitlePosition(newMinY)
                    }
                    .accessibilityHidden(true)
            }
    }

    private var titleOpacity: CGFloat {
        1 - min(scrollOffset / max(titleHeight, 1), 1)
    }

    private func updateTitlePosition(_ minY: CGFloat) {
        guard let restingTitleMinY else {
            restingTitleMinY = minY
            return
        }
        scrollOffset = max(restingTitleMinY - minY, 0)
    }
}

struct AppNavigationTitleFontConfigurator: UIViewControllerRepresentable {
    @Environment(\.locale) private var locale

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        let locale = locale

        DispatchQueue.main.async {
            guard let navigationBar = viewController.navigationController?.navigationBar else { return }
            let usesArabicFont = locale.language.languageCode?.identifier == "ar"
            let fontName = usesArabicFont ? "Rubik" : "Satoshi-Bold"

            let largeBaseFont = UIFont(name: fontName, size: 34)
                ?? UIFont.systemFont(ofSize: 34, weight: .bold)
            let inlineBaseFont = UIFont(name: fontName, size: 17)
                ?? UIFont.systemFont(ofSize: 17, weight: .bold)

            var largeTitleAttributes = navigationBar.largeTitleTextAttributes ?? [:]
            largeTitleAttributes[.font] = UIFontMetrics(forTextStyle: .largeTitle)
                .scaledFont(for: largeBaseFont)
            largeTitleAttributes[.foregroundColor] = UIColor.clear
            largeTitleAttributes.removeValue(forKey: .baselineOffset)
            navigationBar.largeTitleTextAttributes = largeTitleAttributes

            var titleAttributes = navigationBar.titleTextAttributes ?? [:]
            titleAttributes[.font] = UIFontMetrics(forTextStyle: .headline)
                .scaledFont(for: inlineBaseFont)
            navigationBar.titleTextAttributes = titleAttributes

            func configuredAppearance(
                from source: UINavigationBarAppearance
            ) -> UINavigationBarAppearance {
                let appearance = source.copy() as? UINavigationBarAppearance ?? source
                appearance.largeTitleTextAttributes = largeTitleAttributes
                appearance.titleTextAttributes = titleAttributes
                return appearance
            }

            navigationBar.standardAppearance = configuredAppearance(
                from: navigationBar.standardAppearance
            )
            if let scrollEdgeAppearance = navigationBar.scrollEdgeAppearance {
                navigationBar.scrollEdgeAppearance = configuredAppearance(from: scrollEdgeAppearance)
            }
            if let compactAppearance = navigationBar.compactAppearance {
                navigationBar.compactAppearance = configuredAppearance(from: compactAppearance)
            }
            if let compactScrollEdgeAppearance = navigationBar.compactScrollEdgeAppearance {
                navigationBar.compactScrollEdgeAppearance = configuredAppearance(
                    from: compactScrollEdgeAppearance
                )
            }
        }
    }
}

private let serviceAvatarPalette: [Color] = [
    Color(red: 0.31, green: 0.47, blue: 0.94),
    Color(red: 0.47, green: 0.33, blue: 0.88),
    Color(red: 0.78, green: 0.30, blue: 0.62),
    Color(red: 0.91, green: 0.36, blue: 0.32),
    Color(red: 0.89, green: 0.52, blue: 0.22),
    Color(red: 0.24, green: 0.64, blue: 0.42),
    Color(red: 0.18, green: 0.61, blue: 0.70),
    Color(red: 0.26, green: 0.52, blue: 0.78)
]

struct ProfileAvatar: View {
    var size: CGFloat = 36

    var body: some View {
        Image(decorative: "profile_kirill")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(.circle)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
    }
}

private enum AppTopNavigationSheet: String, Identifiable {
    case profile
    case notifications

    var id: String { rawValue }
}

private struct AppTopNavigationBarModifier: ViewModifier {
    @Environment(\.appThemePalette) private var palette
    @State private var presentedSheet: AppTopNavigationSheet?

    let isVisible: Bool
    let searchTitle: LocalizedStringKey
    let searchAction: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                if isVisible {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            presentedSheet = .profile
                        } label: {
                            ProfileAvatar(size: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Profile")
                        .contentShape(Circle())
                    }
                    .sharedBackgroundVisibility(.hidden)

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Notifications", systemImage: "bell") {
                            presentedSheet = .notifications
                        }
                        .badge(2)
                        .accessibilityValue(Text("2 unread notifications"))
                        .tint(palette.accent)
                    }

                    ToolbarSpacer(.fixed, placement: .topBarTrailing)

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            searchAction()
                        } label: {
                            Label(searchTitle, systemImage: "magnifyingglass")
                        }
                        .tint(palette.accent)
                    }
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .profile:
                    SettingsView()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                case .notifications:
                    AppNotificationsSheet()
                        .presentationDetents([.height(280)])
                        .presentationDragIndicator(.visible)
                }
            }
    }
}

extension View {
    func appTopNavigationBar(
        isVisible: Bool = true,
        searchTitle: LocalizedStringKey = "Search",
        searchAction: @escaping () -> Void
    ) -> some View {
        modifier(AppTopNavigationBarModifier(
            isVisible: isVisible,
            searchTitle: searchTitle,
            searchAction: searchAction
        ))
    }
}

private struct AppNotificationsSheet: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 68, height: 68)
                    .background(palette.selectedSurface, in: .circle)
                    .accessibilityHidden(true)

                Text("2 unread notifications")
                    .appFont(.headline, weight: .bold)

                Text("Notification history will appear here soon.")
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ServiceLogo: View {
    let service: ServiceBrand
    var size: CGFloat = 46
    var showsShadow = true

    var body: some View {
        Group {
            if showsShadow {
                logoContent
                    .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
            } else {
                logoContent
            }
        }
        .accessibilityHidden(true)
    }

    private var logoContent: some View {
        Group {
            if let assetName = availableAssetName {
                if assetName.hasPrefix("circle_") || service.fillsLogoContainer {
                    if service.logoMarkScale < 1 {
                        compactCircleAssetBadge(assetName: assetName)
                    } else {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                    }
                } else if service.usesWhiteLogoBackground {
                    whiteLogoBadge(assetName: assetName)
                } else if service.usesMonochromeLogo {
                    monochromeLogoBadge(assetName: assetName)
                } else {
                    logoBadge(assetName: assetName)
                }
            } else if service.usesCustomIcon || service.isPopular {
                ZStack {
                    Circle().fill(service.logoFillColor)
                    if service.usesCustomIcon && service.fallbackSymbol == "initial" {
                        Text(service.initial)
                            .appFont(size: size * 0.44, weight: .bold)
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: service.fallbackSymbol)
                            .font(.system(size: size * 0.43, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            } else {
                ZStack {
                    Circle().fill(service.avatarColor)
                    Text(service.initial)
                        .appFont(size: size * 0.44, weight: .bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
        }
    }

    private var availableAssetName: String? {
        guard let assetName = service.assetName,
              UIImage(named: assetName) != nil else {
            return nil
        }
        return assetName
    }

    private func logoBadge(assetName: String) -> some View {
        ZStack {
            Circle().fill(service.logoFillColor)
            Circle()
                .fill(.white)
                .padding(size * 0.10)
            Image(assetName)
                .resizable()
                .scaledToFit()
                .padding(size * 0.16)
        }
    }

    private func monochromeLogoBadge(assetName: String) -> some View {
        ZStack {
            Circle().fill(service.logoFillColor)
            Image(assetName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.white)
                .padding(size * 0.18)
        }
    }

    private func whiteLogoBadge(assetName: String) -> some View {
        ZStack {
            Circle().fill(.white)
            Image(assetName)
                .resizable()
                .scaledToFit()
                .padding(size * 0.14)
        }
    }

    private func compactCircleAssetBadge(assetName: String) -> some View {
        ZStack {
            Circle().fill(service.logoFillColor)
            Image(assetName)
                .resizable()
                .scaledToFit()
                .scaleEffect(service.logoMarkScale)
        }
    }
}

extension ServiceBrand {
    var logoMarkScale: CGFloat {
        switch id {
        case "t2": 0.82
        case "vk-музыка": 0.88
        default: 1
        }
    }

    var logoFillColor: Color {
        switch id {
        case "netflix":
            Color(red: 0.90, green: 0.04, blue: 0.08)
        case "chatgpt":
            Color.black
        case "apple-icloud":
            Color(red: 0.32, green: 0.66, blue: 0.96)
        case "apple-one":
            Color(red: 0.11, green: 0.11, blue: 0.12)
        default:
            Color(hex: fallbackColor)
        }
    }

    var initial: String {
        name.first.map { String($0).uppercased() } ?? "?"
    }

    var avatarColor: Color {
        let index = id.utf8.reduce(0) { partialResult, byte in
            (partialResult * 31 + Int(byte)) % serviceAvatarPalette.count
        }
        return serviceAvatarPalette[index]
    }

    var brandTint: Color {
        if usesCustomIcon {
            return Color(hex: fallbackColor)
        }

        guard isPopular else { return avatarColor }

        switch id {
        case "netflix":
            return Color(red: 0.90, green: 0.10, blue: 0.15)
        case "cursor":
            return Color(red: 0.34, green: 0.42, blue: 0.55)
        case "apple-tv":
            return Color(red: 0.39, green: 0.42, blue: 0.52)
        default:
            break
        }

        switch fallbackColor.uppercased() {
        case "F4F4F4", "FFFFFF":
            switch category {
            case .entertainment: return Color(red: 0.56, green: 0.32, blue: 0.92)
            case .productivity: return Color(red: 0.28, green: 0.49, blue: 0.95)
            case .cloud: return Color(red: 0.20, green: 0.59, blue: 0.94)
            case .health: return Color(red: 0.24, green: 0.72, blue: 0.45)
            case .education: return Color(red: 0.94, green: 0.57, blue: 0.20)
            case .shopping: return Color(red: 0.93, green: 0.34, blue: 0.57)
            case .social: return Color(red: 0.63, green: 0.36, blue: 0.91)
            case .mobile: return Color(red: 0.12, green: 0.64, blue: 0.76)
            case .other: return Color(red: 0.22, green: 0.67, blue: 0.68)
            }
        default:
            return Color(hex: fallbackColor)
        }
    }
}

struct SDSectionTitle: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .appFont(size: 13, weight: .medium, relativeTo: .caption)
            .tracking(1.7)
            .foregroundStyle(SDTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SDPanel<Content: View>: View {
    var radius: CGFloat = 10
    @ViewBuilder let content: Content

    init(radius: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .background(SDTheme.panel, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct SDDisclosureRow: View {
    let symbol: String
    let title: String
    var value: String? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: 26)
                Text(title)
                    .appFont(size: 15.5)
                Spacer(minLength: 8)
                if let value {
                    Text(value)
                        .appFont(size: 15.5)
                        .foregroundStyle(SDTheme.secondaryText)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SDTheme.secondaryText)
            }
            .foregroundStyle(SDTheme.primaryText)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SheetHandle: View {
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.42))
            .frame(width: 36, height: 5)
            .accessibilityHidden(true)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch cleaned.count {
        case 3:
            red = ((value >> 8) & 0xF) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        }
        self.init(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
