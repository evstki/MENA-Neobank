import CoreText
import Foundation
import SwiftUI

enum AppFonts {
    private static let satoshiFamily = "Satoshi"
    private static let rubikFamily = "Rubik"
    private static let bundledFonts = [
        ("Satoshi-Light", "otf"),
        ("Satoshi-Regular", "otf"),
        ("Satoshi-Medium", "otf"),
        ("Satoshi-Bold", "otf"),
        ("Satoshi-Black", "otf"),
        ("Rubik-Variable", "ttf")
    ]

    static func registerBundledFonts() {
        for (name, fileExtension) in bundledFonts {
            guard let fontURL = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
                assertionFailure("Missing bundled font: \(name).\(fileExtension)")
                continue
            }

            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }

    static func font(
        _ style: Font.TextStyle = .body,
        weight: Font.Weight = .regular,
        locale: Locale
    ) -> Font {
        .custom(family(for: locale), size: baseSize(for: style), relativeTo: style)
            .weight(weight)
    }

    static func font(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body,
        locale: Locale
    ) -> Font {
        .custom(family(for: locale), size: size, relativeTo: style)
            .weight(weight)
    }

    private static func family(for locale: Locale) -> String {
        locale.language.languageCode?.identifier == "ar" ? rubikFamily : satoshiFamily
    }

    private static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .subheadline: 15
        case .callout: 16
        case .caption: 12
        case .caption2: 11
        case .footnote: 13
        default: 17
        }
    }
}

private struct AppFontModifier: ViewModifier {
    @Environment(\.locale) private var locale
    let style: Font.TextStyle
    let weight: Font.Weight
    let size: CGFloat?

    func body(content: Content) -> some View {
        if let size {
            content.font(AppFonts.font(size: size, weight: weight, relativeTo: style, locale: locale))
        } else {
            content.font(AppFonts.font(style, weight: weight, locale: locale))
        }
    }
}

extension View {
    func appFont(
        _ style: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(AppFontModifier(style: style, weight: weight, size: nil))
    }

    func appFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> some View {
        modifier(AppFontModifier(style: style, weight: weight, size: size))
    }
}
