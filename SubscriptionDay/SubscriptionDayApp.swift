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
    @AppStorage("subscription-day.appearance") private var appearance: AppAppearance = .system
    @AppStorage("subscription-day.accent-color") private var accentColor: AppAccentColor = .blue
    @AppStorage("subscription-day.main-currency") private var mainCurrency: AppCurrency = .usd

    init() {
        SDFonts.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.nunito())
                .environment(model)
                .environment(\.appAccentColor, accentColor)
                .environment(\.appCurrency, mainCurrency)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
