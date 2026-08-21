import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let showsDoneButton: Bool
    @AppStorage("subscription-day.language") private var language: AppLanguage = .system
    @AppStorage("subscription-day.accent-color") private var accentColor: AppAccentColor = .blue
    @AppStorage("subscription-day.main-currency") private var mainCurrency: AppCurrency = .usd
    @AppStorage("subscription-day.haptic-feedback") private var hapticFeedback = true
    @AppStorage("subscription-day.face-id-enabled") private var faceIDEnabled = true
    @AppStorage("subscription-day.bank-notifications-enabled") private var notificationsEnabled = true
    @State private var alertMessage: LocalizedStringKey?
    @ScaledMetric(relativeTo: .largeTitle) private var profileAvatarSize = 116.0

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ProfileHeader(avatarSize: profileAvatarSize)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section("Personal") {
                    profileButton("Personal details", systemImage: "person.text.rectangle")
                    profileButton("Contact details", systemImage: "at")
                    profileButton(
                        "Identity verification",
                        systemImage: "checkmark.shield.fill",
                        detail: "Verified",
                        detailColor: .green
                    )
                }
                .appThemedSurfaceRow()

                Section("Banking") {
                    profileButton("Accounts and balances", systemImage: "wallet.bifold")
                    profileButton("Statements and documents", systemImage: "doc.text")
                    profileButton("Transfer limits", systemImage: "gauge.with.dots.needle.67percent")
                }
                .appThemedSurfaceRow()

                Section("Security") {
                    Toggle(isOn: $faceIDEnabled) {
                        ProfileSettingLabel("Face ID", systemImage: "faceid")
                    }
                    .tint(settingsPalette.toggleTint)

                    profileButton("Security and privacy", systemImage: "lock.shield")
                    profileButton("Devices", systemImage: "iphone.gen3")
                }
                .appThemedSurfaceRow()

                Section("Preferences") {
                    Picker(selection: $mainCurrency) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    } label: {
                        ProfileSettingLabel("Main Currency", systemImage: "banknote")
                    }

                    Picker(selection: $language) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.titleKey).tag(option)
                        }
                    } label: {
                        ProfileSettingLabel("Language", systemImage: "character.bubble")
                    }

                    Picker(selection: $accentColor) {
                        ForEach(AppAccentColor.allCases) { option in
                            Label {
                                Text(LocalizedStringKey(option.title))
                            } icon: {
                                Image(uiImage: option.swatchImage)
                                    .renderingMode(.original)
                            }
                            .tag(option)
                        }
                    } label: {
                        ProfileSettingLabel("Accent Color", systemImage: "paintpalette")
                    }

                    Toggle(isOn: $hapticFeedback) {
                        ProfileSettingLabel("Haptic Feedback", systemImage: "waveform")
                    }
                    .tint(settingsPalette.toggleTint)
                }
                .appThemedSurfaceRow()

                Section("Notifications") {
                    Toggle(isOn: $notificationsEnabled) {
                        ProfileSettingLabel("Push notifications", systemImage: "bell.badge")
                    }
                    .tint(settingsPalette.toggleTint)
                }
                .appThemedSurfaceRow()

                Section("Support") {
                    profileButton("Help center", systemImage: "questionmark.circle")
                    profileButton("Contact support", systemImage: "message")
                    profileButton("Legal and privacy", systemImage: "doc.badge.gearshape")
                }
                .appThemedSurfaceRow()

                Section {
                    Button(role: .destructive) {
                        alertMessage = "Sign out is ready to connect."
                    } label: {
                        ProfileSettingLabel(
                            "Sign out",
                            systemImage: "rectangle.portrait.and.arrow.right",
                            iconColor: .red,
                            titleColor: .red
                        )
                    }
                }
                .appThemedSurfaceRow()
            }
            .id(accentColor)
            .contentMargins(.top, 0, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background {
                ZStack(alignment: .top) {
                    settingsPalette.background
                    ProfileTopBackdrop()
                }
                .ignoresSafeArea()
            }
            .navigationTitle(AppLocalization.string("Profile", locale: language.locale))
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
        .alert("Profile", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var settingsPalette: AppThemePalette {
        AppThemePalette(accent: accentColor)
    }

    private func profileButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        detail: LocalizedStringKey? = nil,
        detailColor: Color = .secondary
    ) -> some View {
        Button {
            alertMessage = "This profile option is ready to connect."
        } label: {
            ProfileNavigationLabel(
                title,
                systemImage: systemImage,
                detail: detail,
                detailColor: detailColor
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileTopBackdrop: View {
    var body: some View {
        Image(decorative: "profile_kirill")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 340)
            .scaleEffect(1.25)
            .blur(radius: 56, opaque: true)
            .overlay(.black.opacity(0.45))
            .opacity(0.42)
            .mask {
                LinearGradient(
                    colors: [.black, .black.opacity(0.8), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

private struct ProfileHeader: View {
    let avatarSize: CGFloat

    var body: some View {
        VStack(spacing: 12) {
            ProfileAvatar(size: avatarSize)
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)

            Text(verbatim: "Kirill E")
                .appFont(size: 32, weight: .bold, relativeTo: .largeTitle)

            Text("Personal account")
                .appFont(.body, weight: .medium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileSettingLabel: View {
    @Environment(\.appThemePalette) private var palette
    let title: LocalizedStringKey
    let systemImage: String
    let iconColor: Color?
    let titleColor: Color

    init(
        _ title: LocalizedStringKey,
        systemImage: String,
        iconColor: Color? = nil,
        titleColor: Color = .primary
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.titleColor = titleColor
    }

    var body: some View {
        Label {
            Text(title)
                .appFont(.body, weight: .medium)
                .foregroundStyle(titleColor)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(resolvedIconColor)
                .frame(width: 24)
                .accessibilityHidden(true)
        }
    }

    private var resolvedIconColor: Color {
        iconColor ?? palette.accent
    }
}

private struct ProfileNavigationLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    let detail: LocalizedStringKey?
    let detailColor: Color

    init(
        _ title: LocalizedStringKey,
        systemImage: String,
        detail: LocalizedStringKey? = nil,
        detailColor: Color = .secondary
    ) {
        self.title = title
        self.systemImage = systemImage
        self.detail = detail
        self.detailColor = detailColor
    }

    var body: some View {
        HStack(spacing: 10) {
            ProfileSettingLabel(title, systemImage: systemImage)

            Spacer(minLength: 8)

            if let detail {
                Text(detail)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(detailColor)
            }

            Image(systemName: "chevron.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
    }
}

#Preview {
    SettingsView()
}
