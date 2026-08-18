import SwiftUI

struct AddSubscriptionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section("Import") {
                        ImportRow(title: "Import from App Store", systemImage: "apple.logo", action: showImportMessage)
                        ImportRow(title: "Import from Notion", systemImage: "square.text.square", action: showImportMessage)
                        ImportRow(title: "Import from Google Sheets", systemImage: "tablecells", action: showImportMessage)
                    }

                    Section("Popular Services") {
                        ForEach(ServiceCatalog.popular) { service in
                            NavigationLink(value: service) {
                                CatalogServiceRow(service: service)
                            }
                        }
                    }

                    Section("All Services") {
                        ForEach(ServiceCatalog.all) { service in
                            NavigationLink(value: service) {
                                CatalogServiceRow(service: service)
                            }
                        }
                    }
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
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Services")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        model.draftStartDate = nil
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: ServiceBrand.self) { service in
                NewSubscriptionView(service: service, initialStartDate: model.draftStartDate ?? .now)
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

    private var filteredServices: [ServiceBrand] {
        ServiceCatalog.services.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func showImportMessage(_ title: String) {
        alertMessage = "\(title) is ready to connect."
    }
}

private struct ImportRow: View {
    let title: String
    let systemImage: String
    let action: (String) -> Void

    var body: some View {
        Button {
            action(title)
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}

private struct CatalogServiceRow: View {
    let service: ServiceBrand

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: service, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.headline)
                Text(service.category.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct NewSubscriptionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let service: ServiceBrand

    @State private var name: String
    @State private var schedule: PaymentSchedule = .monthly
    @State private var startDate: Date
    @State private var hasEndDate = false
    @State private var endDate: Date
    @State private var amountText = ""
    @State private var category: SubscriptionCategory
    @State private var paymentMethod = "None"
    @State private var listName = "Personal"
    @State private var notifications = "Default"
    @FocusState private var amountIsFocused: Bool

    init(service: ServiceBrand, initialStartDate: Date) {
        self.service = service
        _name = State(initialValue: service.name)
        _category = State(initialValue: service.category)
        _startDate = State(initialValue: initialStartDate)
        _endDate = State(initialValue: AppModel.calendar.date(byAdding: .year, value: 1, to: initialStartDate) ?? initialStartDate)
    }

    var body: some View {
        Form {
            SubscriptionFormSections(
                service: service,
                name: $name,
                schedule: $schedule,
                startDate: $startDate,
                hasEndDate: $hasEndDate,
                endDate: $endDate,
                amountText: $amountText,
                category: $category,
                paymentMethod: $paymentMethod,
                listName: $listName,
                notifications: $notifications,
                amountFocus: $amountIsFocused
            )
        }
        .navigationTitle("New Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: addSubscription)
                    .disabled(!canAdd)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { amountIsFocused = false }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (parsedAmount ?? 0) > 0
    }

    private func addSubscription() {
        guard let amount = parsedAmount, amount > 0 else { return }
        model.add(SubscriptionRecord(
            service: service,
            name: name,
            amount: amount,
            schedule: schedule,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            category: category,
            paymentMethod: paymentMethod,
            listName: listName,
            notifications: notifications
        ))
        model.showingCatalog = false
        dismiss()
    }
}

struct EditSubscriptionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    private let subscriptionID: UUID
    private let service: ServiceBrand

    @State private var name: String
    @State private var schedule: PaymentSchedule
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var amountText: String
    @State private var category: SubscriptionCategory
    @State private var paymentMethod: String
    @State private var listName: String
    @State private var notifications: String
    @State private var confirmingDelete = false
    @FocusState private var amountIsFocused: Bool

    init(subscription: SubscriptionRecord) {
        subscriptionID = subscription.id
        service = subscription.service
        _name = State(initialValue: subscription.name)
        _schedule = State(initialValue: subscription.schedule)
        _startDate = State(initialValue: subscription.startDate)
        _hasEndDate = State(initialValue: subscription.endDate != nil)
        _endDate = State(initialValue: subscription.endDate
            ?? AppModel.calendar.date(byAdding: .year, value: 1, to: subscription.startDate)
            ?? subscription.startDate)
        _amountText = State(initialValue: Self.amountString(subscription.amount))
        _category = State(initialValue: subscription.category)
        _paymentMethod = State(initialValue: subscription.paymentMethod)
        _listName = State(initialValue: subscription.listName)
        _notifications = State(initialValue: subscription.notifications)
    }

    var body: some View {
        NavigationStack {
            Form {
                SubscriptionFormSections(
                    service: service,
                    name: $name,
                    schedule: $schedule,
                    startDate: $startDate,
                    hasEndDate: $hasEndDate,
                    endDate: $endDate,
                    amountText: $amountText,
                    category: $category,
                    paymentMethod: $paymentMethod,
                    listName: $listName,
                    notifications: $notifications,
                    amountFocus: $amountIsFocused
                )
            }
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        confirmingDelete = true
                    }
                    Button("Save", action: saveSubscription)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountIsFocused = false }
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

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (parsedAmount ?? 0) > 0
    }

    private func saveSubscription() {
        guard let amount = parsedAmount, amount > 0 else { return }
        model.update(SubscriptionRecord(
            id: subscriptionID,
            service: service,
            name: name,
            amount: amount,
            schedule: schedule,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            category: category,
            paymentMethod: paymentMethod,
            listName: listName,
            notifications: notifications
        ))
        dismiss()
    }

    private func deleteSubscription() {
        model.deleteSubscription(id: subscriptionID)
        model.showingSubscriptionDetail = false
        dismiss()
    }

    private static func amountString(_ amount: Double) -> String {
        amount.rounded() == amount ? String(format: "%.0f", amount) : String(format: "%.2f", amount)
    }
}

private struct SubscriptionFormSections: View {
    let service: ServiceBrand
    @Binding var name: String
    @Binding var schedule: PaymentSchedule
    @Binding var startDate: Date
    @Binding var hasEndDate: Bool
    @Binding var endDate: Date
    @Binding var amountText: String
    @Binding var category: SubscriptionCategory
    @Binding var paymentMethod: String
    @Binding var listName: String
    @Binding var notifications: String
    let amountFocus: FocusState<Bool>.Binding

    var body: some View {
        Section {
            VStack(spacing: 8) {
                ServiceLogo(service: service, size: 72)
                Text(service.name)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }

        Section("Subscription") {
            TextField("Name", text: $name)
            Picker("Payment Schedule", selection: $schedule) {
                ForEach(PaymentSchedule.allCases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            Toggle("End Date", isOn: $hasEndDate.animation())
            if hasEndDate {
                DatePicker("Ends", selection: $endDate, in: startDate..., displayedComponents: .date)
            }
        }

        Section {
            HStack {
                Text("USD")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused(amountFocus)
            }
        } header: {
            Text("Amount")
        } footer: {
            Text("Enter the charge for each billing period.")
        }

        Section("Organization") {
            Picker("Category", selection: $category) {
                ForEach(SubscriptionCategory.allCases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            Picker("Pay With", selection: $paymentMethod) {
                ForEach(["None", "Visa", "Cash"], id: \.self, content: Text.init)
            }
            Picker("List", selection: $listName) {
                ForEach(["Personal", "Work"], id: \.self, content: Text.init)
            }
            Picker("Notifications", selection: $notifications) {
                ForEach(["Default", "None", "1 Day"], id: \.self, content: Text.init)
            }
        }
    }
}

#Preview {
    AddSubscriptionView()
        .environment(AppModel())
}
