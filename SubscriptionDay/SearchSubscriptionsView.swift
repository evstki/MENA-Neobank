import SwiftUI

struct SearchSubscriptionsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    let showsDoneButton: Bool

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            List {
                ForEach(model.filteredSubscriptions) { subscription in
                    SearchSubscriptionRow(subscription: subscription)
                }
            }
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
            .navigationTitle("Search")
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
            isSearchFocused = true
        }
    }
}

private struct SearchSubscriptionRow: View {
    let subscription: SubscriptionRecord

    var body: some View {
        HStack(spacing: 12) {
            ServiceLogo(service: subscription.service, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.headline)
                Text("\(subscription.schedule.rawValue) · \(subscription.category.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(subscription.amount, format: .currency(code: "USD"))
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SearchSubscriptionsView()
        .environment(AppModel())
}
