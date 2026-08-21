import SwiftUI

struct BankView: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.calendar) private var calendar
    @ScaledMetric(relativeTo: .largeTitle) private var accountSummaryHeight = 210.0
    @State private var selectedAccount: BankAccount? = .total
    @State private var showingTransactionSearch = false
    @State private var presentedAction: BankAction?
    @State private var selectedTransaction: BankTransaction?
    @State private var selectedHistoryPeriod: BankHistoryPeriod = .thirtyDays
    @State private var showsAllTransactions = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackdrop()

                ScrollView {
                    LazyVStack(spacing: 28) {
                        VStack(spacing: 12) {
                            accountSummary
                            quickActions
                        }

                        transactionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .appTopNavigationBar {
                showingTransactionSearch = true
            }
            .sheet(isPresented: $showingTransactionSearch) {
                BankTransactionSearchView(transactions: BankTransaction.activitySamples)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $presentedAction) { action in
                BankActionSheet(action: action)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedTransaction) { transaction in
                BankTransactionDetailSheet(transaction: transaction)
                    .presentationDetents([.fraction(0.72), .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
        }
    }

    private var accountSummary: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(BankAccount.allCases) { account in
                    BankAccountSummaryPage(account: account)
                        .containerRelativeFrame(.horizontal)
                        .id(account)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selectedAccount)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                ForEach(BankAccount.allCases) { account in
                    Circle()
                        .fill(
                            selectedAccount == account
                                ? Color.primary
                                : Color.secondary.opacity(0.55)
                        )
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.bottom, 8)
            .accessibilityHidden(true)
        }
        .frame(height: accountSummaryHeight)
    }

    @ViewBuilder
    private var quickActions: some View {
        let actions = HStack(alignment: .top, spacing: 8) {
            ForEach(BankAction.allCases) { action in
                BankQuickActionButton(action: action) {
                    presentedAction = action
                }
            }
        }

        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                actions
            }
        } else {
            actions
        }
    }

    private var transactionSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("History")
                    .appFont(.title2, weight: .bold)

                Spacer(minLength: 0)

                historyPeriodSelector
            }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 4)

            ForEach(displayedTransactionGroups) { group in
                BankTransactionDaySection(group: group) { transaction in
                    selectedTransaction = transaction
                }
            }

            if !showsAllTransactions && transactionGroups.count > 3 {
                viewAllButton
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
        }
        .appFloatingSurface(radius: 24)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 0.5)
        }
    }

    private var transactionGroups: [BankTransactionDay] {
        let cutoffDate = selectedHistoryPeriod.cutoffDate(from: .now, calendar: calendar)
        let transactions = BankTransaction.activitySamples.filter { $0.date >= cutoffDate }
        return BankTransactionDay.group(transactions)
    }

    private var displayedTransactionGroups: ArraySlice<BankTransactionDay> {
        transactionGroups.prefix(showsAllTransactions ? transactionGroups.count : 3)
    }

    private var historyPeriodSelector: some View {
        Menu {
            Picker("History range", selection: $selectedHistoryPeriod) {
                ForEach(BankHistoryPeriod.allCases) { period in
                    Text(period.title)
                        .tag(period)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedHistoryPeriod.title)
                    .appFont(.subheadline, weight: .semibold)
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onChange(of: selectedHistoryPeriod) {
            showsAllTransactions = false
        }
    }

    @ViewBuilder
    private var viewAllButton: some View {
        let button = Button {
            withAnimation(.smooth) {
                showsAllTransactions = true
            }
        } label: {
            Label("View all", systemImage: "chevron.down")
                .appFont(.subheadline, weight: .bold)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)

        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        } else {
            button
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
}

private struct BankAccountSummaryPage: View {
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .largeTitle) private var balanceFontSize = 68.0
    @ScaledMetric(relativeTo: .title) private var currencyFontSize = 40.0
    @ScaledMetric(relativeTo: .subheadline) private var accountIconSize = 18.0
    let account: BankAccount

    var body: some View {
        VStack(spacing: 0) {
            Text(account.title)
                .appFont(.subheadline, weight: .semibold)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            balanceText
                .monospacedDigit()
                .minimumScaleFactor(0.62)
                .lineLimit(1)
                .environment(\.layoutDirection, .leftToRight)

            HStack(spacing: 6) {
                accountIcon
                Text(verbatim: account.currency.rawValue)
                Text(verbatim: "∙")
                Text(account.name)
            }
            .appFont(.subheadline, weight: .semibold)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var accountIcon: some View {
        if account == .total {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: accountIconSize, weight: .semibold))
                .accessibilityHidden(true)
        } else {
            Image(systemName: "creditcard.fill")
                .font(.system(size: accountIconSize, weight: .semibold))
                .accessibilityHidden(true)
        }
    }

    private var balanceText: Text {
        let amount = Text(verbatim: formattedBalance)
            .font(AppFonts.font(size: balanceFontSize, weight: .heavy, relativeTo: .largeTitle, locale: locale))

        if account.currency == .usd {
            let currency = Text(verbatim: "$")
                .font(AppFonts.font(size: currencyFontSize, weight: .heavy, relativeTo: .title, locale: locale))
            return Text("\(currency)\(amount)")
        } else {
            let currency = Text(verbatim: "\u{00A0}AED")
                .font(AppFonts.font(size: currencyFontSize, weight: .heavy, relativeTo: .title, locale: locale))
            return Text("\(amount)\(currency)")
        }
    }

    private var formattedBalance: String {
        abs(account.balance).formatted(
            FloatingPointFormatStyle<Double>()
                .grouping(.automatic)
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }
}

private struct BankTransactionSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let transactions: [BankTransaction]
    @State private var searchText = ""
    @State private var selectedTransaction: BankTransaction?

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackdrop()

                if filteredTransactions.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filteredTransactions) { transaction in
                        BankTransactionRow(transaction: transaction, showsDate: true) {
                            selectedTransaction = transaction
                        }
                        .listRowBackground(palette.surface.opacity(0.78))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Search transactions")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Text("Search transactions"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                BankTransactionDetailSheet(transaction: transaction)
                    .presentationDetents([.fraction(0.72), .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
        }
    }

    private var filteredTransactions: [BankTransaction] {
        guard !searchText.isEmpty else { return transactions }
        return transactions.filter {
            $0.searchTerms.localizedCaseInsensitiveContains(searchText)
        }
    }
}

private struct BankQuickActionButton: View {
    @Environment(\.appThemePalette) private var palette
    let action: BankAction
    let perform: () -> Void

    var body: some View {
        VStack(spacing: 7) {
            actionButton

            Text(action.title)
                .appFont(.subheadline, weight: .bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 88)
    }

    @ViewBuilder
    private var actionButton: some View {
        let button = Button(action: perform) {
            Image(systemName: action.symbol)
                .appFont(.headline, weight: .bold)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(Text(action.title))

        if #available(iOS 26.0, *) {
            button
                .controlSize(.small)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        } else {
            button
                .buttonStyle(.plain)
                .background(palette.elevatedSurface, in: .circle)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}

private struct BankTransactionRow: View {
    @Environment(\.locale) private var locale
    let transaction: BankTransaction
    var showsDate = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                BankTransactionIcon(transaction: transaction)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(transaction.title)
                            .appFont(.body, weight: .bold)
                            .lineLimit(1)

                        Text(transaction.subtitle)
                            .appFont(.footnote, weight: .semibold)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if showsDate {
                            Text(transaction.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .appFont(.caption2, weight: .medium)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    amountText
                        .foregroundStyle(amountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .environment(\.layoutDirection, .leftToRight)
                        .accessibilityLabel(Text(verbatim: accessibleAmountText))
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Shows transaction details"))
    }

    private var amountText: Text {
        let parts = amountParts
        let regularFont = AppFonts.font(.body, weight: .bold, locale: locale)
        let centsFont = AppFonts.font(.caption, weight: .bold, locale: locale)
        let sign = transaction.amount > 0 ? "+" : transaction.amount < 0 ? "−" : ""
        let wholeAmount = Text(verbatim: "\(sign)\(transaction.currency == .usd ? "$" : "")\(parts.whole)")
            .font(regularFont)
        let cents = Text(verbatim: "\(parts.separator)\(parts.cents)")
            .font(centsFont)
        let currencySuffix = Text(verbatim: transaction.currency == .aed ? "\u{00A0}AED" : "")
            .font(regularFont)

        return Text("\(wholeAmount)\(cents)\(currencySuffix)")
    }

    private var amountColor: Color {
        if transaction.amount > 0 { return .green }
        if transaction.amount < 0 { return Color(uiColor: .secondaryLabel) }
        return .primary
    }

    private var accessibleAmountText: String {
        let parts = amountParts
        let sign = transaction.amount > 0 ? "+" : transaction.amount < 0 ? "−" : ""
        if transaction.currency == .aed {
            return "\(sign)\(parts.whole)\(parts.separator)\(parts.cents) AED"
        }
        return "\(sign)$\(parts.whole)\(parts.separator)\(parts.cents)"
    }

    private var amountParts: (whole: String, separator: String, cents: String) {
        let number = abs(transaction.amount).formatted(
            FloatingPointFormatStyle<Double>()
                .grouping(.automatic)
                .precision(.fractionLength(2))
                .locale(locale)
        )
        let separator = locale.decimalSeparator ?? "."
        guard let separatorRange = number.range(of: separator, options: .backwards) else {
            return (number, separator, "00")
        }
        return (
            String(number[..<separatorRange.lowerBound]),
            separator,
            String(number[separatorRange.upperBound...])
        )
    }
}

private struct BankTransactionIcon: View {
    let transaction: BankTransaction
    var size: CGFloat = 42

    var body: some View {
        if let brand = transaction.brand {
            ServiceLogo(service: brand, size: size, showsShadow: false)
        } else {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .systemGray3))

                Image(systemName: transaction.symbol)
                    .font(.system(size: size * 0.43, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .overlay {
                Circle().stroke(.white.opacity(0.12), lineWidth: 0.5)
            }
            .accessibilityHidden(true)
        }
    }
}

private struct BankTransactionDaySection: View {
    @Environment(\.calendar) private var calendar
    let group: BankTransactionDay
    let onSelect: (BankTransaction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            dayTitle
                .appFont(.headline, weight: .bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 6)

            ForEach(group.transactions) { transaction in
                BankTransactionRow(transaction: transaction) {
                    onSelect(transaction)
                }

                if transaction.id != group.transactions.last?.id {
                    Divider()
                        .padding(.leading, 54)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var dayTitle: some View {
        if calendar.isDateInToday(group.date) {
            Text("Today")
        } else if calendar.isDateInYesterday(group.date) {
            Text("Yesterday")
        } else {
            Text(group.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
        }
    }

}

private struct BankTransactionDetailSheet: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .title2) private var iconSize = 64.0
    @State private var showingAllSubscriptions = false
    let transaction: BankTransaction

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    detailsCard

                    if transaction.brand != nil {
                        viewAllSubscriptionsButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(AppScreenBackdrop(accentColor: backgroundAccentColor))
            .navigationTitle("Transaction details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAllSubscriptions) {
                SearchSubscriptionsView(
                    automaticallyFocusesSearch: false,
                    navigationTitle: "Subscriptions"
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            BankTransactionIcon(transaction: transaction, size: iconSize)
                .padding(.bottom, 4)

            Text(transaction.title)
                .appFont(.title2, weight: .heavy)
                .multilineTextAlignment(.center)

            Text(transaction.subtitle)
                .appFont(.subheadline, weight: .semibold)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            amountText
                .foregroundStyle(transaction.amount > 0 ? .green : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .environment(\.layoutDirection, .leftToRight)
                .padding(.top, 6)
                .accessibilityLabel(Text(verbatim: accessibleAmountText))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            BankTransactionDetailRow("Status", systemImage: "checkmark.circle") {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .appFont(.subheadline, weight: .bold)
                    .foregroundStyle(.green)
            }

            detailDivider

            BankTransactionDetailRow("Date", systemImage: "calendar") {
                Text(transaction.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .appFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            detailDivider

            BankTransactionDetailRow("Time", systemImage: "clock") {
                Text(transaction.date, format: .dateTime.hour().minute())
                    .appFont(.subheadline, weight: .semibold)
            }

            detailDivider

            BankTransactionDetailRow("Account", systemImage: "building.columns") {
                HStack(spacing: 5) {
                    Text(verbatim: transaction.currency.rawValue)
                    Text(verbatim: "∙")
                    Text(accountName)
                }
                .appFont(.subheadline, weight: .semibold)
                .lineLimit(1)
            }

            detailDivider

            BankTransactionDetailRow("Category", systemImage: "tag") {
                Text(transaction.subtitle)
                    .appFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
            }

            detailDivider

            BankTransactionDetailRow("Transaction ID", systemImage: "number") {
                Text(verbatim: transaction.id.uppercased())
                    .appFont(.caption, weight: .bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .background(palette.surface.opacity(0.62), in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 0.5)
        }
    }

    private var detailDivider: some View {
        Divider()
            .padding(.leading, 48)
    }

    private var accountName: LocalizedStringResource {
        transaction.currency == .usd ? "Default" : "UAE account"
    }

    @ViewBuilder
    private var viewAllSubscriptionsButton: some View {
        let button = Button {
            showingAllSubscriptions = true
        } label: {
            Label("View all subscriptions", systemImage: "rectangle.stack")
                .frame(maxWidth: .infinity)
        }
        .appFont(.body, weight: .bold)
        .controlSize(.large)

        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        } else {
            button
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }

    private var backgroundAccentColor: Color? {
        guard let brand = transaction.brand else { return nil }

        switch brand.id {
        case "netflix", "youtube-premium":
            return brand.brandTint
        default:
            return nil
        }
    }

    private var amountText: Text {
        let parts = amountParts
        let numberFont = AppFonts.font(.largeTitle, weight: .heavy, locale: locale)
        let sign = Text(verbatim: transaction.amount > 0 ? "+" : transaction.amount < 0 ? "−" : "")
            .font(numberFont)
        let whole = Text(verbatim: parts.whole)
            .font(numberFont)
        let cents = Text(verbatim: "\(parts.separator)\(parts.cents)")
            .font(numberFont)

        if transaction.currency == .usd {
            let currency = Text(verbatim: "$")
                .font(numberFont)
            return Text("\(sign)\(currency)\(whole)\(cents)")
        } else {
            let currency = Text(verbatim: "\u{00A0}AED")
                .font(numberFont)
            return Text("\(sign)\(whole)\(cents)\(currency)")
        }
    }

    private var accessibleAmountText: String {
        let parts = amountParts
        let sign = transaction.amount > 0 ? "+" : transaction.amount < 0 ? "−" : ""
        if transaction.currency == .aed {
            return "\(sign)\(parts.whole)\(parts.separator)\(parts.cents) AED"
        }
        return "\(sign)$\(parts.whole)\(parts.separator)\(parts.cents)"
    }

    private var amountParts: (whole: String, separator: String, cents: String) {
        let number = abs(transaction.amount).formatted(
            FloatingPointFormatStyle<Double>()
                .grouping(.automatic)
                .precision(.fractionLength(2))
                .locale(locale)
        )
        let separator = locale.decimalSeparator ?? "."
        guard let separatorRange = number.range(of: separator, options: .backwards) else {
            return (number, separator, "00")
        }
        return (
            String(number[..<separatorRange.lowerBound]),
            separator,
            String(number[separatorRange.upperBound...])
        )
    }
}

private struct BankTransactionDetailRow<Value: View>: View {
    let title: LocalizedStringResource
    let systemImage: String
    let value: Value

    init(
        _ title: LocalizedStringResource,
        systemImage: String,
        @ViewBuilder value: () -> Value
    ) {
        self.title = title
        self.systemImage = systemImage
        self.value = value()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 22)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .appFont(.subheadline, weight: .semibold)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            value
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .accessibilityElement(children: .combine)
    }
}

private struct BankActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let action: BankAction

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: action.symbol)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 74, height: 74)
                    .background(palette.selectedSurface, in: .circle)

                Text(action.title)
                    .appFont(.title2, weight: .heavy)
                Text("This banking action is ready to connect.")
                    .appFont(.body, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppScreenBackdrop())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private enum BankAction: String, CaseIterable, Identifiable {
    case addMoney
    case transfer
    case payViaQR

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .addMoney: "Add money"
        case .transfer: "Transfer"
        case .payViaQR: "Pay via QR"
        }
    }

    var symbol: String {
        switch self {
        case .addMoney: "plus"
        case .transfer: "arrow.left.arrow.right"
        case .payViaQR: "qrcode"
        }
    }
}

private enum BankHistoryPeriod: String, CaseIterable, Identifiable {
    case thirtyDays
    case threeMonths
    case sixMonths
    case oneYear

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .thirtyDays: "30 days"
        case .threeMonths: "3 months"
        case .sixMonths: "6 months"
        case .oneYear: "1 year"
        }
    }

    func cutoffDate(from date: Date, calendar: Calendar) -> Date {
        let component: Calendar.Component
        let value: Int

        switch self {
        case .thirtyDays:
            component = .day
            value = -30
        case .threeMonths:
            component = .month
            value = -3
        case .sixMonths:
            component = .month
            value = -6
        case .oneYear:
            component = .year
            value = -1
        }

        return calendar.date(byAdding: component, value: value, to: date) ?? .distantPast
    }
}

private enum BankAccount: String, CaseIterable, Identifiable {
    case total
    case visa
    case mastercard

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .total: "Available balance"
        case .visa: "Visa ••4232"
        case .mastercard: "MasterCard ••4232"
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .total: "Total"
        case .visa, .mastercard: "Card balance"
        }
    }

    var currency: AppCurrency {
        .usd
    }

    var balance: Double {
        switch self {
        case .total: 12_480.32
        case .visa: 7_920.32
        case .mastercard: 4_560
        }
    }

}

private struct BankTransaction: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let amount: Double
    let currency: AppCurrency
    let date: Date
    let symbol: String
    let color: Color
    let searchTerms: String
    let brand: ServiceBrand?

    static let activitySamples = usdSamples

    static let usdSamples: [BankTransaction] = [
        sample("usd-salary", "Salary", "Northstar Studio", 8_250, .usd, daysAgo: 0, hour: 9, symbol: "briefcase.fill", color: .green, searchTerms: "salary northstar studio راتب نورث ستار"),
        sample("usd-exchange", "Exchanged to AED", "USD → AED account", -1_250, .usd, daysAgo: 0, hour: 11, symbol: "arrow.triangle.2.circlepath", color: .blue, searchTerms: "exchange usd aed تحويل دولار درهم"),
        sample("usd-coffee", "Common Grounds", "Coffee shop", -6.80, .usd, daysAgo: 0, hour: 12, symbol: "cup.and.saucer.fill", color: .brown, searchTerms: "common grounds coffee cafe قهوة مقهى"),
        sample("usd-netflix", "Netflix", "Entertainment", -15.49, .usd, daysAgo: 1, hour: 20, symbol: "play.rectangle.fill", color: .red, searchTerms: "netflix entertainment نتفلكس ترفيه", brandName: "Netflix"),
        sample("usd-youtube-premium", "YouTube Premium", "Subscription", -13.99, .usd, daysAgo: 1, hour: 21, symbol: "play.fill", color: .red, searchTerms: "youtube premium subscription يوتيوب بريميوم اشتراك", brandName: "YouTube Premium"),
        sample("usd-groceries", "Whole Foods Market", "Groceries", -84.32, .usd, daysAgo: 1, hour: 18, symbol: "basket.fill", color: .green, searchTerms: "whole foods market groceries بقالة سوق"),
        sample("usd-uber", "Uber", "Transport", -23.60, .usd, daysAgo: 1, hour: 8, symbol: "car.fill", color: .black, searchTerms: "uber transport ride أوبر مواصلات"),
        sample("usd-cashback", "Cashback", "Rewards", 12.40, .usd, daysAgo: 1, hour: 10, symbol: "sparkles", color: .mint, searchTerms: "cashback rewards استرداد مكافآت"),
        sample("usd-layla", "Layla Hassan", "Personal transfer", 350, .usd, daysAgo: 2, hour: 14, symbol: "person.fill", color: .purple, searchTerms: "layla hassan transfer ليلى حسن تحويل"),
        sample("usd-hbo-max", "HBO Max", "Entertainment", -9.99, .usd, daysAgo: 2, hour: 20, symbol: "tv.fill", color: .black, searchTerms: "hbo max entertainment اتش بي او ماكس ترفيه", brandName: "HBO Max"),
        sample("usd-cursor", "Cursor", "Productivity", -20, .usd, daysAgo: 2, hour: 12, symbol: "cursorarrow", color: .black, searchTerms: "cursor productivity subscription كيرسر إنتاجية اشتراك", brandName: "Cursor"),
        sample("usd-amazon", "Amazon", "Shopping", -127.45, .usd, daysAgo: 2, hour: 16, symbol: "shippingbox.fill", color: .orange, searchTerms: "amazon shopping أمازون تسوق"),
        sample("usd-pharmacy", "CVS Pharmacy", "Health", -32.18, .usd, daysAgo: 2, hour: 19, symbol: "cross.case.fill", color: .red, searchTerms: "cvs pharmacy health صيدلية صحة"),
        sample("usd-apple-music", "Apple Music", "Subscription", -10.99, .usd, daysAgo: 3, hour: 8, symbol: "music.note", color: .pink, searchTerms: "apple music subscription آبل موسيقى اشتراك"),
        sample("usd-emirates", "Emirates", "Travel", -624.80, .usd, daysAgo: 4, hour: 10, symbol: "airplane", color: .red, searchTerms: "emirates travel flight طيران الإمارات سفر"),
        sample("usd-adobe", "Adobe", "Subscription", -22.99, .usd, daysAgo: 4, hour: 12, symbol: "scribble.variable", color: .purple, searchTerms: "adobe subscription أدوبي اشتراك"),
        sample("usd-electricity", "Electricity bill", "Utilities", -91.24, .usd, daysAgo: 4, hour: 17, symbol: "bolt.fill", color: .yellow, searchTerms: "electricity bill utilities كهرباء فاتورة"),
        sample("usd-gym", "Gym membership", "Health & Fitness", -65, .usd, daysAgo: 6, hour: 7, symbol: "dumbbell.fill", color: .indigo, searchTerms: "gym membership fitness نادي لياقة"),
        sample("usd-restaurant", "The Lighthouse", "Food & Drink", -48.30, .usd, daysAgo: 6, hour: 21, symbol: "fork.knife", color: .teal, searchTerms: "lighthouse restaurant food مطعم طعام")
    ]

    static let aedSamples: [BankTransaction] = [
        sample("aed-exchange", "Exchanged from USD", "USD → AED account", 4_590.63, .aed, daysAgo: 0, hour: 11, symbol: "arrow.triangle.2.circlepath", color: .blue, searchTerms: "exchange usd aed تحويل دولار درهم"),
        sample("aed-carrefour", "Carrefour Market", "Groceries", -245.75, .aed, daysAgo: 0, hour: 18, symbol: "cart.fill", color: .blue, searchTerms: "carrefour groceries market كارفور بقالة سوق"),
        sample("aed-careem", "Careem ride", "Transport", -41.20, .aed, daysAgo: 0, hour: 22, symbol: "car.fill", color: .green, searchTerms: "careem ride transport كريم رحلة نقل"),
        sample("aed-bonus", "Salary bonus", "Northstar Studio", 2_200, .aed, daysAgo: 0, hour: 9, symbol: "briefcase.fill", color: .mint, searchTerms: "salary bonus northstar مكافأة راتب"),
        sample("aed-noon", "Noon", "Shopping", -319, .aed, daysAgo: 1, hour: 14, symbol: "bag.fill", color: .yellow, searchTerms: "noon shopping نون تسوق"),
        sample("aed-dewa", "DEWA", "Utilities", -488.15, .aed, daysAgo: 1, hour: 10, symbol: "bolt.fill", color: .orange, searchTerms: "dewa utilities water electricity ديوا كهرباء مياه"),
        sample("aed-spinneys", "Spinneys", "Groceries", -182.40, .aed, daysAgo: 1, hour: 18, symbol: "basket.fill", color: .green, searchTerms: "spinneys groceries سبينس بقالة"),
        sample("aed-talabat", "Talabat", "Food delivery", -72.50, .aed, daysAgo: 1, hour: 21, symbol: "takeoutbag.and.cup.and.straw.fill", color: .orange, searchTerms: "talabat food delivery طلبات توصيل طعام"),
        sample("aed-transfer", "Transfer to Layla", "Personal transfer", -750, .aed, daysAgo: 2, hour: 13, symbol: "person.fill", color: .purple, searchTerms: "transfer layla personal تحويل ليلى شخصي"),
        sample("aed-taxi", "Dubai Taxi", "Transport", -56, .aed, daysAgo: 2, hour: 17, symbol: "car.side.fill", color: .red, searchTerms: "dubai taxi transport تاكسي دبي مواصلات"),
        sample("aed-etisalat", "Etisalat", "Mobile & Internet", -399, .aed, daysAgo: 2, hour: 9, symbol: "antenna.radiowaves.left.and.right", color: .green, searchTerms: "etisalat mobile internet اتصالات هاتف إنترنت"),
        sample("aed-bank-transfer", "Emirates NBD", "Bank transfer", 1_250, .aed, daysAgo: 3, hour: 11, symbol: "building.columns.fill", color: .blue, searchTerms: "emirates nbd bank transfer بنك الإمارات تحويل"),
        sample("aed-cinema", "Cinema City", "Entertainment", -120, .aed, daysAgo: 3, hour: 20, symbol: "film.fill", color: .purple, searchTerms: "cinema city entertainment سينما ترفيه"),
        sample("aed-pharmacy", "Life Pharmacy", "Health", -86.50, .aed, daysAgo: 3, hour: 15, symbol: "cross.case.fill", color: .red, searchTerms: "life pharmacy health لايف صيدلية صحة"),
        sample("aed-rent", "Rent payment", "Housing", -6_200, .aed, daysAgo: 5, hour: 8, symbol: "house.fill", color: .indigo, searchTerms: "rent payment housing إيجار سكن"),
        sample("aed-cashback", "Cashback", "Rewards", 45, .aed, daysAgo: 5, hour: 12, symbol: "sparkles", color: .mint, searchTerms: "cashback rewards استرداد مكافآت")
    ]

    private static func sample(
        _ id: String,
        _ title: LocalizedStringResource,
        _ subtitle: LocalizedStringResource,
        _ amount: Double,
        _ currency: AppCurrency,
        daysAgo: Int,
        hour: Int,
        symbol: String,
        color: Color,
        searchTerms: String,
        brandName: String? = nil
    ) -> BankTransaction {
        BankTransaction(
            id: id,
            title: title,
            subtitle: subtitle,
            amount: amount,
            currency: currency,
            date: sampleDate(daysAgo: daysAgo, hour: hour, minute: 0),
            symbol: symbol,
            color: color,
            searchTerms: searchTerms,
            brand: brandName.map { ServiceCatalog.service(named: $0) }
        )
    }

    private static func sampleDate(daysAgo: Int, hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        let today = Calendar.current.date(from: components) ?? .now
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: today) ?? today
    }
}

private struct BankTransactionDay: Identifiable {
    let date: Date
    let transactions: [BankTransaction]

    var id: Date { date }

    static func group(_ transactions: [BankTransaction]) -> [BankTransactionDay] {
        Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        .map { date, transactions in
            BankTransactionDay(
                date: date,
                transactions: transactions.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.date > $1.date }
    }
}

#Preview("Bank — English") {
    BankView()
        .environment(\.appThemePalette, AppThemePalette(accent: .blue))
        .environment(\.appAccentColor, .blue)
        .environment(\.locale, Locale(identifier: "en"))
        .preferredColorScheme(.dark)
}

#Preview("Bank — Arabic") {
    BankView()
        .environment(\.appThemePalette, AppThemePalette(accent: .teal))
        .environment(\.appAccentColor, .teal)
        .environment(\.locale, Locale(identifier: "ar"))
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
}
