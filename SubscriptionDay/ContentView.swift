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

            Tab(value: .add, role: .search) {
                Color.clear
            } label: {
                Image(uiImage: accentAddIcon)
                    .accessibilityLabel("Add Subscription")
            }
        }
        .onChange(of: selectedTab, handleTabChange)
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

    private func handleTabChange(_ oldTab: AppTab, _ newTab: AppTab) {
        guard newTab == .add else { return }
        selectedTab = oldTab == .add ? .overview : oldTab
        presentCatalog()
    }

    private func presentCatalog() {
        model.draftStartDate = nil
        model.showingCatalog = true
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

    private var accentAddIcon: UIImage {
        let symbol = UIImage(systemName: "plus.circle.fill") ?? UIImage()
        return symbol.withTintColor(UIColor(palette.accent), renderingMode: .alwaysOriginal)
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
    case add
}

#Preview {
    ContentView()
        .environment(AppModel())
}
