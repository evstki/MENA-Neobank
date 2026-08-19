import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appThemePalette) private var palette
    @State private var showingSettings = false
    @State private var returnFromMonth: Date?
    @State private var returnSlideOffset: CGFloat = 0

    private static let availableMonths: [Date] = {
        let anchor = AppModel.makeDate(year: 2026, month: 1, day: 1)
        return (-60...120).compactMap { AppModel.calendar.date(byAdding: .month, value: $0, to: anchor) }
    }()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                HomeAnimatedBackdrop()

                GeometryReader { proxy in
                    TabView(selection: $model.selectedMonth) {
                        ForEach(Self.availableMonths, id: \.self) { month in
                            MonthPage(month: month) {
                                returnToCurrentMonth(from: month, pageWidth: proxy.size.width)
                            }
                            .tag(month)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .opacity(returnFromMonth == nil ? 1 : 0)
                    .allowsHitTesting(returnFromMonth == nil)

                    if let returnFromMonth {
                        let travel = returnFromMonth < currentMonth ? -proxy.size.width : proxy.size.width

                        ZStack {
                            MonthPage(month: returnFromMonth, onReturnToCurrentMonth: {})
                                .offset(x: returnSlideOffset)

                            MonthPage(month: currentMonth, onReturnToCurrentMonth: {})
                                .offset(x: returnSlideOffset - travel)
                        }
                        .clipped()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") {
                        showingSettings = true
                    }
                    .tint(palette.accent)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Search", systemImage: "magnifyingglass") {
                        model.showingSearch = true
                    }
                    .tint(palette.accent)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var currentMonth: Date {
        AppModel.monthStart(for: Date())
    }

    private func returnToCurrentMonth(from month: Date, pageWidth: CGFloat) {
        guard returnFromMonth == nil,
              !AppModel.calendar.isDate(month, equalTo: currentMonth, toGranularity: .month),
              pageWidth > 0 else {
            return
        }

        let travel = month < currentMonth ? -pageWidth : pageWidth
        returnFromMonth = month
        returnSlideOffset = 0

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(20))
            guard returnFromMonth == month else { return }

            withAnimation(
                .spring(duration: 0.28, bounce: 0.10),
                completionCriteria: .removed
            ) {
                returnSlideOffset = travel
            } completion: {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    model.selectedMonth = currentMonth
                    returnFromMonth = nil
                    returnSlideOffset = 0
                }
            }
        }
    }
}

private struct MonthPage: View {
    let month: Date
    let onReturnToCurrentMonth: () -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 16)
                MonthSummary(month: month, onReturnToCurrentMonth: onReturnToCurrentMonth)
                Spacer(minLength: 22)
                MonthCalendar(month: month)
                    .frame(height: min(378, proxy.size.height * 0.56))
                    .padding(.bottom, 6)
                Spacer(minLength: 38)
            }
        }
    }
}

private struct MonthSummary: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appThemePalette) private var palette
    @Environment(\.appCurrency) private var currency
    @ScaledMetric(relativeTo: .largeTitle) private var amountFontSize = 82.0
    let month: Date
    let onReturnToCurrentMonth: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.nunito(.title3, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(amountText)
                    .font(.nunito(size: amountFontSize, weight: .heavy, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.easeOut(duration: 0.28), value: totalAmount)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Monthly subscription total, \(amountText), for \(month.formatted(.dateTime.month(.wide).year())).")

            nextPaymentBadge
        }
    }

    @ViewBuilder
    private var nextPaymentBadge: some View {
        let label = Group {
            if isCurrentMonth {
                Label(nextPaymentSummary, systemImage: "calendar.badge.clock")
            } else {
                HStack(spacing: 8) {
                    if !isPastMonth {
                        Image(systemName: "chevron.left")
                    }

                    Text("Current Month")

                    if isPastMonth {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
            .font(.nunito(.subheadline, weight: .semibold))
            .foregroundStyle(palette.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .allowsTightening(true)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)

        let content = Group {
            if isCurrentMonth {
                label
            } else {
                Button(action: onReturnToCurrentMonth) {
                    label
                }
                .buttonStyle(MonthReturnButtonStyle())
                .accessibilityLabel("Go to Current Month")
            }
        }

        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(palette.accent.opacity(0.24)), in: .capsule)
        } else {
            content
                .background(palette.selectedSurface, in: .capsule)
        }
    }

    private var isCurrentMonth: Bool {
        AppModel.calendar.isDate(month, equalTo: currentMonth, toGranularity: .month)
    }

    private var isPastMonth: Bool {
        month < currentMonth
    }

    private var currentMonth: Date {
        AppModel.monthStart(for: Date())
    }

    private var amountText: String {
        currency.formatted(totalAmount)
    }

    private var totalAmount: Double {
        model.total(in: month)
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
        return currency.formatted(payment.amount)
    }

    private var nextPaymentSummary: String {
        guard model.nextPayment() != nil else { return nextPaymentTitle }
        return "\(nextPaymentTitle) · \(nextPaymentAmount)"
    }
}

private struct MonthReturnButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
                        .font(.nunito(.caption2, weight: .semibold))
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
    @Environment(\.appThemePalette) private var palette
    let day: CalendarDate

    var body: some View {
        Button {
            model.select(day: dayNumber, in: day.date)
        } label: {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cellFill)
                .overlay(alignment: .center) {
                    subscriptionIndicator
                }
                .overlay(alignment: .bottomTrailing) {
                    if day.isInDisplayedMonth {
                        Text("\(dayNumber)")
                            .font(.nunito(size: 12, weight: .semibold, relativeTo: .caption2))
                            .foregroundStyle(.secondary)
                            .padding(6)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isSelected ? 2.5 : 1)
                }
                .frame(height: 52)
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

    @ViewBuilder
    private var subscriptionIndicator: some View {
        switch daySubscriptions.count {
        case 1:
            if let subscription = daySubscriptions.first {
                ServiceLogo(service: subscription.service, size: 25)
                    .offset(y: -4)
            }

        case 2:
            HStack(spacing: -3) {
                ForEach(daySubscriptions) { subscription in
                    ServiceLogo(service: subscription.service, size: 20)
                }
            }
            .offset(y: -4)

        case 3...4:
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(17), spacing: 0), count: 2),
                spacing: 0
            ) {
                ForEach(daySubscriptions) { subscription in
                    ServiceLogo(service: subscription.service, size: 17)
                }
            }
            .frame(width: 34, height: 34)
            .offset(x: -2, y: -4)

        case 5...:
            Text("\(daySubscriptions.count)")
                .font(.nunito(.caption, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
                }
                .offset(y: -4)

        default:
            EmptyView()
        }
    }

    private var cellFill: Color {
        if let subscription = daySubscriptions.first {
            return subscription.service.brandTint.opacity(colorScheme == .dark ? 0.48 : 0.25)
        }

        if day.isInDisplayedMonth {
            return palette.surface.opacity(colorScheme == .dark ? 0.92 : 0.88)
        }

        return palette.surface.opacity(colorScheme == .dark ? 0.44 : 0.46)
    }

    private var borderColor: Color {
        if isSelected { return palette.accent }
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
    @Environment(\.appCurrency) private var currency

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
                    .appThemedSurfaceRow()
                }

                Section {
                    Button("Add Subscription", systemImage: "plus", action: addSubscription)
                    LabeledContent("Total") {
                        Text(currency.formatted(dayTotal))
                            .font(.nunito(.body, weight: .semibold))
                    }
                }
                .appThemedSurfaceRow()
            }
            .appThemedScreenBackground()
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
    @Environment(\.appCurrency) private var currency
    let subscription: SubscriptionRecord

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: subscription.service, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.nunito(.headline, weight: .semibold))
                Text("\(subscription.schedule.rawValue) · \(currency.formatted(subscription.amount))")
                    .font(.nunito(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.forward")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SubscriptionDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    @Environment(\.appCurrency) private var currency
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
                                .font(.nunito(.title2, weight: .bold))
                            Text("\(subscription.schedule.rawValue) · \(currency.formatted(subscription.amount))")
                                .foregroundStyle(.secondary)
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.nunito(.subheadline, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .appThemedSurfaceRow()

                    Section("Billing") {
                        LabeledContent("Amount", value: currency.formatted(subscription.amount))
                        LabeledContent("Next Payment") {
                            Text(subscription.startDate, format: .dateTime.day().month(.abbreviated).year())
                        }
                        LabeledContent("Notifications", value: subscription.notifications)
                    }
                    .appThemedSurfaceRow()

                    Section("Organization") {
                        LabeledContent("Category", value: subscription.category.rawValue)
                        LabeledContent("List", value: subscription.listName)
                        LabeledContent("Payment Method", value: subscription.paymentMethod)
                    }
                    .appThemedSurfaceRow()
                }
                .scrollContentBackground(.hidden)
                .background {
                    SubscriptionDetailBackdrop(tint: subscription.service.brandTint)
                }
                .tint(palette.accent)
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
    @Environment(\.appThemePalette) private var palette
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                palette.background

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
                    colors: [.clear, palette.background.opacity(0.78)],
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
