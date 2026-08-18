import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedTab: AppTab = .subscriptions

    var body: some View {
        @Bindable var model = model

        TabView(selection: $selectedTab) {
            Tab("Subscriptions", systemImage: "calendar", value: .subscriptions) {
                HomeView()
            }

            Tab("Analytics", systemImage: "chart.bar.xaxis", value: .analytics) {
                AnalyticsView(showsDoneButton: false)
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView(showsDoneButton: false)
            }

            Tab(value: .add, role: .search) {
                Color.clear
            } label: {
                Image(uiImage: accentAddIcon)
                    .accessibilityLabel("Add Subscription")
            }
        }
        .onChange(of: selectedTab, handleTabChange)
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

    private var accentAddIcon: UIImage {
        let accentColor = UIColor(red: 0.38, green: 0.50, blue: 1.00, alpha: 1.00)
        let symbol = UIImage(systemName: "plus.circle.fill") ?? UIImage()
        return symbol.withTintColor(accentColor, renderingMode: .alwaysOriginal)
    }
}

private enum AppTab: Hashable {
    case subscriptions
    case analytics
    case add
    case settings
}

#Preview {
    ContentView()
        .environment(AppModel())
}
