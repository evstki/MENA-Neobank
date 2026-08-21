import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appThemePalette) private var palette
    @State private var showingSettings = false
    @State private var returnFromMonth: Date?
    @State private var returnSlideOffset: CGFloat = 0
    @State private var adjacentMonthTransition: AdjacentMonthTransition?
    @State private var adjacentMonthSlideOffset: CGFloat = 0

    private static let availableMonths: [Date] = {
        let anchor = AppModel.makeDate(year: 2026, month: 1, day: 1)
        return (-60...120).compactMap { AppModel.calendar.date(byAdding: .month, value: $0, to: anchor) }
    }()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ZStack {
                AppScreenBackdrop()

                GeometryReader { proxy in
                    TabView(selection: $model.selectedMonth) {
                        ForEach(Self.availableMonths, id: \.self) { month in
                            MonthPage(month: month) {
                                returnToCurrentMonth(from: month, pageWidth: proxy.size.width)
                            } onSelectAdjacentMonth: { adjacentMonth in
                                navigateToMonth(
                                    adjacentMonth,
                                    from: month,
                                    pageWidth: proxy.size.width
                                )
                            }
                            .tag(month)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .opacity(returnFromMonth == nil && adjacentMonthTransition == nil ? 1 : 0)
                    .allowsHitTesting(returnFromMonth == nil && adjacentMonthTransition == nil)

                    if let returnFromMonth {
                        let travel = returnFromMonth < currentMonth ? -proxy.size.width : proxy.size.width

                        ZStack {
                            MonthPage(
                                month: returnFromMonth,
                                onReturnToCurrentMonth: {},
                                onSelectAdjacentMonth: { _ in }
                            )
                                .offset(x: returnSlideOffset)

                            MonthPage(
                                month: currentMonth,
                                onReturnToCurrentMonth: {},
                                onSelectAdjacentMonth: { _ in }
                            )
                                .offset(x: returnSlideOffset - travel)
                        }
                        .clipped()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    } else if let adjacentMonthTransition {
                        let travel = adjacentMonthTransition.to > adjacentMonthTransition.from
                            ? proxy.size.width
                            : -proxy.size.width

                        ZStack {
                            MonthPage(
                                month: adjacentMonthTransition.from,
                                onReturnToCurrentMonth: {},
                                onSelectAdjacentMonth: { _ in }
                            )
                            .offset(x: adjacentMonthSlideOffset)

                            MonthPage(
                                month: adjacentMonthTransition.to,
                                onReturnToCurrentMonth: {},
                                onSelectAdjacentMonth: { _ in }
                            )
                            .offset(x: adjacentMonthSlideOffset + travel)
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
                    Button {
                        showingSettings = true
                    } label: {
                        ProfileAvatar()
                    }
                    .accessibilityLabel("Profile")
                    .buttonBorderShape(.circle)
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

    private func navigateToMonth(_ month: Date, from displayedMonth: Date, pageWidth: CGFloat) {
        let destination = AppModel.monthStart(for: month)
        guard returnFromMonth == nil,
              adjacentMonthTransition == nil,
              !AppModel.calendar.isDate(destination, equalTo: displayedMonth, toGranularity: .month),
              pageWidth > 0 else {
            return
        }

        let transition = AdjacentMonthTransition(from: displayedMonth, to: destination)
        let travel = destination > displayedMonth ? -pageWidth : pageWidth
        adjacentMonthTransition = transition
        adjacentMonthSlideOffset = 0

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(20))
            guard adjacentMonthTransition == transition else { return }

            withAnimation(.spring(duration: 0.28, bounce: 0.10), completionCriteria: .removed) {
                adjacentMonthSlideOffset = travel
            } completion: {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    model.selectedMonth = destination
                    adjacentMonthTransition = nil
                    adjacentMonthSlideOffset = 0
                }
            }
        }
    }
}

private struct AdjacentMonthTransition: Equatable {
    let from: Date
    let to: Date
}

private struct MonthPage: View {
    let month: Date
    let onReturnToCurrentMonth: () -> Void
    let onSelectAdjacentMonth: (Date) -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 16)
                MonthSummary(month: month, onReturnToCurrentMonth: onReturnToCurrentMonth)
                    .offset(y: -20)
                Spacer(minLength: 22)
                MonthCalendar(month: month, onSelectAdjacentMonth: onSelectAdjacentMonth)
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
    @Environment(\.appHidesCents) private var hidesCents
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .largeTitle) private var amountFontSize = 82.0
    let month: Date
    let onReturnToCurrentMonth: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 4) {
                Text(month, format: .dateTime.month(.wide).year())
                    .appFont(.title3, weight: .semibold)
                    .foregroundStyle(.secondary)

                Text(amountText)
                    .appFont(size: amountFontSize, weight: .heavy, relativeTo: .largeTitle)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.easeOut(duration: 0.28), value: totalAmount)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppLocalization.string(
                "home.monthlyTotal.accessibility",
                locale: locale,
                arguments: amountText,
                month.formatted(.dateTime.month(.wide).year().locale(locale))
            ))

            nextPaymentBadge
        }
    }

    @ViewBuilder
    private var nextPaymentBadge: some View {
        let label = Group {
            if isCurrentMonth {
                Label {
                    Text(verbatim: nextPaymentSummary)
                } icon: {
                    Image(systemName: "calendar.badge.clock")
                }
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
            .appFont(.subheadline, weight: .semibold)
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
        currency.formatted(totalAmount, hidesCents: hidesCents)
    }

    private var totalAmount: Double {
        model.total(in: month, convertedTo: currency)
    }

    private var nextPaymentTitle: String {
        guard let payment = model.nextPayment(convertedTo: currency) else {
            return AppLocalization.string("No upcoming payments", locale: locale)
        }
        let today = AppModel.calendar.startOfDay(for: Date())
        let paymentDay = AppModel.calendar.startOfDay(for: payment.date)
        let days = AppModel.calendar.dateComponents([.day], from: today, to: paymentDay).day ?? 0
        switch days {
        case 0: return AppLocalization.string("Next payment today", locale: locale)
        case 1: return AppLocalization.string("Next payment tomorrow", locale: locale)
        default: return AppLocalization.nextPayment(days: days, locale: locale)
        }
    }

    private var nextPaymentAmount: String {
        guard let payment = model.nextPayment(convertedTo: currency) else {
            return AppLocalization.string("Add a subscription to see it here", locale: locale)
        }
        return currency.formatted(payment.amount, hidesCents: hidesCents)
    }

    private var nextPaymentSummary: String {
        guard model.nextPayment(convertedTo: currency) != nil else { return nextPaymentTitle }
        return AppLocalization.string(
            "%@ · %@",
            locale: locale,
            arguments: nextPaymentTitle,
            nextPaymentAmount
        )
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
    @Environment(\.locale) private var locale
    let month: Date
    let onSelectAdjacentMonth: (Date) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    var body: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdayNames.enumerated(), id: \.offset) { _, name in
                    Text(name)
                        .appFont(.caption2, weight: .semibold)
                        .foregroundStyle(.tertiary)
                }
            }

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(days) { day in
                    CalendarDayCell(day: day, onSelectAdjacentMonth: onSelectAdjacentMonth)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var weekdayNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        let weekdayNames = formatter.veryShortWeekdaySymbols ?? []
        guard weekdayNames.count == 7 else { return weekdayNames }
        let startIndex = firstWeekday - 1
        return Array(weekdayNames[startIndex...] + weekdayNames[..<startIndex])
    }

    private var days: [CalendarDate] {
        let calendar = AppModel.calendar
        let weekday = calendar.component(.weekday, from: month)
        let leadingDays = (weekday - firstWeekday + 7) % 7
        guard let firstVisibleDate = calendar.date(byAdding: .day, value: -leadingDays, to: month) else {
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

    private var firstWeekday: Int {
        locale.language.languageCode?.identifier == "ru" ? 2 : 1
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
    @Environment(\.locale) private var locale
    let day: CalendarDate
    let onSelectAdjacentMonth: (Date) -> Void

    var body: some View {
        Button {
            guard day.isInDisplayedMonth else {
                onSelectAdjacentMonth(day.date)
                return
            }

            model.select(date: day.date)

            Task { @MainActor in
                await Task.yield()
                model.presentSelectedDate()
            }
        } label: {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cellFill)
                .overlay(alignment: .center) {
                    subscriptionIndicator
                }
                .overlay(alignment: .bottomTrailing) {
                    if day.isInDisplayedMonth {
                        Text("\(dayNumber)")
                            .appFont(size: 11, weight: .semibold, relativeTo: .caption2)
                            .foregroundStyle(.secondary)
                            .padding(5)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isToday ? palette.accent : .clear,
                            lineWidth: 2.5
                        )
                }
                .frame(height: 58)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isToday ? .isSelected : [])
    }

    private var dayNumber: Int {
        AppModel.calendar.component(.day, from: day.date)
    }

    private var daySubscriptions: [SubscriptionRecord] {
        model.subscriptions(on: day.date)
    }

    private var isToday: Bool {
        AppModel.calendar.isDateInToday(day.date)
    }

    @ViewBuilder
    private var subscriptionIndicator: some View {
        if day.isInDisplayedMonth {
            switch daySubscriptions.count {
            case 1:
                if let subscription = daySubscriptions.first {
                    ServiceLogo(service: subscription.service, size: 27)
                }

            case 2:
                HStack(spacing: -4) {
                    ForEach(daySubscriptions) { subscription in
                        ServiceLogo(service: subscription.service, size: 20)
                    }
                }

            case 3...4:
                ZStack {
                    ForEach(Array(daySubscriptions.enumerated()), id: \.element.id) { index, subscription in
                        ServiceLogo(service: subscription.service, size: 18)
                            .offset(
                                x: index.isMultiple(of: 2) ? -7 : 7,
                                y: index < 2 ? -7 : 7
                            )
                            .zIndex(Double(index))
                    }
                }
                .frame(width: 32, height: 32)

            case 5...:
                Text("\(daySubscriptions.count)")
                    .appFont(.caption, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
                    }
            default:
                EmptyView()
            }
        }
    }

    private var cellFill: Color {
        guard day.isInDisplayedMonth else {
            return palette.surface.opacity(colorScheme == .dark ? 0.44 : 0.46)
        }

        if let subscription = daySubscriptions.first {
            return subscription.service.brandTint.opacity(colorScheme == .dark ? 0.48 : 0.25)
        }

        return palette.surface.opacity(colorScheme == .dark ? 0.92 : 0.88)
    }

    private var accessibilityText: String {
        let count = daySubscriptions.count
        let dateText = day.date.formatted(.dateTime.day().month(.wide).year().locale(locale))
        let countText = count == 0
            ? AppLocalization.string("calendar.noSubscriptions", locale: locale)
            : AppLocalization.subscriptionCount(count, locale: locale)
        return AppLocalization.string(
            "calendar.day.accessibility",
            locale: locale,
            arguments: dateText,
            countText
        )
    }
}

struct DaySubscriptionsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents

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
                        Text(currency.formatted(dayTotal, hidesCents: hidesCents))
                            .appFont(.body, weight: .semibold)
                    }
                }
                .appThemedSurfaceRow()
            }
            .appThemedScreenBackground()
            .navigationTitle(Text(
                model.selectedDate,
                format: .dateTime.day().month(.wide).year()
            ))
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
        daySubscriptions.reduce(0) { $0 + $1.amount(convertedTo: currency) }
    }

    private func open(_ subscription: SubscriptionRecord) {
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            model.editingSubscription = subscription
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
    @Environment(\.appHidesCents) private var hidesCents
    @Environment(\.locale) private var locale
    let subscription: SubscriptionRecord

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: subscription.service, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .appFont(.headline, weight: .semibold)
                Text(verbatim: "\(subscription.schedule.localizedTitle(locale: locale)) · \(subscription.currency.formatted(subscription.amount, hidesCents: hidesCents))")
                    .appFont(.subheadline)
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

#Preview {
    HomeView()
        .environment(AppModel())
}
