import Charts
import SwiftUI

struct AnalyticsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents
    @Environment(\.appThemePalette) private var palette
    @Environment(\.locale) private var locale
    let showsDoneButton: Bool
    @State private var selectedYear = 2026
    @State private var selectedCategoryName = "All Categories"
    @State private var selectedBreakdown: SpendingBreakdown = .categories
    @State private var presentedBreakdown: SpendingBreakdown?

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackdrop()

                Form {
                    Section {
                        Picker("Spending breakdown", selection: $selectedBreakdown) {
                            ForEach(SpendingBreakdown.allCases) { breakdown in
                                Text(LocalizedStringKey(breakdown.title)).tag(breakdown)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowSeparator(.hidden)

                        AnalyticsInteractiveChart(
                            breakdown: $selectedBreakdown,
                            slices: slices(for: selectedBreakdown),
                            selectedYear: selectedYear,
                            presentedBreakdown: $presentedBreakdown
                        )
                        .frame(height: 300)
                        .listRowSeparator(.hidden)
                        .sensoryFeedback(.selection, trigger: selectedBreakdown)

                        Picker("Year", selection: $selectedYear) {
                            ForEach((selectedYear - 3)...(selectedYear + 3), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .tint(palette.accent)

                        Picker("Category", selection: $selectedCategoryName) {
                            Text("All Categories").tag("All Categories")
                            ForEach(SubscriptionCategory.allCases) { category in
                                Text(category.localizedTitleKey).tag(category.rawValue)
                            }
                        }
                        .tint(palette.accent)
                    } footer: {
                        Text(AppLocalization.activeSubscriptions(activeSubscriptions.count, locale: locale))
                    }
                    .appThemedSurfaceRow(opacity: 0.5)

                    Section("Forecast") {
                        LabeledContent("Yearly Forecast") {
                            Text(currency.formatted(yearlyForecast, hidesCents: hidesCents))
                                .appFont(.title3, weight: .semibold)
                                .monospacedDigit()
                        }
                        LabeledContent("Average Monthly Cost") {
                            Text(currency.formatted(yearlyForecast / 12, hidesCents: hidesCents))
                                .appFont(.title3, weight: .semibold)
                                .monospacedDigit()
                        }
                    }
                    .appThemedSurfaceRow(opacity: 0.5)

                    Section {
                        LabeledContent("Total Paid") {
                            Text(currency.formatted(
                                model.lifetimePaidTotal(convertedTo: currency),
                                hidesCents: hidesCents
                            ))
                                .appFont(.title3, weight: .semibold)
                                .monospacedDigit()
                        }

                        ForEach(lifetimeServiceTotals) { item in
                            HStack(spacing: 12) {
                                ServiceLogo(service: item.service, size: 32)
                                Text(item.service.name)
                                    .lineLimit(1)
                                Spacer(minLength: 12)
                                Text(currency.formatted(item.amount, hidesCents: hidesCents))
                                    .appFont(.body, weight: .semibold)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    } header: {
                        Text(lifetimeSectionTitle)
                    }
                    .appThemedSurfaceRow(opacity: 0.5)
                }
                .id(accentColor)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .appTopNavigationBar(isVisible: !showsDoneButton) {
                model.showingSearch = true
            }
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .onAppear {
            selectedYear = AppModel.calendar.component(.year, from: model.selectedMonth)
        }
        .sheet(item: $presentedBreakdown) { breakdown in
            AnalyticsBreakdownSheet(
                breakdown: breakdown,
                slices: slices(for: breakdown)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var selectedCategory: SubscriptionCategory? {
        SubscriptionCategory(rawValue: selectedCategoryName)
    }

    private var activeSubscriptions: [SubscriptionRecord] {
        model.activeSubscriptions(in: selectedYear, category: selectedCategory)
    }

    private var yearlyForecast: Double {
        model.forecast(in: selectedYear, category: selectedCategory, convertedTo: currency)
    }

    private var lifetimeServiceTotals: [LifetimeServiceTotal] {
        model.lifetimePaidTotalsByService(convertedTo: currency).map {
            LifetimeServiceTotal(service: $0.service, amount: $0.amount)
        }
    }

    private var lifetimeSectionTitle: String {
        guard let startDate = model.subscriptions.map(\.startDate).min() else {
            return AppLocalization.string("Lifetime", locale: locale)
        }

        let formattedDate = startDate.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(locale)
        )
        return AppLocalization.string(
            "Lifetime from %@",
            locale: locale,
            arguments: formattedDate
        )
    }

    private func slices(for breakdown: SpendingBreakdown) -> [AnalyticsSlice] {
        switch breakdown {
        case .apps:
            return model.serviceForecasts(
                in: selectedYear,
                category: selectedCategory,
                convertedTo: currency
            ).map {
                AnalyticsSlice(
                    id: "app-\($0.service.id)",
                    name: $0.service.name,
                    amount: $0.amount,
                    color: $0.service.brandTint,
                    service: $0.service,
                    category: nil
                )
            }
        case .categories:
            if let selectedCategory {
                let amount = model.forecast(
                    in: selectedYear,
                    category: selectedCategory,
                    convertedTo: currency
                )
                return amount > 0
                    ? [AnalyticsSlice(
                        id: "category-\(selectedCategory.id)",
                        name: selectedCategory.localizedTitle(locale: locale),
                        amount: amount,
                        color: selectedCategory.chartColor,
                        service: nil,
                        category: selectedCategory
                    )]
                    : []
            }
            return model.categoryForecasts(in: selectedYear, convertedTo: currency).map {
                AnalyticsSlice(
                    id: "category-\($0.category.id)",
                    name: $0.category.localizedTitle(locale: locale),
                    amount: $0.amount,
                    color: $0.category.chartColor,
                    service: nil,
                    category: $0.category
                )
            }
        }
    }
}

private struct LifetimeServiceTotal: Identifiable {
    let service: ServiceBrand
    let amount: Double

    var id: String { service.id }
}

private enum SpendingBreakdown: String, CaseIterable, Identifiable {
    case apps
    case categories

    var id: Self { self }

    var title: String {
        switch self {
        case .apps: "Apps"
        case .categories: "Categories"
        }
    }

}

private struct AnalyticsSlice: Identifiable {
    let id: String
    let name: String
    let amount: Double
    let color: Color
    let service: ServiceBrand?
    let category: SubscriptionCategory?
}

private extension SubscriptionCategory {
    var chartColor: Color {
        switch self {
        case .entertainment: SDTheme.chartRed
        case .productivity: SDTheme.chartBlue
        case .cloud: .cyan
        case .health: .green
        case .education: .orange
        case .shopping: .purple
        case .social: .pink
        case .mobile: .teal
        case .other: .gray
        }
    }

    var chartSymbol: String {
        switch self {
        case .entertainment: "play.tv.fill"
        case .productivity: "laptopcomputer"
        case .cloud: "icloud.fill"
        case .health: "heart.fill"
        case .education: "graduationcap.fill"
        case .shopping: "cart.fill"
        case .social: "person.2.fill"
        case .mobile: "antenna.radiowaves.left.and.right"
        case .other: "square.grid.2x2.fill"
        }
    }
}

private struct AnalyticsChart: View {
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents
    let slices: [AnalyticsSlice]

    var body: some View {
        ZStack {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Forecast Amount", slice.amount),
                    innerRadius: .ratio(0.64),
                    angularInset: 2
                )
                .cornerRadius(6)
                .foregroundStyle(slice.color)
                .accessibilityLabel(slice.name)
                .accessibilityValue(currency.formatted(slice.amount, hidesCents: hidesCents))
            }
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let plotFrame = proxy.plotFrame {
                        let frame = geometry[plotFrame]

                        ForEach(slices.filter { shouldShowIcon(for: $0) }) { slice in
                            let position = iconPosition(for: slice, in: frame)

                            sliceIcon(for: slice)
                                .position(x: position.x, y: position.y)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .allowsHitTesting(false)
            }

            VStack(spacing: 3) {
                Text("Total")
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                ViewThatFits(in: .horizontal) {
                    totalAmountLabel(.title2)
                    totalAmountLabel(.title3)
                    totalAmountLabel(.headline)
                    totalAmountLabel(.subheadline, canScale: true)
                }
                .frame(width: 120)
            }
            .frame(maxWidth: 120)
            .accessibilityHidden(true)
        }
    }

    private var total: Double {
        slices.reduce(0) { $0 + $1.amount }
    }

    private func shouldShowIcon(for slice: AnalyticsSlice) -> Bool {
        guard total > 0 else { return false }
        return slice.amount / total >= 0.06
    }

    @ViewBuilder
    private func sliceIcon(for slice: AnalyticsSlice) -> some View {
        if let service = slice.service {
            ServiceLogo(service: service, size: 28)
        } else if let category = slice.category {
            CategoryChartIcon(category: category)
        }
    }

    private func iconPosition(for slice: AnalyticsSlice, in plotFrame: CGRect) -> CGPoint {
        guard total > 0,
              let index = slices.firstIndex(where: { $0.id == slice.id }) else {
            return CGPoint(x: plotFrame.midX, y: plotFrame.midY)
        }

        let precedingAmount = slices[..<index].reduce(0) { $0 + $1.amount }
        let midpointFraction = (precedingAmount + slice.amount / 2) / total
        let midpointAngle = CGFloat(-Double.pi / 2 + midpointFraction * 2 * Double.pi)
        let outerRadius = min(plotFrame.width, plotFrame.height) / 2
        let ringMidpointRadius = outerRadius * 0.82

        return CGPoint(
            x: plotFrame.midX + cos(midpointAngle) * ringMidpointRadius,
            y: plotFrame.midY + sin(midpointAngle) * ringMidpointRadius
        )
    }

    private var formattedTotal: String {
        currency.formatted(total, hidesCents: hidesCents)
    }

    private func totalAmountLabel(
        _ style: Font.TextStyle,
        canScale: Bool = false
    ) -> some View {
        Text(formattedTotal)
            .appFont(style, weight: .bold)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(canScale ? 0.75 : 1)
            .fixedSize(horizontal: !canScale, vertical: false)
    }
}

private struct AnalyticsInteractiveChart: View {
    @Environment(\.locale) private var locale
    @Binding var breakdown: SpendingBreakdown
    let slices: [AnalyticsSlice]
    let selectedYear: Int
    @Binding var presentedBreakdown: SpendingBreakdown?

    var body: some View {
        if slices.isEmpty {
            ContentUnavailableView(
                "No Spending Data",
                systemImage: "chart.pie",
                description: Text(AppLocalization.string(
                    "analytics.empty.description",
                    locale: locale,
                    arguments: selectedYear
                ))
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        } else {
            ZStack {
                AnalyticsChart(slices: slices)
                    .id(breakdown)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                presentedBreakdown = breakdown
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else {
                            return
                        }

                        breakdown = breakdown == .apps ? .categories : .apps
                    }
            )
            .accessibilityLabel("Show Breakdown")
            .accessibilityHint("Tap to show breakdown details.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text("Show Breakdown")) {
                presentedBreakdown = breakdown
            }
        }
    }
}

private struct AnalyticsBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents
    let breakdown: SpendingBreakdown
    let slices: [AnalyticsSlice]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total") {
                        Text(currency.formatted(total, hidesCents: hidesCents))
                            .appFont(.title3, weight: .bold)
                            .monospacedDigit()
                    }
                }
                .appThemedSurfaceRow()

                Section {
                    ForEach(slices) { slice in
                        AnalyticsBreakdownRow(slice: slice, total: total)
                    }
                } header: {
                    Text(LocalizedStringKey(breakdown.title))
                }
                .appThemedSurfaceRow()
            }
            .appThemedScreenBackground()
            .navigationTitle(LocalizedStringKey(breakdown.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var total: Double {
        slices.reduce(0) { $0 + $1.amount }
    }
}

private struct AnalyticsBreakdownRow: View {
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents
    let slice: AnalyticsSlice
    let total: Double

    var body: some View {
        HStack(spacing: 12) {
            breakdownIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(slice.name)
                    .appFont(.body, weight: .semibold)
                    .lineLimit(1)

                Text(share, format: .percent.precision(.fractionLength(0)))
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(currency.formatted(slice.amount, hidesCents: hidesCents))
                .appFont(.body, weight: .semibold)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var breakdownIcon: some View {
        if let service = slice.service {
            ServiceLogo(service: service, size: 36)
        } else if let category = slice.category {
            Image(systemName: category.chartSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(slice.color.gradient, in: Circle())
                .accessibilityHidden(true)
        }
    }

    private var share: Double {
        guard total > 0 else { return 0 }
        return slice.amount / total
    }
}

private struct CategoryChartIcon: View {
    let category: SubscriptionCategory

    var body: some View {
        Image(systemName: category.chartSymbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(.black.opacity(0.24), in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    AnalyticsView()
        .environment(AppModel())
}
