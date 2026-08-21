import SwiftUI

struct SearchSubscriptionsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    let showsDoneButton: Bool
    let automaticallyFocusesSearch: Bool
    let navigationTitle: LocalizedStringResource

    init(
        showsDoneButton: Bool = true,
        automaticallyFocusesSearch: Bool = true,
        navigationTitle: LocalizedStringResource = "Search"
    ) {
        self.showsDoneButton = showsDoneButton
        self.automaticallyFocusesSearch = automaticallyFocusesSearch
        self.navigationTitle = navigationTitle
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            List {
                ForEach(model.filteredSubscriptions) { subscription in
                    SearchSubscriptionRow(subscription: subscription)
                        .appThemedSurfaceRow()
                }
            }
            .appThemedScreenBackground()
            .overlay {
                if model.subscriptions.isEmpty {
                    ContentUnavailableView(
                        "No Subscriptions",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Subscriptions you add will appear here.")
                    )
                } else if model.filteredSubscriptions.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                }
            }
            .navigationTitle(Text(navigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.searchText, prompt: "Subscriptions")
            .searchFocused($isSearchFocused)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            model.searchText = ""
                            dismiss()
                        }
                    }
                }
            }
        }
        .task {
            if automaticallyFocusesSearch {
                isSearchFocused = true
            }
        }
    }
}

private struct SearchSubscriptionRow: View {
    @Environment(\.appHidesCents) private var hidesCents
    @Environment(\.locale) private var locale
    let subscription: SubscriptionRecord

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: subscription.service, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .appFont(.headline, weight: .semibold)
                Text(verbatim: "\(subscription.schedule.localizedTitle(locale: locale)) · \(subscription.category.localizedTitle(locale: locale))")
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(subscription.currency.formatted(subscription.amount, hidesCents: hidesCents))
                .appFont(.body, weight: .medium)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SearchSubscriptionsView()
        .environment(AppModel())
}
