import SwiftUI

struct AddSubscriptionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appCurrency) private var mainCurrency
    @Environment(\.locale) private var locale
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        NewSubscriptionView(
                            service: ServiceCatalog.customTemplate,
                            initialStartDate: model.draftStartDate ?? .now,
                            initialCurrency: mainCurrency,
                            initialName: query,
                            usesCustomBrand: true
                        )
                    } label: {
                        Label {
                            if query.isEmpty {
                                Text("Add Custom Subscription")
                            } else {
                                Text(AppLocalization.string(
                                    "Create “%@”",
                                    locale: locale,
                                    arguments: query
                                ))
                            }
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .appFont(.headline, weight: .semibold)
                    }
                }
                .appThemedSurfaceRow()

                if query.isEmpty {
                    Section("Popular Services") {
                        ForEach(ServiceCatalog.popular(locale: locale)) { service in
                            NavigationLink(value: service) {
                                CatalogServiceRow(service: service)
                            }
                        }
                    }
                    .appThemedSurfaceRow()

                    Section("Mobile Providers") {
                        ForEach(ServiceCatalog.mobileProviders(locale: locale)) { service in
                            NavigationLink(value: service) {
                                CatalogServiceRow(service: service)
                            }
                        }
                    }
                    .appThemedSurfaceRow()

                    Section("All Services") {
                        ForEach(ServiceCatalog.all(locale: locale)) { service in
                            NavigationLink(value: service) {
                                CatalogServiceRow(service: service)
                            }
                        }
                    }
                    .appThemedSurfaceRow()
                } else if filteredServices.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .listRowBackground(Color.clear)
                } else {
                    Section("Search Results") {
                        ForEach(filteredServices) { service in
                            NavigationLink(value: service) {
                                CatalogServiceRow(service: service)
                            }
                        }
                    }
                    .appThemedSurfaceRow()
                }
            }
            .appThemedScreenBackground()
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search or enter a service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        model.draftStartDate = nil
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: ServiceBrand.self) { service in
                NewSubscriptionView(
                    service: service,
                    initialStartDate: model.draftStartDate ?? .now,
                    initialCurrency: mainCurrency
                )
            }
        }
    }

    private var filteredServices: [ServiceBrand] {
        ServiceCatalog.visibleServices(locale: locale).filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

}

private struct CatalogServiceRow: View {
    @Environment(\.locale) private var locale
    let service: ServiceBrand

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: service, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .appFont(.headline, weight: .semibold)
                    .lineLimit(1)
                Text(service.category.localizedTitle(locale: locale))
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let suggestedPrice = service.suggestedPrice {
                Text(suggestedPrice.formattedAmount)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private enum SubscriptionFormField: Hashable {
    case name
    case amount
    case cardName
}

struct NewSubscriptionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let service: ServiceBrand
    private let usesCustomBrand: Bool

    @State private var name: String
    @State private var schedule: PaymentSchedule
    @State private var startDate: Date
    @State private var hasEndDate = false
    @State private var endDate: Date
    @State private var amountText: String
    @State private var currency: AppCurrency
    @State private var category: SubscriptionCategory
    @State private var paymentMethod = "None"
    @State private var cardName = ""
    @State private var notifications = "Default"
    @State private var customIconSymbol: String
    @State private var customIconColor: String
    @FocusState private var focusedField: SubscriptionFormField?

    init(
        service: ServiceBrand,
        initialStartDate: Date,
        initialCurrency: AppCurrency = .usd,
        initialName: String? = nil,
        usesCustomBrand: Bool = false
    ) {
        self.service = service
        self.usesCustomBrand = usesCustomBrand
        let suggestedPrice = service.suggestedPrice
        _name = State(initialValue: initialName ?? service.name)
        _schedule = State(initialValue: suggestedPrice?.schedule ?? .monthly)
        _amountText = State(initialValue: suggestedPrice.map { Self.amountString($0.amount) } ?? "")
        _currency = State(initialValue: suggestedPrice?.currency ?? initialCurrency)
        _category = State(initialValue: service.category)
        _startDate = State(initialValue: initialStartDate)
        _endDate = State(initialValue: AppModel.calendar.date(byAdding: .year, value: 1, to: initialStartDate) ?? initialStartDate)
        _customIconSymbol = State(initialValue: service.usesCustomIcon ? service.fallbackSymbol : "initial")
        _customIconColor = State(initialValue: service.usesCustomIcon ? service.fallbackColor : "7354E8")
    }

    var body: some View {
        Form {
            SubscriptionFormSections(
                service: resolvedService,
                name: $name,
                schedule: $schedule,
                startDate: $startDate,
                hasEndDate: $hasEndDate,
                endDate: $endDate,
                amountText: $amountText,
                currency: $currency,
                category: $category,
                paymentMethod: $paymentMethod,
                cardName: $cardName,
                notifications: $notifications,
                allowsIconCustomization: usesCustomBrand,
                showsActiveStatus: false,
                customIconSymbol: $customIconSymbol,
                customIconColor: $customIconColor,
                focusedField: $focusedField
            )
        }
        .appThemedScreenBackground()
        .navigationTitle("New Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: addSubscription)
                    .buttonStyle(.borderedProminent)
                    .tint(palette.accent)
                    .foregroundStyle(palette.accentForeground)
                    .disabled(!canAdd)
            }
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField == .name {
                    Button("Next") { focusedField = .amount }
                }
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            await Task.yield()
            focusedField = usesCustomBrand ? .name : .amount
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private static func amountString(_ amount: Double) -> String {
        amount.rounded() == amount ? String(format: "%.0f", amount) : String(format: "%.2f", amount)
    }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (parsedAmount ?? 0) > 0
    }

    private var resolvedService: ServiceBrand {
        guard usesCustomBrand else { return service }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return ServiceBrand(
            trimmedName.isEmpty ? "Custom Subscription" : trimmedName,
            symbol: customIconSymbol,
            color: customIconColor,
            category: category,
            customIcon: true
        )
    }

    private func addSubscription() {
        guard let amount = parsedAmount, amount > 0 else { return }
        let subscription = SubscriptionRecord(
            service: resolvedService,
            name: name,
            amount: amount,
            currency: currency,
            schedule: schedule,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            category: category,
            paymentMethod: paymentMethod,
            cardName: cardName.trimmingCharacters(in: .whitespacesAndNewlines),
            notifications: notifications
        )
        model.showingCatalog = false
        dismiss()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            model.add(subscription)
        }
    }
}

struct EditSubscriptionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    private let subscriptionID: UUID
    private let service: ServiceBrand
    private let usesCustomBrand: Bool

    @State private var name: String
    @State private var schedule: PaymentSchedule
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var amountText: String
    @State private var currency: AppCurrency
    @State private var category: SubscriptionCategory
    @State private var paymentMethod: String
    @State private var cardName: String
    @State private var notifications: String
    @State private var customIconSymbol: String
    @State private var customIconColor: String
    @State private var confirmingDelete = false
    @FocusState private var focusedField: SubscriptionFormField?

    init(subscription: SubscriptionRecord) {
        subscriptionID = subscription.id
        service = subscription.service
        usesCustomBrand = subscription.service.usesCustomIcon || !ServiceCatalog.contains(subscription.service)
        _name = State(initialValue: subscription.name)
        _schedule = State(initialValue: subscription.schedule)
        _startDate = State(initialValue: subscription.startDate)
        _hasEndDate = State(initialValue: subscription.endDate != nil)
        _endDate = State(initialValue: subscription.endDate
            ?? AppModel.calendar.date(byAdding: .year, value: 1, to: subscription.startDate)
            ?? subscription.startDate)
        _amountText = State(initialValue: Self.amountString(subscription.amount))
        _currency = State(initialValue: subscription.currency)
        _category = State(initialValue: subscription.category)
        _paymentMethod = State(initialValue: subscription.paymentMethod)
        _cardName = State(initialValue: subscription.cardName)
        _notifications = State(initialValue: subscription.notifications)
        _customIconSymbol = State(initialValue: service.usesCustomIcon ? service.fallbackSymbol : "initial")
        _customIconColor = State(initialValue: service.usesCustomIcon ? service.fallbackColor : "7354E8")
    }

    var body: some View {
        NavigationStack {
            Form {
                SubscriptionFormSections(
                    service: resolvedService,
                    name: $name,
                    schedule: $schedule,
                    startDate: $startDate,
                    hasEndDate: $hasEndDate,
                    endDate: $endDate,
                    amountText: $amountText,
                    currency: $currency,
                    category: $category,
                    paymentMethod: $paymentMethod,
                    cardName: $cardName,
                    notifications: $notifications,
                    allowsIconCustomization: usesCustomBrand,
                    showsActiveStatus: true,
                    customIconSymbol: $customIconSymbol,
                    customIconColor: $customIconColor,
                    focusedField: $focusedField
                )

                Section {
                    deleteSubscriptionButton
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .appThemedScreenBackground()
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Save", action: saveSubscription)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField == .name {
                        Button("Next") { focusedField = .amount }
                    }
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Delete Subscription", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteSubscription)
        } message: {
            Text("Are you sure you want to delete this subscription? This action cannot be undone.")
        }
    }

    @ViewBuilder
    private var deleteSubscriptionButton: some View {
        if #available(iOS 26.0, *) {
            deleteSubscriptionButtonContent
                .buttonStyle(.glass)
                .tint(.red)
        } else {
            deleteSubscriptionButtonContent
                .buttonStyle(.bordered)
                .tint(.red)
        }
    }

    private var deleteSubscriptionButtonContent: some View {
        Button(role: .destructive) {
            confirmingDelete = true
        } label: {
            Label("Delete Subscription", systemImage: "trash")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
        }
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (parsedAmount ?? 0) > 0
    }

    private var resolvedService: ServiceBrand {
        guard usesCustomBrand else { return service }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return ServiceBrand(
            trimmedName.isEmpty ? service.name : trimmedName,
            symbol: customIconSymbol,
            color: customIconColor,
            category: category,
            customIcon: true
        )
    }

    private func saveSubscription() {
        guard let amount = parsedAmount, amount > 0 else { return }
        model.update(SubscriptionRecord(
            id: subscriptionID,
            service: resolvedService,
            name: name,
            amount: amount,
            currency: currency,
            schedule: schedule,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            category: category,
            paymentMethod: paymentMethod,
            cardName: cardName.trimmingCharacters(in: .whitespacesAndNewlines),
            notifications: notifications
        ))
        dismiss()
    }

    private func deleteSubscription() {
        model.deleteSubscription(id: subscriptionID)
        dismiss()
    }

    private static func amountString(_ amount: Double) -> String {
        amount.rounded() == amount ? String(format: "%.0f", amount) : String(format: "%.2f", amount)
    }
}

private struct SubscriptionFormSections: View {
    @Environment(\.appThemePalette) private var palette
    let service: ServiceBrand
    @Binding var name: String
    @Binding var schedule: PaymentSchedule
    @Binding var startDate: Date
    @Binding var hasEndDate: Bool
    @Binding var endDate: Date
    @Binding var amountText: String
    @Binding var currency: AppCurrency
    @Binding var category: SubscriptionCategory
    @Binding var paymentMethod: String
    @Binding var cardName: String
    @Binding var notifications: String
    let allowsIconCustomization: Bool
    let showsActiveStatus: Bool
    @Binding var customIconSymbol: String
    @Binding var customIconColor: String
    let focusedField: FocusState<SubscriptionFormField?>.Binding
    @State private var showsMoreOptions = false
    @State private var showsIconPicker = false

    var body: some View {
        Section {
            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    ServiceLogo(service: service, size: 52)

                    if allowsIconCustomization {
                        Button {
                            focusedField.wrappedValue = nil
                            showsIconPicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(palette.accent)
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        Circle()
                                            .stroke(palette.surface, lineWidth: 2)
                                    }
                                    .shadow(color: .black.opacity(0.22), radius: 2, y: 1)

                                Image(systemName: "pencil")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(palette.accentForeground)
                            }
                            .frame(width: 40, height: 40)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Customize Icon")
                        .offset(x: 12, y: 12)
                    }
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 5) {
                    TextField("Subscription Name", text: $name)
                        .appFont(.headline, weight: .semibold)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused(focusedField, equals: .name)
                        .onSubmit {
                            focusedField.wrappedValue = .amount
                        }

                    if showsActiveStatus {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .appFont(.subheadline, weight: .medium)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .appThemedSurfaceRow()
        .sheet(isPresented: $showsIconPicker) {
            CustomSubscriptionIconPicker(
                name: name,
                symbol: $customIconSymbol,
                colorHex: $customIconColor
            )
        }

        Section {
            HStack(spacing: 10) {
                if currency != .aed {
                    currencyLabel
                }

                TextField("0.00", text: $amountText)
                    .appFont(.title2, weight: .bold)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .monospacedDigit()
                    .focused(focusedField, equals: .amount)
                    .accessibilityLabel("Amount")

                if currency == .aed {
                    currencyLabel
                }

                Spacer(minLength: 8)

                Picker("Currency", selection: $currency) {
                    ForEach(AppCurrency.allCases) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Currency")
            }
            .padding(.vertical, 3)
            .environment(\.layoutDirection, .leftToRight)

            Picker("Billing Cycle", selection: $schedule) {
                ForEach(PaymentSchedule.allCases) { value in
                    Text(value.localizedTitleKey).tag(value)
                }
            }

            DatePicker("First Payment", selection: $startDate, displayedComponents: .date)
        }
        .appThemedSurfaceRow()

        Section {
            Button {
                withAnimation(.easeInOut(duration: 0.20)) {
                    showsMoreOptions.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Label("More Options", systemImage: "slider.horizontal.3")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("Optional")
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showsMoreOptions ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                showsMoreOptions ? Text("Hide More Options") : Text("Show More Options")
            )

            if showsMoreOptions {
                Toggle("End Date", isOn: $hasEndDate)
                    .tint(palette.toggleTint)

                if hasEndDate {
                    DatePicker("Ends", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Picker("Category", selection: $category) {
                    ForEach(SubscriptionCategory.allCases) { value in
                        Text(value.localizedTitleKey).tag(value)
                    }
                }

                Picker("Payment Method", selection: $paymentMethod) {
                    ForEach(["None", "Visa", "Cash"], id: \.self) { value in
                        Text(LocalizedStringKey(value)).tag(value)
                    }
                }

                LabeledContent("Card Name") {
                    TextField("Personal Visa", text: $cardName)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused(focusedField, equals: .cardName)
                }

                Picker("Reminder", selection: $notifications) {
                    ForEach(["Default", "None", "1 Day"], id: \.self) { value in
                        Text(LocalizedStringKey(value)).tag(value)
                    }
                }
            }
        }
        .appThemedSurfaceRow()
        .animation(.easeInOut(duration: 0.20), value: showsMoreOptions)
        .animation(.easeInOut(duration: 0.20), value: hasEndDate)
        .onAppear {
            if hasEndDate
                || category != service.category
                || paymentMethod != "None"
                || !cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || notifications != "Default" {
                showsMoreOptions = true
            }
        }
    }

    private var currencyLabel: some View {
        Text(currency.symbol)
            .appFont(.title2, weight: .semibold)
            .foregroundStyle(palette.accent)
    }
}

private struct CustomSubscriptionIconPicker: View {
    private struct IconOption: Identifiable {
        let symbol: String
        let title: LocalizedStringKey
        var id: String { symbol }
    }

    private struct ColorOption: Identifiable {
        let hex: String
        let title: LocalizedStringKey
        var id: String { hex }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let name: String
    @Binding var symbol: String
    @Binding var colorHex: String

    private let colorOptions: [ColorOption] = [
        ColorOption(hex: "477CF1", title: "Blue"),
        ColorOption(hex: "7354E8", title: "Purple"),
        ColorOption(hex: "D14FA0", title: "Pink"),
        ColorOption(hex: "EB6A32", title: "Orange"),
        ColorOption(hex: "E84C5B", title: "Red"),
        ColorOption(hex: "D99B28", title: "Yellow"),
        ColorOption(hex: "29A36A", title: "Green"),
        ColorOption(hex: "1A9E9F", title: "Teal"),
        ColorOption(hex: "697386", title: "Gray"),
        ColorOption(hex: "181818", title: "Black")
    ]

    private let iconOptions: [IconOption] = [
        IconOption(symbol: "initial", title: "Initial"),
        IconOption(symbol: "sparkles", title: "Sparkles"),
        IconOption(symbol: "cart.fill", title: "Shopping"),
        IconOption(symbol: "shippingbox.fill", title: "Delivery"),
        IconOption(symbol: "gift.fill", title: "Gifts"),
        IconOption(symbol: "ticket.fill", title: "Tickets"),
        IconOption(symbol: "bolt.fill", title: "Lightning"),
        IconOption(symbol: "fuelpump.fill", title: "Fuel"),
        IconOption(symbol: "house.fill", title: "Home"),
        IconOption(symbol: "building.2.fill", title: "Building"),
        IconOption(symbol: "bed.double.fill", title: "Home Services"),
        IconOption(symbol: "car.fill", title: "Car"),
        IconOption(symbol: "bicycle", title: "Bicycle"),
        IconOption(symbol: "airplane", title: "Travel"),
        IconOption(symbol: "tram.fill", title: "Transit"),
        IconOption(symbol: "fork.knife", title: "Food"),
        IconOption(symbol: "cup.and.saucer.fill", title: "Coffee"),
        IconOption(symbol: "wineglass.fill", title: "Drinks"),
        IconOption(symbol: "gamecontroller.fill", title: "Games"),
        IconOption(symbol: "music.note", title: "Music"),
        IconOption(symbol: "headphones", title: "Audio"),
        IconOption(symbol: "mic.fill", title: "Podcasts"),
        IconOption(symbol: "play.fill", title: "Video"),
        IconOption(symbol: "tv.fill", title: "TV"),
        IconOption(symbol: "film.fill", title: "Movies"),
        IconOption(symbol: "camera.fill", title: "Photography"),
        IconOption(symbol: "heart.fill", title: "Health"),
        IconOption(symbol: "cross.case.fill", title: "Medical"),
        IconOption(symbol: "pawprint.fill", title: "Pets"),
        IconOption(symbol: "dumbbell.fill", title: "Fitness"),
        IconOption(symbol: "figure.run", title: "Running"),
        IconOption(symbol: "phone.fill", title: "Phone"),
        IconOption(symbol: "antenna.radiowaves.left.and.right", title: "Internet"),
        IconOption(symbol: "wifi", title: "Wi-Fi"),
        IconOption(symbol: "cloud.fill", title: "Cloud"),
        IconOption(symbol: "lock.fill", title: "Security"),
        IconOption(symbol: "key.fill", title: "Keys"),
        IconOption(symbol: "shield.fill", title: "Protection"),
        IconOption(symbol: "creditcard.fill", title: "Payments"),
        IconOption(symbol: "banknote.fill", title: "Finance"),
        IconOption(symbol: "wallet.pass.fill", title: "Wallet"),
        IconOption(symbol: "chart.line.uptrend.xyaxis", title: "Investing"),
        IconOption(symbol: "graduationcap.fill", title: "Education"),
        IconOption(symbol: "book.fill", title: "Books"),
        IconOption(symbol: "newspaper.fill", title: "News"),
        IconOption(symbol: "briefcase.fill", title: "Work"),
        IconOption(symbol: "paintbrush.fill", title: "Creative"),
        IconOption(symbol: "calendar", title: "Calendar"),
        IconOption(symbol: "doc.text.fill", title: "Documents"),
        IconOption(symbol: "globe", title: "Web"),
        IconOption(symbol: "map.fill", title: "Maps"),
        IconOption(symbol: "person.2.fill", title: "Community"),
        IconOption(symbol: "bell.fill", title: "Alerts")
    ]

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    iconContent(symbol: symbol, size: 27)
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                        .background(Color(hex: colorHex), in: Circle())
                        .shadow(color: Color(hex: colorHex).opacity(0.30), radius: 10, y: 5)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon Color")
                            .appFont(.headline, weight: .semibold)
                        LazyVGrid(columns: colorColumns, spacing: 12) {
                            ForEach(colorOptions) { option in
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        colorHex = option.hex
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: option.hex))

                                        if colorHex == option.hex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(width: 38, height: 38)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(option.title))
                                .accessibilityAddTraits(colorHex == option.hex ? .isSelected : [])
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .appFont(.headline, weight: .semibold)
                        LazyVGrid(columns: iconColumns, spacing: 10) {
                            ForEach(iconOptions) { option in
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        symbol = option.symbol
                                    }
                                } label: {
                                    iconContent(symbol: option.symbol, size: 19)
                                        .foregroundStyle(symbol == option.symbol ? .white : .primary)
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .background(
                                            symbol == option.symbol ? Color(hex: colorHex) : palette.elevatedSurface,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(option.title))
                                .accessibilityAddTraits(symbol == option.symbol ? .isSelected : [])
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Customize Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(520), .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func iconContent(symbol: String, size: CGFloat) -> some View {
        if symbol == "initial" {
            Text(name.trimmingCharacters(in: .whitespacesAndNewlines).first.map {
                String($0).uppercased()
            } ?? "?")
                .appFont(size: size, weight: .bold)
        } else {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
        }
    }
}

#Preview {
    AddSubscriptionView()
        .environment(AppModel())
}
