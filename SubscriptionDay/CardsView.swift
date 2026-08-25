import SwiftUI

struct CardsView: View {
    @Environment(\.appThemePalette) private var palette
    @State private var selectedCard: ManagedBankCard? = .main
    @State private var detailCard: ManagedBankCard?
    @State private var frozenCards: Set<ManagedBankCard> = []
    @State private var showingPIN = false
    @State private var showingWalletConfirmation = false

    var body: some View {
        ZStack {
            AppScreenBackdrop()

            ScrollView {
                VStack(spacing: 26) {
                    AppPageTitle(title: "Cards")
                        .padding(.horizontal, 20)

                    cardCarousel
                    selectedCardSummary
                    cardActions
                    cardButtons
                }
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            AppNavigationTitleFontConfigurator()
                .frame(width: 0, height: 0)
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CardOrderView()
                } label: {
                    Label("Order card", systemImage: "plus")
                }
                .tint(palette.accent)
            }
        }
        .sheet(item: $detailCard) { card in
            CardDetailsSheet(card: card)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Card PIN", isPresented: $showingPIN) {
            Button("Done", role: .cancel) { }
        } message: {
            Text(verbatim: selectedCard?.pin ?? "••••")
        }
        .alert("Apple Wallet", isPresented: $showingWalletConfirmation) {
            Button("Continue") { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your card is ready to add to Apple Wallet.")
        }
        .sensoryFeedback(.selection, trigger: frozenCards)
    }

    @ViewBuilder
    private var cardButtons: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 10) {
                    walletButton
                    replaceCardButton
                }
            }
        } else {
            VStack(spacing: 10) {
                walletButton
                replaceCardButton
            }
        }
    }

    private var cardCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(ManagedBankCard.allCases) { card in
                    VisaCardPreview(finish: card.finish, orientation: .landscape)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            length * 0.90
                        }
                        .shadow(color: card.glowColor.opacity(0.28), radius: 24, y: 12)
                        .id(card)
                        .accessibilityLabel(card.accessibilityLabel)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(id: $selectedCard, anchor: .center)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    @ViewBuilder
    private var selectedCardSummary: some View {
        if let selectedCard {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text(selectedCard.title)
                        .appFont(.title3, weight: .bold)

                    Text(verbatim: "•••• \(selectedCard.lastFour)")
                        .appFont(.body, weight: .medium)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 7) {
                    ForEach(ManagedBankCard.allCases) { card in
                        Capsule()
                            .fill(selectedCard == card ? Color.primary : Color.secondary.opacity(0.35))
                            .frame(width: selectedCard == card ? 18 : 7, height: 7)
                    }
                }
                .animation(.smooth(duration: 0.22), value: selectedCard)
                .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var cardActions: some View {
        HStack(alignment: .top, spacing: 8) {
            CardManagementAction(
                title: "Show PIN",
                systemImage: "number.circle.fill"
            ) {
                showingPIN = true
            }

            CardManagementAction(
                title: "Card details",
                systemImage: "creditcard.fill"
            ) {
                detailCard = selectedCard
            }

            CardManagementAction(
                title: selectedCard.map(frozenCards.contains) == true ? "Unfreeze" : "Freeze card",
                systemImage: selectedCard.map(frozenCards.contains) == true ? "sun.max.fill" : "snowflake"
            ) {
                toggleFreeze()
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var walletButton: some View {
        let button = Button {
            showingWalletConfirmation = true
        } label: {
            Label("Add to Apple Wallet", systemImage: "wallet.pass.fill")
                .appFont(.body, weight: .bold)
                .foregroundStyle(palette.accentForeground)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.extraLarge)

        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(palette.accent)
                .padding(.horizontal, 20)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(palette.accent)
                .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var replaceCardButton: some View {
        let button = Button {
            detailCard = selectedCard
        } label: {
            Label("Manage card", systemImage: "slider.horizontal.3")
                .appFont(.body, weight: .bold)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)

        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .tint(.primary)
                .padding(.horizontal, 20)
        } else {
            button
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.primary)
                .padding(.horizontal, 20)
        }
    }

    private func toggleFreeze() {
        guard let selectedCard else { return }

        if frozenCards.contains(selectedCard) {
            frozenCards.remove(selectedCard)
        } else {
            frozenCards.insert(selectedCard)
        }
    }
}

private struct CardManagementAction: View {
    @Environment(\.appThemePalette) private var palette
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            actionButton

            Text(verbatim: title)
                .appFont(.footnote, weight: .bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 34, alignment: .top)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var actionButton: some View {
        let button = Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 48, height: 48)
        }
        .accessibilityLabel(Text(verbatim: title))

        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(palette.accent)
        } else {
            button
                .buttonStyle(.plain)
                .foregroundStyle(palette.accent)
                .background(palette.elevatedSurface, in: .circle)
        }
    }
}

private struct CardDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let card: ManagedBankCard

    var body: some View {
        NavigationStack {
            List {
                Section("Card") {
                    LabeledContent("Name", value: card.title)
                    LabeledContent("Type", value: card.type)
                    LabeledContent("Number", value: "•••• \(card.lastFour)")
                    LabeledContent("Currency", value: "AED")
                }

                Section("Controls") {
                    NavigationLink {
                        Text("Spending limits")
                            .navigationTitle("Spending limits")
                    } label: {
                        Label("Spending limits", systemImage: "gauge.with.dots.needle.50percent")
                    }
                    NavigationLink {
                        Text("Replace card")
                            .navigationTitle("Replace card")
                    } label: {
                        Label("Replace card", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
            }
            .appThemedScreenBackground()
            .navigationTitle("Card details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private enum ManagedBankCard: String, CaseIterable, Identifiable {
    case main
    case virtual

    var id: Self { self }

    var title: String {
        switch self {
        case .main: "Main"
        case .virtual: "Virtual"
        }
    }

    var type: String {
        switch self {
        case .main: "Physical card"
        case .virtual: "Virtual card"
        }
    }

    var lastFour: String {
        switch self {
        case .main: "4241"
        case .virtual: "2270"
        }
    }

    var pin: String {
        switch self {
        case .main: "4 2 4 1"
        case .virtual: "2 2 7 0"
        }
    }

    var finish: CardFinish {
        switch self {
        case .main: .sand
        case .virtual: .spaceGrey
        }
    }

    var glowColor: Color {
        finish.color
    }

    var accessibilityLabel: String {
        "\(title), \(type), ending in \(lastFour)"
    }
}
