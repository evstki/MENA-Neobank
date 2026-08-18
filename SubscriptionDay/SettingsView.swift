import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let showsDoneButton: Bool
    @AppStorage("subscription-day.rounding") private var rounding = false
    @AppStorage("subscription-day.abbreviate-large-numbers") private var abbreviateLargeNumbers = true
    @AppStorage("subscription-day.true-dark-colors") private var trueDarkColors = false
    @AppStorage("subscription-day.haptic-feedback") private var hapticFeedback = true
    @AppStorage("subscription-day.language") private var language = "Auto"
    @AppStorage("subscription-day.appearance") private var appearance: AppAppearance = .system
    @AppStorage("subscription-day.first-reminder") private var firstReminder = "1 Day"
    @AppStorage("subscription-day.second-reminder") private var secondReminder = "Never"
    @State private var reminderTime = Date.now
    @State private var alertMessage: String?

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image("app_logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(.rect(cornerRadius: 10))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Subscription Day")
                                .font(.headline)
                            Text("Free account")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Free")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SDTheme.accent)
                    }

                    Text("Unlock all features with a lifetime license.")
                        .foregroundStyle(.secondary)
                }

                Section {
                    SettingsActionRow(title: "iCloud & Data", systemImage: "icloud", value: "Off") {
                        alertMessage = "iCloud synchronization is turned off."
                    }
                }

                Section {
                    SettingsActionRow(title: "Main Currency", systemImage: "dollarsign.circle", value: "USD") {
                        alertMessage = "USD is the current main currency."
                    }
                    Toggle("Rounding", isOn: $rounding)
                    Toggle("Abbreviate Large Numbers", isOn: $abbreviateLargeNumbers)
                } header: {
                    Text("Currency")
                } footer: {
                    Text("Rounding hides decimals. Abbreviated values use a compact format such as 74.5K.")
                }

                Section("Library") {
                    LabeledContent("Categories", value: "\(SubscriptionCategory.allCases.count)")
                    LabeledContent("Lists", value: "2")
                    LabeledContent("Payment Methods", value: "3")
                }

                Section {
                    Picker("First Reminder", selection: $firstReminder) {
                        ForEach(["1 Day", "2 Days", "1 Week"], id: \.self, content: Text.init)
                    }
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    Picker("Second Reminder", selection: $secondReminder) {
                        ForEach(["Never", "1 Day", "1 Week"], id: \.self, content: Text.init)
                    }
                    Button("Test Notification", systemImage: "bell.badge") {
                        alertMessage = "Test notification scheduled."
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Notifications might not appear while a Focus mode is enabled.")
                }

                Section {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("The selected theme is applied immediately across the entire app.")
                }

                Section("Interface") {
                    Picker("Language", selection: $language) {
                        ForEach(["Auto", "English", "Русский"], id: \.self, content: Text.init)
                    }
                    Toggle("True Dark Colors", isOn: $trueDarkColors)
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                }

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

                Section("Support") {
                    Button("Rate & Review", systemImage: "star.bubble") {
                        alertMessage = "App Store review page is ready to connect."
                    }
                    Button("Ideas & Roadmap", systemImage: "checklist") {
                        alertMessage = "Roadmap is ready to connect."
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

                Section {
                    VStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("Made with care for native iOS")
                            .font(.footnote)
                        Text("Version 1.1.3")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
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
        .alert("Subscription Day", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

private struct SettingsActionRow: View {
    let title: String
    let systemImage: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                Text(value)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    SettingsView()
        .environment(AppModel())
}
