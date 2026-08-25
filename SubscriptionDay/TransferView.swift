import SwiftUI

struct TransferView: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .largeTitle) private var amountFontSize = 68.0
    @State private var amount = ""
    @State private var selectedCurrency: AppCurrency = .aed
    @Binding private var selectedDestination: TransferDestination?
    @State private var showingRecipientPicker = false
    @State private var showingConfirmation = false
    @State private var showingSuccess = false
    @FocusState private var amountFieldIsFocused: Bool

    init(selectedDestination: Binding<TransferDestination?>) {
        _selectedDestination = selectedDestination
    }

    var body: some View {
        ZStack {
            AppScreenBackdrop(accentColor: selectedDestination?.color)

            ScrollView {
                VStack(spacing: 0) {
                    amountSection
                        .padding(.top, 26)

                    recipientSection
                        .padding(.top, 32)
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRecipientPicker) {
            TransferRecipientPicker(selection: $selectedDestination)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
        }
        .safeAreaInset(edge: .bottom) {
            nextButton
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
        .confirmationDialog(
            confirmationTitle,
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Send transfer") {
                showingSuccess = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The transfer will be sent immediately from All accounts.")
        }
        .alert("Transfer sent", isPresented: $showingSuccess) {
            Button("Done", role: .cancel) {
                amount = ""
            }
        } message: {
            Text(successMessage)
        }
        .sensoryFeedback(.selection, trigger: selectedDestination)
        .sensoryFeedback(.success, trigger: showingSuccess)
        .onChange(of: showingRecipientPicker, initial: true) { _, isPresented in
            amountFieldIsFocused = !isPresented && selectedDestination != nil
        }
    }

    private var amountSection: some View {
        VStack(spacing: 12) {
            ZStack {
                TextField("", text: amountBinding)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .font(amountFont)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .multilineTextAlignment(.center)
                    .focused($amountFieldIsFocused)
                    .frame(maxWidth: .infinity)
                    .frame(height: 92)
                    .accessibilityLabel("Transfer amount")
                    .accessibilityValue("\(visibleAmount) \(selectedCurrency.rawValue)")

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: visibleAmount)
                        .font(amountFont)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: numericAmount))
                        .allowsHitTesting(false)

                    currencyPicker
                }
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .animation(.snappy(duration: 0.2), value: numericAmount)
            }
            .frame(maxWidth: .infinity)
            .environment(\.layoutDirection, .leftToRight)

            Label {
                Text(verbatim: "From All accounts · \(formattedAvailableBalance) \(selectedCurrency.rawValue) available")
            } icon: {
                Image(systemName: "arrow.up.arrow.down")
            }
                .appFont(.subheadline, weight: .semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var amountFont: Font {
        AppFonts.font(
            size: amountFontSize,
            weight: .heavy,
            relativeTo: .largeTitle,
            locale: locale
        )
    }

    private var currencyPicker: some View {
        Menu {
            Picker("Currency", selection: $selectedCurrency) {
                Text(verbatim: "AED").tag(AppCurrency.aed)
                Text(verbatim: "USD").tag(AppCurrency.usd)
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: selectedCurrency.rawValue)
                    .appFont(.title2, weight: .bold)

                Image(systemName: "chevron.down")
                    .font(.caption.bold())
            }
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Transfer currency")
        .accessibilityValue(selectedCurrency.rawValue)
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recipient")
                    .appFont(.subheadline, weight: .bold)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                if selectedDestination != nil {
                    Button("Change") {
                        amountFieldIsFocused = false
                        showingRecipientPicker = true
                    }
                    .appFont(.subheadline, weight: .bold)
                }
            }

            if let selectedDestination {
                TransferDestinationRow(destination: selectedDestination)
                    .transition(.blurReplace)
            } else {
                Button("Choose recipient", systemImage: "person.crop.circle.badge.plus") {
                    showingRecipientPicker = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth(duration: 0.24), value: selectedDestination)
    }

    @ViewBuilder
    private var nextButton: some View {
        let button = Button {
            showingConfirmation = true
        } label: {
            Text("Next")
                .appFont(.body, weight: .bold)
                .foregroundStyle(palette.accentForeground)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.extraLarge)
        .disabled(!canContinue)

        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(palette.accent)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(palette.accent)
        }
    }

    private var visibleAmount: String {
        amount.isEmpty ? "0" : amount
    }

    private var numericAmount: Double {
        Double(amount) ?? 0
    }

    private var amountBinding: Binding<String> {
        Binding(
            get: { amount },
            set: { newValue in
                let normalizedValue = normalizedAmount(newValue)
                guard normalizedValue != amount else { return }

                withAnimation(.snappy(duration: 0.2)) {
                    amount = normalizedValue
                }
            }
        )
    }

    private var formattedAvailableBalance: String {
        let balance = AppCurrency.aed.converted(12_480, to: selectedCurrency)
        return balance.formatted(
            FloatingPointFormatStyle<Double>()
                .grouping(.automatic)
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }

    private var canContinue: Bool {
        selectedDestination != nil && numericAmount > 0
    }

    private var confirmationTitle: String {
        guard let selectedDestination else { return "Review transfer" }
        return "Send \(visibleAmount) \(selectedCurrency.rawValue) to \(selectedDestination.messageName)?"
    }

    private var successMessage: String {
        guard let selectedDestination else { return "Your transfer is complete." }
        return "\(visibleAmount) \(selectedCurrency.rawValue) was sent to \(selectedDestination.messageName)."
    }

    private func normalizedAmount(_ value: String) -> String {
        let normalizedSeparator = value.replacingOccurrences(of: ",", with: ".")
        var result = ""
        var hasDecimalSeparator = false
        var integerDigits = 0
        var fractionDigits = 0

        for character in normalizedSeparator {
            if character.isNumber {
                if hasDecimalSeparator {
                    guard fractionDigits < 2 else { continue }
                    fractionDigits += 1
                } else {
                    guard integerDigits < 8 else { continue }
                    integerDigits += 1
                }
                result.append(character)
            } else if character == ".", !hasDecimalSeparator {
                hasDecimalSeparator = true
                if result.isEmpty {
                    result = "0"
                    integerDigits = 1
                }
                result.append(character)
            }
        }

        while result.count > 1, result.hasPrefix("0"), !result.hasPrefix("0.") {
            result.removeFirst()
        }

        return result
    }
}

struct TransferRecipientPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var selection: TransferDestination?

    init(selection: Binding<TransferDestination?>) {
        _selection = selection
    }

    var body: some View {
        NavigationStack {
            List {
                Text("New transfer")
                    .appFont(.largeTitle, weight: .bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityAddTraits(.isHeader)

                Section {
                    ForEach(TransferMethod.allCases) { method in
                        NavigationLink(value: method) {
                            TransferMethodRow(method: method)
                        }
                    }
                } header: {
                    Text("Transfer using")
                        .appFont(.footnote, weight: .medium)
                }

                Section {
                    ForEach(TransferContact.family) { contact in
                        contactButton(contact)
                    }
                } header: {
                    Text("Family")
                        .appFont(.footnote, weight: .medium)
                }

                Section {
                    ForEach(TransferContact.others) { contact in
                        contactButton(contact)
                    }
                } header: {
                    Text("Other contacts")
                        .appFont(.footnote, weight: .medium)
                }
            }
            .listStyle(.insetGrouped)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: TransferMethod.self) { method in
                TransferMethodEntryView(method: method) { value in
                    selection = .manual(method, value)
                    dismiss()
                }
            }
        }
        .background {
            AppNavigationTitleFontConfigurator(
                stylesBarButtons: true
            )
            .frame(width: 0, height: 0)
        }
    }

    private func contactButton(_ contact: TransferContact) -> some View {
        Button {
            selection = .contact(contact)
            dismiss()
        } label: {
            TransferContactRow(contact: contact)
        }
        .buttonStyle(.plain)
    }
}

private struct TransferMethodRow: View {
    let method: TransferMethod

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(method.title)
                    .appFont(.body, weight: .semibold)
                Text(method.subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: method.symbol)
                .foregroundStyle(method.color)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

private struct TransferMethodEntryView: View {
    @Environment(\.appThemePalette) private var palette
    let method: TransferMethod
    let onContinue: (String) -> Void
    @State private var value = ""
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        Form {
            Section {
                entryField
            } footer: {
                Text(method.helpText)
                    .appFont(.footnote)
            }
        }
        .navigationTitle(method.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            continueButton
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        .task {
            fieldIsFocused = true
        }
    }

    @ViewBuilder
    private var entryField: some View {
        switch method {
        case .bankAccount:
            TextField("IBAN or account number", text: $value)
                .appFont(.body)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($fieldIsFocused)
        case .phoneNumber:
            TextField("Phone number", text: $value)
                .appFont(.body)
                .keyboardType(.phonePad)
                .focused($fieldIsFocused)
        case .cardNumber:
            TextField("Card number", text: $value)
                .appFont(.body)
                .keyboardType(.numberPad)
                .focused($fieldIsFocused)
        }
    }

    private var continueButton: some View {
        Button {
            onContinue(trimmedValue)
        } label: {
            Text("Continue")
                .appFont(.body, weight: .bold)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .tint(palette.accent)
        .frame(maxWidth: .infinity)
        .disabled(trimmedValue.isEmpty)
    }

    private var trimmedValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct TransferDestinationRow: View {
    let destination: TransferDestination

    var body: some View {
        HStack(spacing: 14) {
            TransferDestinationAvatar(destination: destination, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(destination.title)
                    .appFont(.headline, weight: .bold)

                if let enteredValue = destination.enteredValue {
                    Text(verbatim: enteredValue)
                        .appFont(.footnote, weight: .semibold)
                        .foregroundStyle(.secondary)
                } else if let subtitle = destination.subtitle {
                    Text(subtitle)
                        .appFont(.footnote, weight: .semibold)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

private struct TransferContactRow: View {
    let contact: TransferContact

    var body: some View {
        HStack(spacing: 14) {
            TransferAvatar(
                color: contact.color,
                imageName: contact.imageName,
                initials: contact.initials,
                symbol: nil,
                size: 46
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .appFont(.body, weight: .semibold)
                Text(contact.detail)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct TransferDestinationAvatar: View {
    let destination: TransferDestination
    let size: CGFloat

    var body: some View {
        switch destination {
        case .contact(let contact):
            TransferAvatar(
                color: contact.color,
                imageName: contact.imageName,
                initials: contact.initials,
                symbol: nil,
                size: size
            )
        case .manual(let method, _):
            TransferAvatar(
                color: method.color,
                imageName: nil,
                initials: "",
                symbol: method.symbol,
                size: size
            )
        }
    }
}

private struct TransferAvatar: View {
    let color: Color
    let imageName: String?
    let initials: String
    let symbol: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient)

            if let imageName {
                Image(decorative: imageName)
                    .resizable()
                    .scaledToFill()
            } else if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            } else {
                Text(verbatim: initials)
                    .appFont(size: size * 0.32, weight: .heavy)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .clipShape(.circle)
    }
}

enum TransferDestination: Hashable {
    case contact(TransferContact)
    case manual(TransferMethod, String)

    var title: LocalizedStringResource {
        switch self {
        case .contact(let contact): contact.name
        case .manual(let method, _): method.title
        }
    }

    var subtitle: LocalizedStringResource? {
        switch self {
        case .contact(let contact): contact.detail
        case .manual: nil
        }
    }

    var enteredValue: String? {
        guard case .manual(_, let value) = self else { return nil }
        return value
    }

    var messageName: String {
        switch self {
        case .contact(let contact): contact.unlocalizedName
        case .manual(_, let value): value
        }
    }

    var color: Color {
        switch self {
        case .contact(let contact): contact.color
        case .manual(let method, _): method.color
        }
    }
}

enum TransferMethod: String, CaseIterable, Identifiable {
    case bankAccount
    case phoneNumber
    case cardNumber

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .bankAccount: "Bank account"
        case .phoneNumber: "Phone number"
        case .cardNumber: "Card number"
        }
    }

    var subtitle: LocalizedStringResource {
        switch self {
        case .bankAccount: "IBAN or account number"
        case .phoneNumber: "Use a mobile number"
        case .cardNumber: "Send directly to a card"
        }
    }

    var helpText: LocalizedStringResource {
        switch self {
        case .bankAccount: "Enter the recipient’s IBAN or account number."
        case .phoneNumber: "Enter the mobile number linked to the recipient’s account."
        case .cardNumber: "Enter the recipient’s debit or credit card number."
        }
    }

    var symbol: String {
        switch self {
        case .bankAccount: "building.columns"
        case .phoneNumber: "phone"
        case .cardNumber: "creditcard"
        }
    }

    var color: Color {
        switch self {
        case .bankAccount: .blue
        case .phoneNumber: .green
        case .cardNumber: .orange
        }
    }
}

enum TransferContact: String, CaseIterable, Identifiable {
    case layla
    case omar
    case aisha
    case daniel
    case mariam
    case noah

    static let family: [Self] = [.layla, .omar]
    static let others: [Self] = [.aisha, .daniel, .mariam, .noah]

    var id: Self { self }

    var name: LocalizedStringResource {
        switch self {
        case .layla: "Layla Hassan"
        case .omar: "Omar Ali"
        case .aisha: "Aisha Khan"
        case .daniel: "Daniel Reed"
        case .mariam: "Mariam Noor"
        case .noah: "Noah Williams"
        }
    }

    var unlocalizedName: String {
        switch self {
        case .layla: "Layla Hassan"
        case .omar: "Omar Ali"
        case .aisha: "Aisha Khan"
        case .daniel: "Daniel Reed"
        case .mariam: "Mariam Noor"
        case .noah: "Noah Williams"
        }
    }

    var initials: String {
        switch self {
        case .layla: "LH"
        case .omar: "OA"
        case .aisha: "AK"
        case .daniel: "DR"
        case .mariam: "MN"
        case .noah: "NW"
        }
    }

    var imageName: String? {
        switch self {
        case .layla: "contact_layla"
        case .aisha: "contact_aisha"
        case .daniel: "contact_daniel"
        case .omar, .mariam, .noah: nil
        }
    }

    var detail: LocalizedStringResource {
        switch self {
        case .layla: "Recently paid · •• 2841"
        case .omar: "Emirates NBD · •• 9018"
        case .aisha: "Mashreq · •• 1175"
        case .daniel: "HSBC UAE · •• 6630"
        case .mariam: "Recently paid · •• 4392"
        case .noah: "ADCB · •• 7746"
        }
    }

    var color: Color {
        switch self {
        case .layla: .purple
        case .omar: .orange
        case .aisha: .pink
        case .daniel: .blue
        case .mariam: .teal
        case .noah: .indigo
        }
    }
}
