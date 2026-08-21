//
//  SubscriptionDayApp.swift
//  SubscriptionDay
//
//  Created by Nikita on 17.08.2026.
//

import SwiftUI

@main
struct SubscriptionDayApp: App {
    @State private var model = AppModel()
    @AppStorage("subscription-day.accent-color") private var accentColor: AppAccentColor = .blue
    @AppStorage("subscription-day.main-currency") private var mainCurrency: AppCurrency = .usd
    @AppStorage("subscription-day.rounding") private var hidesCents = true
    @AppStorage("subscription-day.language") private var language: AppLanguage = .system

    init() {
        AppFonts.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .appFont()
                .environment(model)
                .environment(\.appAccentColor, accentColor)
                .environment(\.appCurrency, mainCurrency)
                .environment(\.appHidesCents, hidesCents)
                .environment(\.locale, language.locale)
                .environment(\.layoutDirection, language.layoutDirection)
                .preferredColorScheme(.dark)
                .task {
                    guard !AppCurrency.allCases.contains(mainCurrency) else { return }
                    mainCurrency = .usd
                }
        }
    }
}
