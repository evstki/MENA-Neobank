import SwiftUI
import StoreKit

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.requestReview) private var requestReview
    @AppStorage("subscription-day.has-requested-review") private var hasRequestedReview = false
    @State private var selectedTab: AppTab = .subscriptions

    var body: some View {
        @Bindable var model = model

        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "calendar", value: .subscriptions) {
                HomeView()
            }

            Tab("Analytics", systemImage: "chart.bar.xaxis", value: .analytics) {
                AnalyticsView(showsDoneButton: false)
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
        .sheet(isPresented: $model.showingSubscriptionDetail) {
            if let subscriptionID = model.selectedSubscriptionID {
                SubscriptionDetailView(subscriptionID: subscriptionID)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .environment(\.appThemePalette, palette)
        .tint(palette.accent)
    }

    private func handleTabChange(_ oldTab: AppTab, _ newTab: AppTab) {
        guard newTab == .add else { return }
        selectedTab = oldTab == .add ? .subscriptions : oldTab
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
        AppThemePalette(accent: accentColor, colorScheme: colorScheme)
    }
}

private enum AppTab: Hashable {
    case subscriptions
    case analytics
    case add
}

#Preview {
    ContentView()
        .environment(AppModel())
}
