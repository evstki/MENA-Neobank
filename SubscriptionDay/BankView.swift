import SwiftUI
import Charts

struct BankView: View {
    @Environment(\.appThemePalette) private var palette
    @ScaledMetric(relativeTo: .largeTitle) private var accountSummaryHeight = 180.0
    @State private var selectedAccount: BankAccount? = .total
    @State private var displayCurrency: AppCurrency = .aed
    @State private var showingTransactionSearch = false
    @State private var showingTransferRecipientPicker = false
    @State private var showingTransfer = false
    @State private var selectedTransferDestination: TransferDestination?
    @State private var presentedAction: BankAction?
    @State private var selectedTransaction: BankTransaction?
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

                        VStack(spacing: AppSurfaceMetrics.blockSpacing) {
                            overviewWidgets
                            transactionSection
                        }
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
            .appTabBarHidden(showingTransfer)
            .navigationDestination(isPresented: $showingTransfer) {
                TransferView(selectedDestination: $selectedTransferDestination)
            }
            .sheet(
                isPresented: $showingTransferRecipientPicker,
                onDismiss: continueTransferIfRecipientSelected
            ) {
                TransferRecipientPicker(selection: $selectedTransferDestination)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
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
                    BankAccountSummaryPage(
                        account: account,
                        selection: $selectedAccount,
                        displayCurrency: $displayCurrency
                    )
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
        .frame(height: accountSummaryHeight)
    }

    @ViewBuilder
    private var quickActions: some View {
        let actions = HStack(alignment: .top, spacing: 8) {
            ForEach(BankAction.allCases) { action in
                BankQuickActionButton(action: action) {
                    perform(action)
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

    private func perform(_ action: BankAction) {
        if action == .transfer {
            selectedTransferDestination = nil
            showingTransferRecipientPicker = true
        } else {
            presentedAction = action
        }
    }

    private func continueTransferIfRecipientSelected() {
        guard selectedTransferDestination != nil else { return }
        showingTransfer = true
    }

    private var overviewWidgets: some View {
        BankOverviewWidgets(
            spentAmountAED: currentMonthAEDSpend,
            currency: displayCurrency
        )
    }

    private var currentMonthAEDSpend: Double {
        BankTransaction.activitySamples.reduce(into: 0) { total, transaction in
            guard transaction.currency == .aed,
                  transaction.amount < 0,
                  Calendar.current.isDate(transaction.date, equalTo: .now, toGranularity: .month)
            else { return }

            total += abs(transaction.amount)
        }
    }

    private var transactionSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("History")
                    .appFont(.title2, weight: .bold)

                Spacer(minLength: 0)

                historyViewAllButton
            }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 4)

            ForEach(displayedTransactionGroups) { group in
                BankTransactionDaySection(group: group) { transaction in
                    selectedTransaction = transaction
                }
            }

        }
        .appFloatingSurface(radius: AppSurfaceMetrics.cornerRadius)
        .overlay {
            RoundedRectangle(cornerRadius: AppSurfaceMetrics.cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 0.5)
        }
    }

    private var transactionGroups: [BankTransactionDay] {
        BankTransactionDay.group(BankTransaction.activitySamples)
    }

    private var displayedTransactionGroups: ArraySlice<BankTransactionDay> {
        transactionGroups.prefix(showsAllTransactions ? transactionGroups.count : 3)
    }

    private var historyViewAllButton: some View {
        Button {
            withAnimation(.smooth) {
                showsAllTransactions = true
            }
        } label: {
            HStack(spacing: 6) {
                Text("View All")
                    .appFont(.subheadline, weight: .semibold)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct BankOverviewWidgets: View {
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .body) private var widgetHeight = 136.0
    private let spacing = AppSurfaceMetrics.blockSpacing
    private let transactionsWidthRatio = 0.50
    let spentAmountAED: Double
    let currency: AppCurrency

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - spacing

            HStack(spacing: spacing) {
                transactionsWidget
                    .frame(width: availableWidth * transactionsWidthRatio)

                VStack(spacing: spacing) {
                    savingsWidget
                    rewardsWidget
                }
                .frame(width: availableWidth * (1 - transactionsWidthRatio))
            }
        }
        .frame(height: widgetHeight)
        .accessibilityElement(children: .contain)
    }

    private var transactionsWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transactions")
                .appFont(.headline, weight: .bold)

            Text(spendingSummary)
                .appFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 4)

            spendingBar
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .bankWidgetSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transactions")
        .accessibilityValue(spendingSummary)
    }

    private var savingsWidget: some View {
        HStack(spacing: 10) {
            savingsPie

            VStack(alignment: .leading, spacing: 2) {
                savingsAmountText
                    .foregroundStyle(.white)
                Text(earnedSummary)
                    .appFont(.footnote, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .minimumScaleFactor(0.78)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .bankWidgetSurface()
        .accessibilityElement(children: .combine)
    }

    private var savingsAmountText: Text {
        let amount = Text(verbatim: formattedSavingsAmount)
            .font(AppFonts.font(.subheadline, weight: .semibold, locale: locale))

        if currency == .usd {
            let currency = Text(verbatim: "$")
                .font(AppFonts.font(.subheadline, weight: .semibold, locale: locale))
            return Text("\(currency)\(amount)")
        }

        let currency = Text(verbatim: " \(currency.rawValue)")
            .font(AppFonts.font(.footnote, weight: .semibold, locale: locale))

        return Text("\(amount)\(currency)")
    }

    private var rewardsWidget: some View {
        HStack(spacing: 10) {
            rewardsMark

            VStack(alignment: .leading, spacing: 2) {
                Text("4 rewards")
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.primary)
                Text("for you this week")
                    .appFont(.footnote, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .minimumScaleFactor(0.78)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .bankWidgetSurface()
        .accessibilityElement(children: .combine)
    }

    private var spendingBar: some View {
        GeometryReader { proxy in
            let pillSpacing = 3.0
            let contentWidth = max(0, proxy.size.width - (pillSpacing * 4))

            HStack(spacing: pillSpacing) {
                Self.widgetPalette[0]
                    .frame(width: contentWidth * 0.42)
                    .clipShape(.capsule)
                Self.widgetPalette[1]
                    .frame(width: contentWidth * 0.20)
                    .clipShape(.capsule)
                Self.widgetPalette[2]
                    .frame(width: contentWidth * 0.14)
                    .clipShape(.capsule)
                Self.widgetPalette[3]
                    .frame(width: contentWidth * 0.13)
                    .clipShape(.capsule)
                Self.widgetPalette[4]
                    .frame(width: contentWidth * 0.11)
                    .clipShape(.capsule)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var savingsPie: some View {
        Chart(Self.savingsBreakdown) { slice in
            SectorMark(
                angle: .value("Savings earned", slice.value),
                innerRadius: .ratio(0.56),
                angularInset: 1
            )
            .cornerRadius(2)
            .foregroundStyle(by: .value("Source", slice.name))
        }
        .chartForegroundStyleScale(
            domain: Self.savingsBreakdown.map(\.name),
            range: Self.savingsBreakdown.map(\.color)
        )
        .chartLegend(.hidden)
        .frame(width: 44, height: 44)
        .scaleEffect(0.82)
        .accessibilityHidden(true)
    }

    private var rewardsMark: some View {
        ZStack {
            BankRewardBubble(
                systemImage: "gift.fill",
                color: Self.widgetPalette[1],
                size: 26
            )
                .offset(x: -9, y: -9)
            BankRewardBubble(
                systemImage: "star.fill",
                color: Self.widgetPalette[3],
                size: 26
            )
                .offset(x: 9, y: -9)
            BankRewardBubble(
                systemImage: "sparkles",
                color: Self.widgetPalette[4],
                size: 26
            )
                .offset(x: -9, y: 9)
            BankRewardBubble(
                systemImage: "crown.fill",
                color: Self.widgetPalette[2],
                size: 26
            )
                .offset(x: 9, y: 9)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(0.82)
        .accessibilityHidden(true)
    }

    private static let widgetPalette = [
        Color(hex: "#DCB67E"),
        Color(hex: "#AA78D3"),
        Color(hex: "#8A95FF"),
        Color(hex: "#58EDD1"),
        Color(hex: "#A0B3B6")
    ]

    private static let savingsBreakdown = [
        BankSavingsSlice(name: "Interest", value: 46, color: widgetPalette[0]),
        BankSavingsSlice(name: "Round-ups", value: 31, color: widgetPalette[1]),
        BankSavingsSlice(name: "Rewards", value: 23, color: widgetPalette[2])
    ]

    private var formattedSpend: String {
        displayedSpend.formatted(
            FloatingPointFormatStyle<Double>()
                .grouping(.automatic)
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }

    private var formattedWidgetSpend: String {
        currency == .usd
            ? "$\(formattedSpend)"
            : "\(formattedSpend) \(currency.rawValue)"
    }

    private var spendingSummary: String {
        AppLocalization.string(
            "bank.widget.spentIn",
            locale: locale,
            arguments: formattedWidgetSpend,
            monthName
        )
    }

    private var earnedSummary: String {
        AppLocalization.string(
            "bank.widget.earnedIn",
            locale: locale,
            arguments: monthName
        )
    }

    private var formattedSavingsAmount: String {
        displayedSavingsAmount.formatted(
            FloatingPointFormatStyle<Double>()
                .grouping(.automatic)
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }

    private var displayedSpend: Double {
        BankCurrencyConversion.convert(spentAmountAED, from: .aed, to: currency)
    }

    private var displayedSavingsAmount: Double {
        BankCurrencyConversion.convert(11_314, from: .aed, to: currency)
    }

    private var monthName: String {
        Date.now.formatted(
            Date.FormatStyle()
                .month(.wide)
                .locale(locale)
        )
    }
}

private struct BankSavingsSlice: Identifiable {
    let name: String
    let value: Double
    let color: Color

    var id: String { name }
}

private struct BankRewardBubble: View {
    @Environment(\.appThemePalette) private var palette
    let systemImage: String
    let color: Color
    var size: CGFloat = 27

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            .clipShape(.circle)
            .overlay {
                Circle()
                    .strokeBorder(palette.surface, lineWidth: 3)
            }
    }
}

private extension View {
    func bankWidgetSurface() -> some View {
        appFloatingSurface(radius: AppSurfaceMetrics.cornerRadius)
            .overlay {
                RoundedRectangle(cornerRadius: AppSurfaceMetrics.cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 0.5)
            }
    }
}

private struct BankAccountSummaryPage: View {
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .largeTitle) private var balanceFontSize = 57.8
    @ScaledMetric(relativeTo: .title) private var currencyFontSize = 34.0
    @ScaledMetric(relativeTo: .subheadline) private var accountIconSize = 18.0
    let account: BankAccount
    @Binding var selection: BankAccount?
    @Binding var displayCurrency: AppCurrency

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

            accountControls
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var accountIcon: some View {
        Image(systemName: "creditcard.fill")
            .font(.system(size: accountIconSize, weight: .semibold))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var accountControls: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                controlRow
            }
        } else {
            controlRow
        }
    }

    @ViewBuilder
    private var controlRow: some View {
        if #available(iOS 26.0, *) {
            HStack(spacing: 8) {
                accountSelector
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                currencyButton
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
            }
        } else {
            HStack(spacing: 8) {
                accountSelector
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                currencyButton
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
            }
        }
    }

    private var accountSelector: some View {
        Menu {
            ForEach(BankAccount.allCases) { option in
                Button {
                    withAnimation(.smooth) {
                        selection = option
                    }
                } label: {
                    HStack {
                        Text(option.title)

                        if selection == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                if account != .total {
                    accountIcon
                }

                if account == .total {
                    Text(account.name)
                } else {
                    Text(account.title)
                }
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
            }
            .appFont(.subheadline, weight: .semibold)
            .foregroundStyle(.white)
            .lineLimit(1)
        }
        .accessibilityLabel("Select account")
        .accessibilityValue(Text(account.title))
        .accessibilityHint("Shows the account list")
    }

    private var currencyButton: some View {
        Button {
            withAnimation(.smooth) {
                displayCurrency = displayCurrency == .aed ? .usd : .aed
            }
        } label: {
            Text(verbatim: displayCurrency.rawValue)
                .appFont(.subheadline, weight: .semibold)
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .accessibilityLabel("Display currency")
        .accessibilityValue(displayCurrency.rawValue)
        .accessibilityHint(
            displayCurrency == .aed
                ? "Switches values to US dollars"
                : "Switches values to UAE dirhams"
        )
    }

    private var balanceText: Text {
        let amount = Text(verbatim: formattedBalance)
            .font(AppFonts.font(size: balanceFontSize, weight: .heavy, relativeTo: .largeTitle, locale: locale))

        if displayCurrency == .usd {
            let currency = Text(verbatim: "$")
                .font(AppFonts.font(size: balanceFontSize, weight: .heavy, relativeTo: .largeTitle, locale: locale))
            return Text("\(currency)\(amount)")
        } else {
            let currency = Text(verbatim: "\u{00A0}AED")
                .font(AppFonts.font(size: currencyFontSize, weight: .heavy, relativeTo: .title, locale: locale))
            return Text("\(amount)\(currency)")
        }
    }

    private var formattedBalance: String {
        abs(displayedBalance).formatted(
            FloatingPointFormatStyle<Double>()
                .grouping(.automatic)
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }

    private var displayedBalance: Double {
        BankCurrencyConversion.convert(
            account.balance,
            from: account.currency,
            to: displayCurrency
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
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .glassEffect(
                    .regular.tint(palette.surface).interactive(),
                    in: .circle
                )
        } else {
            button
                .buttonStyle(.plain)
                .background(palette.surface, in: .circle)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
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
            .font(centsFont)

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
        .background(
            palette.surface.opacity(0.62),
            in: .rect(cornerRadius: AppSurfaceMetrics.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppSurfaceMetrics.cornerRadius, style: .continuous)
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

private enum BankCurrencyConversion {
    private static let aedPerUSD = 3.6725

    static func convert(_ amount: Double, from source: AppCurrency, to target: AppCurrency) -> Double {
        guard source != target else { return amount }

        switch (source, target) {
        case (.aed, .usd): return amount / aedPerUSD
        case (.usd, .aed): return amount * aedPerUSD
        default: return amount
        }
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
        case .total: "All accounts"
        case .visa, .mastercard: "Card balance"
        }
    }

    var currency: AppCurrency {
        switch self {
        case .total: .aed
        case .visa, .mastercard: .usd
        }
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

    static let activitySamples = (aedSamples + usdExceptionSamples)
        .sorted { $0.date > $1.date }

    static let usdExceptionSamples: [BankTransaction] = [
        sample("usd-salary", "Salary", "Northstar Studio", 8_250, .usd, daysAgo: 0, hour: 9, symbol: "briefcase.fill", color: .green, searchTerms: "salary northstar studio راتب نورث ستار"),
        sample("usd-exchange", "Exchanged to AED", "USD → AED account", -1_250, .usd, daysAgo: 0, hour: 11, symbol: "arrow.triangle.2.circlepath", color: .blue, searchTerms: "exchange usd aed تحويل دولار درهم"),
        sample("usd-youtube-premium", "YouTube Premium", "Subscription", -13.99, .usd, daysAgo: 1, hour: 21, symbol: "play.fill", color: .red, searchTerms: "youtube premium subscription يوتيوب بريميوم اشتراك", brandName: "YouTube Premium"),
        sample("usd-cursor", "Cursor", "Productivity", -20, .usd, daysAgo: 2, hour: 12, symbol: "cursorarrow", color: .black, searchTerms: "cursor productivity subscription كيرسر إنتاجية اشتراك", brandName: "Cursor")
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
