import SwiftUI

struct GrowView: View {
    @State private var showingSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackdrop()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 30) {
                        AppPageHeading(
                            title: "Savings",
                            description: "Save, invest and grow your money"
                        )
                        GrowBalanceSection()
                        GrowSavingsSection()
                        GrowInvestmentsSection()
                        GrowAnalyticsSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }
            .background {
                AppNavigationTitleFontConfigurator()
                    .frame(width: 0, height: 0)
            }
            .navigationTitle("Savings")
            .navigationBarTitleDisplayMode(.large)
            .appTopNavigationBar(searchTitle: "Search Savings") {
                showingSearch = true
            }
            .sheet(isPresented: $showingSearch) {
                GrowSearchSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: GrowInvestmentDestination.self) { destination in
                GrowInvestmentDestinationView(destination: destination)
            }
        }
    }
}

private struct GrowBalanceSection: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Total saved & invested")
                .appFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)

            Text(formattedUSD(GrowContent.totalBalanceUSD))
                .appFont(size: 40, weight: .bold, relativeTo: .largeTitle)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 20) {
                GrowMetric(
                    label: "Savings",
                    value: formattedUSD(GrowContent.savingsBalanceUSD),
                    tint: .primary
                )
                GrowMetric(
                    label: "Investments",
                    value: formattedUSD(GrowContent.portfolioValueUSD),
                    tint: palette.accent
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func formattedUSD(_ amount: Double) -> String {
        currency.formatted(AppCurrency.usd.converted(amount, to: currency), hidesCents: hidesCents)
    }
}

private struct GrowAnalyticsSection: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents

    private let monthlyTrend = [
        GrowTrendPoint(id: 1, value: 0.36),
        GrowTrendPoint(id: 2, value: 0.48),
        GrowTrendPoint(id: 3, value: 0.43),
        GrowTrendPoint(id: 4, value: 0.61),
        GrowTrendPoint(id: 5, value: 0.72),
        GrowTrendPoint(id: 6, value: 0.66),
        GrowTrendPoint(id: 7, value: 0.84),
        GrowTrendPoint(id: 8, value: 0.92)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analytics")
                .appFont(.headline, weight: .bold)

            HStack(alignment: .bottom, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved this month")
                        .appFont(.footnote, weight: .medium)
                        .foregroundStyle(.secondary)

                    Text(formattedUSD(2_266))
                        .appFont(.title2, weight: .bold)
                        .foregroundStyle(palette.accent)
                        .monospacedDigit()

                    Label("2.1% this month", systemImage: "arrow.up.right")
                        .appFont(.footnote, weight: .bold)
                        .foregroundStyle(.green)
                }

                Spacer(minLength: 4)

                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(monthlyTrend) { point in
                        Capsule()
                            .fill(point.id == monthlyTrend.last?.id ? palette.accent : palette.accent.opacity(0.28))
                            .frame(width: 6, height: 44 * point.value)
                    }
                }
                .frame(height: 46, alignment: .bottom)
                .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    private func formattedUSD(_ amount: Double) -> String {
        currency.formatted(AppCurrency.usd.converted(amount, to: currency), hidesCents: hidesCents)
    }
}

private struct GrowTrendPoint: Identifiable {
    let id: Int
    let value: Double
}

private struct GrowMetric: View {
    let label: LocalizedStringKey
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .appFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            Text(value)
                .appFont(.subheadline, weight: .bold)
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.87)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GrowSavingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GrowSectionHeader(title: "Savings accounts")

            ScrollView(.horizontal) {
                LazyHStack(spacing: AppSurfaceMetrics.blockSpacing) {
                    ForEach(GrowContent.accounts) { account in
                        GrowSavingsCard(account: account)
                            .containerRelativeFrame(
                                .horizontal,
                                count: 10,
                                span: 8,
                                spacing: AppSurfaceMetrics.blockSpacing
                            )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

private struct GrowSavingsAccount: Identifiable {
    let id: String
    let name: LocalizedStringKey
    let detail: LocalizedStringKey
    let balanceUSD: Double
    let goalUSD: Double
    let annualRate: Double
    let symbol: String
    let tint: Color
}

private struct GrowSavingsCard: View {
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents
    @Environment(\.locale) private var locale
    let account: GrowSavingsAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: account.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(account.tint.opacity(0.72), in: .circle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(account.name)
                        .appFont(.headline, weight: .bold)
                    Text(account.detail)
                        .appFont(.footnote, weight: .medium)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Balance")
                    .appFont(.footnote, weight: .medium)
                    .foregroundStyle(.secondary)

                Text(formattedUSD(account.balanceUSD))
                    .appFont(size: 30, weight: .bold, relativeTo: .title)
                    .monospacedDigit()

                Label(annualRateLabel, systemImage: "percent")
                    .appFont(.footnote, weight: .bold)
                    .foregroundStyle(account.tint)
            }

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(account.tint)

                HStack(spacing: 8) {
                    Text(goalAmountLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Text(progressLabel)
                }
                .appFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(minHeight: 246, alignment: .topLeading)
        .growCardSurface(radius: AppSurfaceMetrics.cornerRadius)
        .accessibilityElement(children: .combine)
    }

    private var progress: Double {
        min(account.balanceUSD / account.goalUSD, 1)
    }

    private var annualRateLabel: String {
        AppLocalization.string("grow.apy", locale: locale, arguments: account.annualRate)
    }

    private var progressLabel: String {
        AppLocalization.string("grow.goalProgress", locale: locale, arguments: Int(progress * 100))
    }

    private var goalAmountLabel: String {
        AppLocalization.string(
            "grow.goalAmount",
            locale: locale,
            arguments: formattedUSD(account.balanceUSD), formattedUSD(account.goalUSD)
        )
    }

    private func formattedUSD(_ amount: Double) -> String {
        currency.formatted(AppCurrency.usd.converted(amount, to: currency), hidesCents: hidesCents)
    }
}

private enum GrowContent {
    static let accounts = [
        GrowSavingsAccount(
            id: "emergency",
            name: "Emergency fund",
            detail: "For unexpected expenses",
            balanceUSD: 12_500,
            goalUSD: 20_000,
            annualRate: 4.25,
            symbol: "shield.fill",
            tint: .cyan
        ),
        GrowSavingsAccount(
            id: "travel",
            name: "Travel fund",
            detail: "Japan · Spring 2027",
            balanceUSD: 6_800,
            goalUSD: 10_000,
            annualRate: 3.80,
            symbol: "airplane",
            tint: .purple
        )
    ]

    static let portfolioValueUSD = 34_620.0
    static let savingsBalanceUSD = accounts.reduce(0) { $0 + $1.balanceUSD }
    static let totalBalanceUSD = savingsBalanceUSD + portfolioValueUSD
}

private struct GrowInvestmentsSection: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.appCurrency) private var currency
    @Environment(\.appHidesCents) private var hidesCents

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GrowSectionHeader(title: "Investments")

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Portfolio value")
                            .appFont(.subheadline, weight: .medium)
                            .foregroundStyle(.secondary)

                        Text(formattedUSD(GrowContent.portfolioValueUSD))
                            .appFont(size: 32, weight: .bold, relativeTo: .largeTitle)
                            .monospacedDigit()

                        Text("+\(formattedUSD(2_140)) · +6.6%")
                            .appFont(.footnote, weight: .bold)
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    BundledArtwork(name: "coin")
                        .frame(width: 104, height: 82)
                        .offset(x: 12, y: -6)
                        .accessibilityHidden(true)
                }

                GrowAllocationBar()

                HStack(spacing: 16) {
                    GrowAllocationLabel(title: "ETFs", value: "62%", color: palette.accent)
                    GrowAllocationLabel(title: "Stocks", value: "26%", color: .purple)
                    GrowAllocationLabel(title: "Cash", value: "12%", color: .gray)
                }

                GrowInvestmentActions()
            }
            .padding(20)
            .growCardSurface(radius: AppSurfaceMetrics.cornerRadius)
        }
    }

    private func formattedUSD(_ amount: Double) -> String {
        currency.formatted(AppCurrency.usd.converted(amount, to: currency), hidesCents: hidesCents)
    }
}

private struct GrowInvestmentActions: View {
    @Environment(\.appThemePalette) private var palette

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                investLink
                portfolioLink
            }

            VStack(spacing: 12) {
                investLink
                portfolioLink
            }
        }
    }

    private var investLink: some View {
        NavigationLink(value: GrowInvestmentDestination.invest) {
            Label("Invest", systemImage: "plus")
                .appFont(.subheadline, weight: .bold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .foregroundStyle(palette.accentForeground)
                .background(palette.accent, in: .capsule)
        }
        .buttonStyle(.plain)
    }

    private var portfolioLink: some View {
        NavigationLink(value: GrowInvestmentDestination.portfolio) {
            Label("View portfolio", systemImage: "chart.pie")
                .appFont(.subheadline, weight: .bold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .foregroundStyle(.primary)
                .background(palette.selectedSurface, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

private struct GrowAllocationBar: View {
    @Environment(\.appThemePalette) private var palette

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(proxy.size.width - 8, 0)
            HStack(spacing: 4) {
                Capsule()
                    .fill(palette.accent)
                    .frame(width: availableWidth * 0.62)
                Capsule()
                    .fill(.purple)
                    .frame(width: availableWidth * 0.26)
                Capsule()
                    .fill(.gray)
                    .frame(width: availableWidth * 0.12)
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

private struct GrowAllocationLabel: View {
    let title: LocalizedStringKey
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .appFont(.footnote, weight: .medium)
                    .foregroundStyle(.secondary)
                Text(value)
                    .appFont(.footnote, weight: .bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GrowSectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .appFont(.title2, weight: .bold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GrowCardSurface: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .appFloatingSurface(radius: radius)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 0.5)
            }
    }
}

private extension View {
    func growCardSurface(radius: CGFloat) -> some View {
        modifier(GrowCardSurface(radius: radius))
    }
}

private enum GrowInvestmentDestination: Hashable {
    case invest
    case portfolio

    var title: LocalizedStringKey {
        switch self {
        case .invest: "Invest"
        case .portfolio: "Your portfolio"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .invest: "Choose an investment to grow your portfolio."
        case .portfolio: "Review holdings, allocation and performance."
        }
    }

    var symbol: String {
        switch self {
        case .invest: "plus.circle.fill"
        case .portfolio: "chart.pie.fill"
        }
    }
}

private struct GrowInvestmentDestinationView: View {
    @Environment(\.appThemePalette) private var palette
    let destination: GrowInvestmentDestination

    var body: some View {
        ZStack {
            AppScreenBackdrop()

            VStack(spacing: 18) {
                Image(systemName: destination.symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 76, height: 76)
                    .background(palette.selectedSurface, in: .circle)
                    .accessibilityHidden(true)

                Text(destination.title)
                    .appFont(.title2, weight: .bold)

                Text(destination.subtitle)
                    .appFont(.body, weight: .medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
        .navigationTitle(destination.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum GrowFeature: String, CaseIterable, Identifiable, Hashable {
    case analytics = "Analytics"
    case savings = "Savings accounts"
    case investments = "Investments"

    var id: String { rawValue }

    var title: LocalizedStringKey { LocalizedStringKey(rawValue) }

    var subtitle: LocalizedStringKey {
        switch self {
        case .analytics: "Review savings and investment growth"
        case .savings: "Track goals and interest across savings accounts"
        case .investments: "Review portfolio value and allocation"
        }
    }

    var symbol: String {
        switch self {
        case .analytics: "chart.bar.xaxis"
        case .savings: "banknote.fill"
        case .investments: "chart.line.uptrend.xyaxis"
        }
    }
}

private struct GrowSearchSheet: View {
    @Environment(\.appThemePalette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var query = ""

    private var results: [GrowFeature] {
        guard !query.isEmpty else { return GrowFeature.allCases }
        return GrowFeature.allCases.filter {
            AppLocalization.string($0.rawValue, locale: locale)
                .localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(results) { feature in
                        NavigationLink(value: feature) {
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(feature.title)
                                        .appFont(.headline, weight: .bold)
                                    Text(feature.subtitle)
                                        .appFont(.footnote, weight: .medium)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: feature.symbol)
                                    .foregroundStyle(palette.accent)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .appThemedScreenBackground()
                }
            }
            .navigationTitle("Search Savings")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search Savings")
            .navigationDestination(for: GrowFeature.self) { feature in
                GrowFeatureSummary(feature: feature)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct GrowFeatureSummary: View {
    @Environment(\.appThemePalette) private var palette
    let feature: GrowFeature

    var body: some View {
        ZStack {
            AppScreenBackdrop()

            VStack(spacing: 18) {
                Image(systemName: feature.symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 76, height: 76)
                    .background(palette.selectedSurface, in: .circle)

                Text(feature.title)
                    .appFont(.title2, weight: .bold)

                Text(feature.subtitle)
                    .appFont(.body, weight: .medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
        .navigationTitle(feature.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
