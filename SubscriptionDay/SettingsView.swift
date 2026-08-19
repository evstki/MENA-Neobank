import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let showsDoneButton: Bool
    @AppStorage("subscription-day.rounding") private var rounding = true
    @AppStorage("subscription-day.abbreviate-large-numbers") private var abbreviateLargeNumbers = true
    @AppStorage("subscription-day.haptic-feedback") private var hapticFeedback = true
    @AppStorage("subscription-day.language") private var language = "Auto"
    @AppStorage("subscription-day.appearance") private var appearance: AppAppearance = .system
    @AppStorage("subscription-day.accent-color") private var accentColor: AppAccentColor = .blue
    @AppStorage("subscription-day.main-currency") private var mainCurrency: AppCurrency = .usd
    @AppStorage("subscription-day.reminders-enabled") private var remindersEnabled = false
    @AppStorage("subscription-day.first-reminder") private var reminder = "1 Day"
    @State private var reminderTime = Date.now
    @State private var alertMessage: String?

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Payment Reminder", isOn: $remindersEnabled)
                        .tint(settingsPalette.toggleTint)
                    if remindersEnabled {
                        Picker("Reminder", selection: $reminder) {
                            ForEach(["1 Day", "2 Days", "1 Week"], id: \.self, content: Text.init)
                        }
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        Button("Test Notification", systemImage: "bell.badge") {
                            alertMessage = "Test notification scheduled."
                        }
                    }
                }
                .animation(.default, value: remindersEnabled)
                .appThemedSurfaceRow()

                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    Picker("Accent Color", selection: $accentColor) {
                        ForEach(AppAccentColor.allCases) { option in
                            Label {
                                Text(option.title)
                            } icon: {
                                Image(uiImage: option.swatchImage)
                                    .renderingMode(.original)
                            }
                                .tag(option)
                        }
                    }
                }
                .appThemedSurfaceRow()

                Section("Interface") {
                    Picker("Main Currency", selection: $mainCurrency) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    Toggle("Rounding", isOn: $rounding)
                        .tint(settingsPalette.toggleTint)
                    Toggle("Abbreviate Large Numbers", isOn: $abbreviateLargeNumbers)
                        .tint(settingsPalette.toggleTint)
                    Picker("Language", selection: $language) {
                        ForEach(["Auto", "English", "Русский"], id: \.self, content: Text.init)
                    }
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .tint(settingsPalette.toggleTint)
                }
                .appThemedSurfaceRow()

                Section {
                    LabeledContent("Last Update") {
                        Text(Date.now, format: .dateTime.month(.abbreviated).day().hour().minute())
                    }
                    Button("Update Now", systemImage: "arrow.clockwise") {
                        alertMessage = "Currency rates are already up to date."
                    }
                } header: {
                    Text("Currency Rates")
                } footer: {
                    Text("Currency rates are approximate and may differ from rates offered by your bank.")
                }
                .appThemedSurfaceRow()

                Section("Support") {
                    Button("Rate & Review", systemImage: "star.bubble") {
                        alertMessage = "App Store review page is ready to connect."
                    }
                    Button("Contact", systemImage: "envelope") {
                        alertMessage = "Contact form is ready to connect."
                    }
                    ShareLink(
                        item: URL(string: "https://example.com/subscription-day")!,
                        subject: Text("Subscription Day"),
                        message: Text("Track subscriptions with Subscription Day.")
                    ) {
                        Label("Share with a Friend", systemImage: "square.and.arrow.up")
                    }
                }
                .appThemedSurfaceRow()
            }
            .id(accentColor)
            .appThemedScreenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .environment(\.appThemePalette, settingsPalette)
        .tint(settingsPalette.accent)
        .alert("Subscription Day", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var settingsPalette: AppThemePalette {
        AppThemePalette(accent: accentColor, colorScheme: colorScheme)
    }
}

#Preview {
    SettingsView()
        .environment(AppModel())
}
