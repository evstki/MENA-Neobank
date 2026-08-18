import Charts
import SwiftUI

struct AnalyticsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let showsDoneButton: Bool
    @State private var selectedYear = 2026
    @State private var selectedCategoryName = "All Categories"

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Filters") {
                    Picker("Year", selection: $selectedYear) {
                        ForEach((selectedYear - 3)...(selectedYear + 3), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    Picker("Category", selection: $selectedCategoryName) {
                        Text("All Categories").tag("All Categories")
                        ForEach(SubscriptionCategory.allCases) { category in
                            Text(category.rawValue).tag(category.rawValue)
                        }
                    }
                }

                Section {
                    if slices.isEmpty {
                        ContentUnavailableView(
                            "No Spending Data",
                            systemImage: "chart.pie",
                            description: Text("Add a subscription for \(selectedYear) to see analytics.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 260)
                    } else {
                        AnalyticsChart(slices: slices)
                            .frame(height: 300)
                    }
                } header: {
                    Text("Spending by Category")
                } footer: {
                    Text("Based on \(activeSubscriptions.count) active \(activeSubscriptions.count == 1 ? "subscription" : "subscriptions").")
                }

                Section("Forecast") {
                    LabeledContent("Yearly Forecast") {
                        Text(yearlyForecast, format: .currency(code: "USD"))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    }
                    LabeledContent("Average Monthly Cost") {
                        Text(yearlyForecast / 12, format: .currency(code: "USD"))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
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

    private var slices: [AnalyticsSlice] {
        if let selectedCategory {
            let amount = model.forecast(in: selectedYear, category: selectedCategory)
            return amount > 0 ? [AnalyticsSlice(category: selectedCategory, amount: amount)] : []
        }
        return model.categoryForecasts(in: selectedYear).map {
            AnalyticsSlice(category: $0.category, amount: $0.amount)
        }
    }
}

private struct AnalyticsSlice: Identifiable {
    let category: SubscriptionCategory
    let amount: Double
    var id: SubscriptionCategory { category }

    var color: Color {
        switch category {
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
}

private struct AnalyticsChart: View {
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
                .foregroundStyle(by: .value("Category", slice.category.rawValue))
                .accessibilityLabel(slice.category.rawValue)
                .accessibilityValue(slice.amount.formatted(.currency(code: "USD")))
            }
            .chartForegroundStyleScale(
                domain: slices.map { $0.category.rawValue },
                range: slices.map(\.color)
            )
            .chartLegend(position: .bottom, alignment: .center, spacing: 10)

            VStack(spacing: 3) {
                Text("Total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(total, format: .currency(code: "USD"))
                    .font(.title2.bold())
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

#Preview {
    AnalyticsView()
        .environment(AppModel())
}
