import CoreText
import Foundation
import SwiftUI

enum SDFonts {
    static let nunitoFamily = "Nunito"

    static func registerBundledFonts() {
        guard let fontURL = Bundle.main.url(forResource: "Nunito-Variable", withExtension: "ttf") else {
            return
        }

        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }

    static func nunito(
        _ style: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> Font {
        .custom(nunitoFamily, size: baseSize(for: style), relativeTo: style)
            .weight(weight)
    }

    static func nunito(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        .custom(nunitoFamily, size: size, relativeTo: style)
            .weight(weight)
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

extension Font {
    static func nunito(
        _ style: TextStyle = .body,
        weight: Weight = .regular
    ) -> Font {
        SDFonts.nunito(style, weight: weight)
    }

    static func nunito(
        size: CGFloat,
        weight: Weight = .regular,
        relativeTo style: TextStyle = .body
    ) -> Font {
        SDFonts.nunito(size: size, weight: weight, relativeTo: style)
    }
}
