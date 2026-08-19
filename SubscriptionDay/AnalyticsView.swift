import Charts
import SwiftUI

struct AnalyticsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.appCurrency) private var currency
    @Environment(\.appThemePalette) private var palette
    let showsDoneButton: Bool
    @State private var selectedYear = 2026
    @State private var selectedCategoryName = "All Categories"
    @State private var selectedBreakdown: SpendingBreakdown = .categories

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Spending breakdown", selection: $selectedBreakdown) {
                        ForEach(SpendingBreakdown.allCases) { breakdown in
                            Text(breakdown.title).tag(breakdown)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    if slices.isEmpty {
                        ContentUnavailableView(
                            "No Spending Data",
                            systemImage: "chart.pie",
                            description: Text("Add a subscription for \(selectedYear) to see analytics.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 260)
                        .listRowSeparator(.hidden)
                    } else {
                        AnalyticsChart(slices: slices)
                            .frame(height: 300)
                            .listRowSeparator(.hidden)
                    }

                    Picker("Year", selection: $selectedYear) {
                        ForEach((selectedYear - 3)...(selectedYear + 3), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .tint(palette.accent)

                    Picker("Category", selection: $selectedCategoryName) {
                        Text("All Categories").tag("All Categories")
                        ForEach(SubscriptionCategory.allCases) { category in
                            Text(category.rawValue).tag(category.rawValue)
                        }
                    }
                    .tint(palette.accent)
                } footer: {
                    Text("Based on \(activeSubscriptions.count) active \(activeSubscriptions.count == 1 ? "subscription" : "subscriptions").")
                }
                .appThemedSurfaceRow()

                Section("Forecast") {
                    LabeledContent("Yearly Forecast") {
                        Text(currency.formatted(yearlyForecast))
                            .font(.nunito(.title3, weight: .semibold))
                            .monospacedDigit()
                    }
                    LabeledContent("Average Monthly Cost") {
                        Text(currency.formatted(yearlyForecast / 12))
                            .font(.nunito(.title3, weight: .semibold))
                            .monospacedDigit()
                    }
                }
                .appThemedSurfaceRow()

                Section("Lifetime") {
                    LabeledContent("Total Paid") {
                        Text(currency.formatted(model.lifetimePaidTotal()))
                            .font(.nunito(.title3, weight: .semibold))
                            .monospacedDigit()
                    }

                    ForEach(lifetimeServiceTotals) { item in
                        HStack(spacing: 12) {
                            ServiceLogo(service: item.service, size: 32)
                            Text(item.service.name)
                                .lineLimit(1)
                            Spacer(minLength: 12)
                            Text(currency.formatted(item.amount))
                                .font(.nunito(.body, weight: .semibold))
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .appThemedSurfaceRow()
            }
            .id(accentColor)
            .appThemedScreenBackground()
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
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
    }

    private var selectedCategory: SubscriptionCategory? {
        SubscriptionCategory(rawValue: selectedCategoryName)
    }

    private var activeSubscriptions: [SubscriptionRecord] {
        model.activeSubscriptions(in: selectedYear, category: selectedCategory)
    }

    private var yearlyForecast: Double {
        model.forecast(in: selectedYear, category: selectedCategory)
    }

    private var lifetimeServiceTotals: [LifetimeServiceTotal] {
        model.lifetimePaidTotalsByService().map {
            LifetimeServiceTotal(service: $0.service, amount: $0.amount)
        }
    }

    private var slices: [AnalyticsSlice] {
        switch selectedBreakdown {
        case .apps:
            return model.serviceForecasts(in: selectedYear, category: selectedCategory).map {
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
                let amount = model.forecast(in: selectedYear, category: selectedCategory)
                return amount > 0
                    ? [AnalyticsSlice(
                        id: "category-\(selectedCategory.id)",
                        name: selectedCategory.rawValue,
                        amount: amount,
                        color: selectedCategory.chartColor,
                        service: nil,
                        category: selectedCategory
                    )]
                    : []
            }
            return model.categoryForecasts(in: selectedYear).map {
                AnalyticsSlice(
                    id: "category-\($0.category.id)",
                    name: $0.category.rawValue,
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
        case .other: "square.grid.2x2.fill"
        }
    }
}

private struct AnalyticsChart: View {
    @Environment(\.appCurrency) private var currency
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
                .foregroundStyle(by: .value("Spending Group", slice.name))
                .annotation(position: .overlay) {
                    if let service = slice.service {
                        ServiceLogo(service: service, size: 28)
                    } else if let category = slice.category {
                        CategoryChartIcon(category: category)
                    }
                }
                .accessibilityLabel(slice.name)
                .accessibilityValue(currency.formatted(slice.amount))
            }
            .chartForegroundStyleScale(
                domain: slices.map(\.name),
                range: slices.map(\.color)
            )
            .chartLegend(position: .bottom, alignment: .center, spacing: 10)

            VStack(spacing: 3) {
                Text("Total")
                    .font(.nunito(.subheadline))
                    .foregroundStyle(.secondary)
                Text(currency.formatted(total))
                    .font(.nunito(.title2, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: 120)
            .padding(.bottom, 42)
            .accessibilityHidden(true)
        }
    }

    private var total: Double {
        slices.reduce(0) { $0 + $1.amount }
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
