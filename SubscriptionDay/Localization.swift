import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "Auto"
    case english = "English"
    case arabic = "العربية"

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    var locale: Locale {
        switch self {
        case .system:
            Locale.autoupdatingCurrent.language.languageCode?.identifier == "ar"
                ? Locale(identifier: "ar")
                : Locale(identifier: "en")
        case .english: Locale(identifier: "en")
        case .arabic: Locale(identifier: "ar")
        }
    }

    var layoutDirection: LayoutDirection {
        locale.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight
    }
}

enum AppLocalization {
    static func string(
        _ key: String,
        locale: Locale,
        arguments: CVarArg...
    ) -> String {
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        let resourceLanguage = switch languageCode {
        case "ar": "ar"
        case "ru": "ru"
        default: "en"
        }
        let bundle = Bundle.main.path(forResource: resourceLanguage, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: locale, arguments: arguments)
    }

    static func activeSubscriptions(_ count: Int, locale: Locale) -> String {
        string(
            pluralKey(base: "analytics.active", count: count, locale: locale),
            locale: locale,
            arguments: count
        )
    }

    static func nextPayment(days: Int, locale: Locale) -> String {
        string(
            pluralKey(base: "home.nextPayment.days", count: days, locale: locale),
            locale: locale,
            arguments: days
        )
    }

    static func subscriptionCount(_ count: Int, locale: Locale) -> String {
        string(
            pluralKey(base: "calendar.subscriptions", count: count, locale: locale),
            locale: locale,
            arguments: count
        )
    }

    static func growActiveSubscriptions(_ count: Int, locale: Locale) -> String {
        string(
            pluralKey(base: "grow.active", count: count, locale: locale),
            locale: locale,
            arguments: count
        )
    }

    private static func pluralKey(base: String, count: Int, locale: Locale) -> String {
        let languageCode = locale.language.languageCode?.identifier
        if languageCode == "ar" {
            let absoluteCount = abs(count)
            let modulo100 = absoluteCount % 100
            if absoluteCount == 0 { return "\(base).zero" }
            if absoluteCount == 1 { return "\(base).one" }
            if absoluteCount == 2 { return "\(base).two" }
            if (3...10).contains(modulo100) { return "\(base).few" }
            if (11...99).contains(modulo100) { return "\(base).many" }
            return "\(base).other"
        }

        guard languageCode == "ru" else {
            return count == 1 ? "\(base).one" : "\(base).other"
        }

        let modulo10 = abs(count) % 10
        let modulo100 = abs(count) % 100
        if modulo10 == 1, modulo100 != 11 { return "\(base).one" }
        if (2...4).contains(modulo10), !(12...14).contains(modulo100) {
            return "\(base).few"
        }
        return "\(base).many"
    }
}

extension SubscriptionCategory {
    var localizedTitleKey: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    func localizedTitle(locale: Locale) -> String {
        AppLocalization.string(rawValue, locale: locale)
    }
}

extension PaymentSchedule {
    var localizedTitleKey: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    func localizedTitle(locale: Locale) -> String {
        AppLocalization.string(rawValue, locale: locale)
    }
}
