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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .tint(SDTheme.accent)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
