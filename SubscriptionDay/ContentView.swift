import SwiftUI
import StoreKit

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.requestReview) private var requestReview
    @AppStorage("subscription-day.has-requested-review") private var hasRequestedReview = false
    @State private var selectedTab: AppTab = .overview

    var body: some View {
        @Bindable var model = model

        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "house.fill", value: .overview) {
                BankView()
            }

            Tab("Products", systemImage: "creditcard.fill", value: .products) {
                ProductsView()
            }

            Tab("Services", systemImage: "rectangle.grid.2x2.fill", value: .pay) {
                PayView()
            }

            Tab("Savings", systemImage: "chart.bar.xaxis", value: .grow) {
                GrowView()
            }
        }
        .onChange(of: model.subscriptions.count, requestReviewAfterSubscriptionAdded)
        .sheet(isPresented: $model.showingCatalog) {
                AddSubscriptionView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $model.showingSearch) {
            SearchSubscriptionsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $model.showingDaySubscriptions) {
                DaySubscriptionsView()
                    .presentationDetents([.height(model.daySubscriptionsSheetHeight)])
                    .presentationDragIndicator(.visible)
        }
        .sheet(item: $model.editingSubscription) { subscription in
            EditSubscriptionView(subscription: subscription)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .environment(\.appThemePalette, palette)
        .tint(palette.accent)
    }

    private func requestReviewAfterSubscriptionAdded(_ oldCount: Int, _ newCount: Int) {
        guard newCount > oldCount, !hasRequestedReview else { return }
        hasRequestedReview = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            requestReview()
        }
    }

    private var palette: AppThemePalette {
        AppThemePalette(accent: accentColor)
    }
}

private enum AppTab: Hashable {
    case overview
    case pay
    case products
    case grow
}

#Preview {
    ContentView()
        .environment(AppModel())
}
