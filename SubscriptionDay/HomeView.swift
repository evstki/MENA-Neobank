import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model

    private static let availableMonths: [Date] = {
        let anchor = AppModel.makeDate(year: 2026, month: 1, day: 1)
        return (-60...120).compactMap { AppModel.calendar.date(byAdding: .month, value: $0, to: anchor) }
    }()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ZStack {
                SDTheme.calendarBackground.ignoresSafeArea()
                AmbientGlow(warmOpacity: 0.06, coolOpacity: 0.05).ignoresSafeArea()

                TabView(selection: $model.selectedMonth) {
                    ForEach(Self.availableMonths, id: \.self) { month in
                        MonthPage(month: month)
                            .tag(month)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("List", selection: $model.listFilter) {
                            ForEach(SubscriptionListFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        Label(model.listFilter.rawValue, systemImage: "line.3.horizontal.decrease")
                    }
                    .accessibilityLabel("Subscription list, \(model.listFilter.rawValue)")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Search", systemImage: "magnifyingglass") {
                        model.showingSearch = true
                    }
                    .tint(SDTheme.accent)
                }
            }
        }
    }
}

private struct MonthPage: View {
    let month: Date

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 16)
                MonthSummary(month: month)
                Spacer(minLength: 22)
                MonthCalendar(month: month)
                    .frame(height: min(330, proxy.size.height * 0.49))
                    .padding(.bottom, 6)
                Spacer(minLength: 38)
            }
        }
    }
}

private struct MonthSummary: View {
    @Environment(AppModel.self) private var model
    let month: Date

    var body: some View {
        VStack(spacing: 12) {
            Text(month, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Monthly subscription total")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(amountText)
                .font(.system(size: 56, weight: .medium, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .minimumScaleFactor(0.65)
                .lineLimit(1)

            HStack(spacing: 9) {
                Image(systemName: "calendar.badge.clock")
                VStack(alignment: .leading, spacing: 1) {
                    Text(nextPaymentTitle)
                    Text(nextPaymentAmount)
                        .font(.caption.weight(.medium))
                        .opacity(0.82)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(SDTheme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(SDTheme.accent.opacity(0.16), in: .capsule)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Monthly subscription total, \(amountText), for \(month.formatted(.dateTime.month(.wide).year())). \(nextPaymentTitle), \(nextPaymentAmount)")
    }

    private var amountText: String {
        let amount = model.total(in: month)
        if amount.rounded() == amount {
            return "$\(Int(amount))"
        }
        return String(format: "$%.2f", locale: Locale(identifier: "en_US_POSIX"), amount)
    }

    private var nextPaymentTitle: String {
        guard let payment = model.nextPayment() else { return "No upcoming payments" }
        let today = AppModel.calendar.startOfDay(for: Date())
        let paymentDay = AppModel.calendar.startOfDay(for: payment.date)
        let days = AppModel.calendar.dateComponents([.day], from: today, to: paymentDay).day ?? 0
        switch days {
        case 0: return "Next payment today"
        case 1: return "Next payment tomorrow"
        default: return "Next payment in \(days) days"
        }
    }

    private var nextPaymentAmount: String {
        guard let payment = model.nextPayment() else { return "Add a subscription to see it here" }
        if payment.amount.rounded() == payment.amount {
            return "$\(Int(payment.amount))"
        }
        return String(format: "$%.2f", locale: Locale(identifier: "en_US_POSIX"), payment.amount)
    }
}

private struct MonthCalendar: View {
    let month: Date
    private let weekdayNames = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    var body: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdayNames.enumerated(), id: \.offset) { _, name in
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(days) { day in
                    CalendarDayCell(day: day)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var days: [CalendarDate] {
        let calendar = AppModel.calendar
        let weekday = calendar.component(.weekday, from: month)
        guard let firstVisibleDate = calendar.date(byAdding: .day, value: -(weekday - 1), to: month) else {
            return []
        }

        return (0..<42).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: firstVisibleDate) else {
                return nil
            }
            return CalendarDate(
                date: date,
                isInDisplayedMonth: calendar.isDate(date, equalTo: month, toGranularity: .month)
            )
        }
    }
}

private struct CalendarDate: Identifiable {
    let date: Date
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

private struct CalendarDayCell: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    let day: CalendarDate

    var body: some View {
        Button {
            model.select(day: dayNumber, in: day.date)
        } label: {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cellFill)
                .overlay(alignment: .center) {
                    if !daySubscriptions.isEmpty {
                        HStack(spacing: -5) {
                            ForEach(daySubscriptions.prefix(2)) { subscription in
                                ServiceLogo(service: subscription.service, size: 25)
                            }
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("\(dayNumber)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(day.isInDisplayedMonth ? .secondary : .tertiary)
                        .padding(6)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isSelected ? 2.5 : 1)
                }
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var dayNumber: Int {
        AppModel.calendar.component(.day, from: day.date)
    }

    private var daySubscriptions: [SubscriptionRecord] {
        model.subscriptions(on: day.date)
    }

    private var isSelected: Bool {
        AppModel.calendar.isDate(day.date, inSameDayAs: model.selectedDate)
    }

    private var cellFill: Color {
        if let subscription = daySubscriptions.first {
            return subscription.service.brandTint.opacity(colorScheme == .dark ? 0.48 : 0.25)
        }

        if day.isInDisplayedMonth {
            return Color.primary.opacity(colorScheme == .dark ? 0.17 : 0.10)
        }

        return Color.primary.opacity(colorScheme == .dark ? 0.065 : 0.055)
    }

    private var borderColor: Color {
        if isSelected { return SDTheme.accent }
        if let subscription = daySubscriptions.first {
            return subscription.service.brandTint.opacity(colorScheme == .dark ? 0.82 : 0.52)
        }
        return .clear
    }

    private var accessibilityText: String {
        let count = daySubscriptions.count
        let dateText = day.date.formatted(.dateTime.day().month(.wide).year())
        return count == 0 ? "\(dateText), no subscriptions" : "\(dateText), \(count) subscriptions"
    }
}

struct DaySubscriptionsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if daySubscriptions.isEmpty {
                    ContentUnavailableView(
                        "No Subscriptions",
                        systemImage: "calendar.badge.plus",
                        description: Text("Add a subscription scheduled for this day.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section("Subscriptions") {
                        ForEach(daySubscriptions) { subscription in
                            Button {
                                open(subscription)
                            } label: {
                                SubscriptionRow(subscription: subscription)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    model.deleteSubscription(id: subscription.id)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Add Subscription", systemImage: "plus", action: addSubscription)
                    LabeledContent("Total") {
                        Text(dayTotal, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle(model.selectedDate.formatted(.dateTime.day().month(.wide).year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus", action: addSubscription)
                }
            }
        }
    }

    private var daySubscriptions: [SubscriptionRecord] {
        model.subscriptions(on: model.selectedDate)
    }

    private var dayTotal: Double {
        daySubscriptions.reduce(0) { $0 + $1.amount }
    }

    private func open(_ subscription: SubscriptionRecord) {
        model.selectedSubscriptionID = subscription.id
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            model.showingSubscriptionDetail = true
        }
    }

    private func addSubscription() {
        model.draftStartDate = model.selectedDate
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            model.showingCatalog = true
        }
    }
}

private struct SubscriptionRow: View {
    let subscription: SubscriptionRecord

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: subscription.service, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.headline)
                Text("\(subscription.schedule.rawValue) · \(subscription.amount.formatted(.currency(code: "USD")))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SubscriptionDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let subscriptionID: UUID
    @State private var showingEdit = false

    var body: some View {
        NavigationStack {
            if let subscription {
                Form {
                    Section {
                        VStack(spacing: 10) {
                            ServiceLogo(service: subscription.service, size: 82)
                                .shadow(color: subscription.service.brandTint.opacity(0.55), radius: 24)
                            Text(subscription.name)
                                .font(.title2.bold())
                            Text("\(subscription.schedule.rawValue) · \(subscription.amount.formatted(.currency(code: "USD")))")
                                .foregroundStyle(.secondary)
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Rectangle().fill(.ultraThinMaterial))

                    Section("Billing") {
                        LabeledContent("Amount", value: subscription.amount.formatted(.currency(code: "USD")))
                        LabeledContent("Next Payment") {
                            Text(subscription.startDate, format: .dateTime.day().month(.abbreviated).year())
                        }
                        LabeledContent("Notifications", value: subscription.notifications)
                    }
                    .listRowBackground(Rectangle().fill(.ultraThinMaterial))

                    Section("Organization") {
                        LabeledContent("Category", value: subscription.category.rawValue)
                        LabeledContent("List", value: subscription.listName)
                        LabeledContent("Payment Method", value: subscription.paymentMethod)
                    }
                    .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                }
                .scrollContentBackground(.hidden)
                .background {
                    SubscriptionDetailBackdrop(tint: subscription.service.brandTint)
                }
                .tint(subscription.service.brandTint)
                .navigationTitle("Subscription")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { showingEdit = true }
                    }
                }
            } else {
                ContentUnavailableView("Subscription Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let subscription {
                EditSubscriptionView(subscription: subscription)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: model.selectedSubscriptionID) { _, newValue in
            if newValue == nil { dismiss() }
        }
    }

    private var subscription: SubscriptionRecord? {
        model.subscription(id: subscriptionID)
    }
}

private struct SubscriptionDetailBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(uiColor: .systemGroupedBackground)

                RadialGradient(
                    colors: [
                        tint.opacity(colorScheme == .dark ? 0.68 : 0.34),
                        tint.opacity(colorScheme == .dark ? 0.28 : 0.14),
                        .clear
                    ],
                    center: .top,
                    startRadius: 8,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )
                .scaleEffect(1.22)
                .blur(radius: 30)

                LinearGradient(
                    colors: [.clear, Color(uiColor: .systemGroupedBackground).opacity(0.66)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    HomeView()
        .environment(AppModel())
}
