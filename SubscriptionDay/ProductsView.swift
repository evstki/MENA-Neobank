import SwiftUI

struct ProductsView: View {
    @State private var selectedProduct: BankProduct?
    @State private var showingSearch = false
    @State private var showingCards = false
    @State private var showingCardOrder = false
    @State private var showingSubscriptionTracker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackdrop()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        AppPageHeading(
                            title: "Products",
                            description: "Everything to bank, protect and grow"
                        )
                        ProductsCardsSection(
                            viewAllAction: { showingCards = true },
                            action: open
                        )
                        ProductsBentoSection { product in
                            open(product)
                        }
                        ProductsCategoriesSection { product in
                            open(product)
                        }
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
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .appTopNavigationBar(searchTitle: "Search products") {
                showingSearch = true
            }
            .appTabBarHidden(showingCardOrder || showingCards)
            .navigationDestination(isPresented: $showingCardOrder) {
                CardOrderView()
            }
            .navigationDestination(isPresented: $showingCards) {
                CardsView()
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailSheet(product: product)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSubscriptionTracker) {
                HomeView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSearch) {
                ProductSearchSheet(products: ProductsContent.searchableProducts)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func open(_ product: BankProduct) {
        if product.id == ProductsContent.newCard.id {
            showingCardOrder = true
        } else if product.id == ProductsContent.subscriptions.id {
            showingSubscriptionTracker = true
        } else {
            selectedProduct = product
        }
    }
}

private struct ProductsCardsSection: View {
    let viewAllAction: () -> Void
    let action: (BankProduct) -> Void

    var body: some View {
        let radius = AppSurfaceMetrics.cornerRadius
        let content = VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Text("Cards")
                    .appFont(.title2, weight: .bold)

                Spacer(minLength: 0)

                Button(action: viewAllAction) {
                    HStack(spacing: 6) {
                        Text("View All")
                            .appFont(.subheadline, weight: .semibold)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View all cards")
            }

            HStack(alignment: .top, spacing: AppSurfaceMetrics.blockSpacing) {
                ForEach(ProductsContent.cards) { product in
                    ProductCardShelfItem(product: product) {
                        action(product)
                    }
                }
            }
        }
        .padding(18)
        .contentShape(.rect(cornerRadius: radius))

        content
            .appFloatingSurface(radius: radius)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 0.5)
            }
    }
}

private struct ProductCardShelfItem: View {
    @Environment(\.appThemePalette) private var palette
    let product: BankProduct
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                cardPreview

                VStack(spacing: 3) {
                    Text(product.title)
                        .appFont(.subheadline, weight: .bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if product.id != ProductsContent.newCard.id {
                        Text(product.subtitle)
                            .appFont(.footnote, weight: .medium)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(product.detail)
    }

    @ViewBuilder
    private var cardPreview: some View {
        if product.id == ProductsContent.newCard.id {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(palette.elevatedSurface)
                .overlay {
                    Image(systemName: "plus.viewfinder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .frame(width: 80, height: 50)
        } else {
            Image(
                product.id == ProductsContent.disposableCard.id
                    ? "small-mastercard"
                    : "small-visa-card"
            )
            .resizable()
            .renderingMode(.original)
            .frame(width: 80, height: 50)
            .clipShape(.rect(cornerRadius: 5))
        }
    }
}

private struct ProductsBentoSection: View {
    private let bentoHeight: CGFloat = 150
    private let bentoSpacing = AppSurfaceMetrics.blockSpacing
    let action: (BankProduct) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProductSectionTitle("Explore")

            bentoContent
                .frame(height: totalBentoHeight)
        }
    }

    private var bentoContent: some View {
        GeometryReader { proxy in
            let columnWidth = max((proxy.size.width - bentoSpacing) / 2, 0)

            VStack(spacing: bentoSpacing) {
                HStack(spacing: bentoSpacing) {
                    savingsCard
                        .frame(width: columnWidth)
                    compactCards(ProductsContent.investments, ProductsContent.insurance)
                        .frame(width: columnWidth)
                }

                HStack(spacing: bentoSpacing) {
                    compactCards(ProductsContent.jointAccounts, ProductsContent.esim)
                        .frame(width: columnWidth)
                    businessCard
                        .frame(width: columnWidth)
                }
            }
            .frame(width: proxy.size.width, height: totalBentoHeight, alignment: .topLeading)
        }
    }

    private var savingsCard: some View {
        ProductBentoCard(
            product: ProductsContent.savings,
            artworkSize: CGSize(width: 160, height: 124),
            artworkOffset: CGSize(width: 42, height: 24)
        ) {
            action(ProductsContent.savings)
        }
        .frame(height: bentoHeight)
    }

    private var businessCard: some View {
        ProductBentoCard(
            product: ProductsContent.business,
            artworkSize: CGSize(width: 154, height: 120),
            artworkOffset: CGSize(width: 40, height: 24)
        ) {
            action(ProductsContent.business)
        }
        .frame(height: bentoHeight)
    }

    private func compactCards(_ first: BankProduct, _ second: BankProduct) -> some View {
        VStack(spacing: bentoSpacing) {
            ProductBentoCard(
                product: first,
                isCompact: true,
                showsArtwork: first.artworkName != nil,
                artworkSize: first.id == ProductsContent.investments.id
                    ? CGSize(width: 96, height: 82)
                    : CGSize(width: 56, height: 52),
                artworkOffset: first.id == ProductsContent.investments.id
                    ? CGSize(width: 20, height: 0)
                    : CGSize(width: 16, height: 0),
                artworkAlignment: .trailing,
                contentTrailingPadding: first.artworkName == nil
                    ? nil
                    : first.id == ProductsContent.investments.id ? 68 : 44
            ) {
                action(first)
            }
            .frame(height: compactCardHeight)

            ProductBentoCard(
                product: second,
                isCompact: true,
                showsArtwork: second.artworkName != nil,
                mirrorsArtwork: second.id == ProductsContent.esim.id,
                artworkSize: second.id == ProductsContent.esim.id
                    ? CGSize(width: 96, height: 82)
                    : CGSize(width: 56, height: 52),
                artworkOffset: second.id == ProductsContent.esim.id
                    ? CGSize(width: 22, height: 0)
                    : CGSize(width: 16, height: 0),
                artworkAlignment: .trailing,
                contentTrailingPadding: second.artworkName == nil
                    ? nil
                    : second.id == ProductsContent.esim.id ? 68 : 44
            ) {
                action(second)
            }
            .frame(height: compactCardHeight)
        }
        .frame(maxWidth: .infinity, minHeight: bentoHeight, maxHeight: bentoHeight)
    }

    private var compactCardHeight: CGFloat {
        (bentoHeight - bentoSpacing) / 2
    }

    private var totalBentoHeight: CGFloat {
        bentoHeight * 2 + bentoSpacing
    }
}

private struct ProductBentoCard: View {
    let product: BankProduct
    var isCompact = false
    var showsArtwork = true
    var mirrorsArtwork = false
    var artworkSize: CGSize = .zero
    var artworkOffset: CGSize = .zero
    var artworkAlignment: Alignment = .bottomTrailing
    var contentLeadingPadding: CGFloat = 18
    var contentTrailingPadding: CGFloat?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appFloatingSurface(radius: radius)
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(.white.opacity(0.09), lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: radius))
        .accessibilityElement(children: .combine)
        .accessibilityHint(product.detail)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 6) {
            if isCompact {
                Spacer(minLength: 0)
            }

            Text(product.title)
                .appFont(isCompact ? .subheadline : .headline, weight: .bold)
                .foregroundStyle(.primary)
                .lineLimit(isCompact ? 1 : 2)

            Text(product.subtitle)
                .appFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
                .lineLimit(isCompact ? 2 : 3)
                .frame(
                    maxWidth: showsArtwork && !isCompact ? 132 : .infinity,
                    alignment: .leading
                )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, isCompact ? 12 : 18)
        .padding(.leading, contentLeadingPadding)
        .padding(.trailing, contentTrailingPadding ?? (isCompact ? 12 : 18))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: artworkAlignment) {

            if showsArtwork {
                ProductArtwork(product: product)
                    .frame(width: artworkSize.width, height: artworkSize.height)
                    .scaleEffect(x: mirrorsArtwork ? -1 : 1, y: 1)
                    .offset(x: artworkOffset.width, y: artworkOffset.height)
            }
        }
        .contentShape(.rect(cornerRadius: radius))
    }

    private var radius: CGFloat {
        AppSurfaceMetrics.cornerRadius
    }
}

private struct ProductArtwork: View {
    let product: BankProduct

    var body: some View {
        Group {
            if let artworkName = product.artworkName {
                BundledArtwork(name: artworkName)
            } else {
                Image(systemName: product.systemImage)
                    .font(.system(size: 38, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(product.tint)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ProductsCategoriesSection: View {
    let action: (BankProduct) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProductSectionTitle("All products")

            listContent
                .appFloatingSurface(radius: AppSurfaceMetrics.cornerRadius)
                .overlay {
                    RoundedRectangle(cornerRadius: AppSurfaceMetrics.cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.09), lineWidth: 0.5)
                }
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(ProductsContent.categories.enumerated()), id: \.element.id) { index, product in
                Button {
                    action(product)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: product.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(product.tint, in: .circle)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(product.title)
                                .appFont(.body, weight: .bold)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(product.subtitle)
                                .appFont(.subheadline, weight: .medium)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint(product.detail)

                if index < ProductsContent.categories.count - 1 {
                    Divider()
                        .padding(.leading, 74)
                        .padding(.trailing, 16)
                        .overlay(.white.opacity(0.06))
                }
            }
        }
    }
}

private struct ProductSectionTitle: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .appFont(.title2, weight: .bold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProductDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let product: BankProduct

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: product.systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(product.tint, in: .rect(cornerRadius: 24))

                Text(product.title)
                    .appFont(.title2, weight: .bold)
                    .multilineTextAlignment(.center)

                Text(product.detail)
                    .appFont(.body, weight: .medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("This product is ready to explore.")
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(.secondary)

                Button("Explore product") {
                    dismiss()
                }
                .appFont(.headline, weight: .bold)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(palette.accent)
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppScreenBackdrop())
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ProductSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let products: [BankProduct]
    @State private var query = ""
    @State private var selectedProduct: BankProduct?
    @State private var showingSubscriptionTracker = false

    var body: some View {
        NavigationStack {
            List(filteredProducts) { product in
                Button {
                    if product.id == ProductsContent.subscriptions.id {
                        showingSubscriptionTracker = true
                    } else {
                        selectedProduct = product
                    }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(product.title)
                                .appFont(.body, weight: .bold)
                                .foregroundStyle(.primary)

                            Text(product.subtitle)
                                .appFont(.subheadline, weight: .medium)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: product.systemImage)
                            .foregroundStyle(product.tint)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppScreenBackdrop())
            .searchable(text: $query, prompt: Text("Search products"))
            .navigationTitle("Search products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailSheet(product: product)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSubscriptionTracker) {
                HomeView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .tint(palette.accent)
    }

    private var filteredProducts: [BankProduct] {
        guard !query.isEmpty else { return products }
        return products.filter { product in
            product.searchTerms.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct BankProduct: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let detail: LocalizedStringResource
    let systemImage: String
    let tint: Color
    let artworkName: String?
    let searchTerms: String
    let cardColors: [Color]

    init(
        id: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        detail: LocalizedStringResource,
        systemImage: String,
        tint: Color,
        artworkName: String? = nil,
        searchTerms: String,
        cardColors: [Color] = [Color(red: 0.20, green: 0.24, blue: 0.36), Color(red: 0.08, green: 0.10, blue: 0.17)]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.systemImage = systemImage
        self.tint = tint
        self.artworkName = artworkName
        self.searchTerms = searchTerms
        self.cardColors = cardColors
    }
}

private enum ProductsContent {
    static let disposableCard = BankProduct(
        id: "disposable-card",
        title: "Main",
        subtitle: "••4241",
        detail: "Your main card for everyday spending.",
        systemImage: "creditcard.fill",
        tint: .pink,
        searchTerms: "disposable single use virtual card online purchase",
        cardColors: [Color(red: 0.95, green: 0.43, blue: 0.61), Color(red: 0.86, green: 0.30, blue: 0.52)]
    )

    static let virtualCard = BankProduct(
        id: "virtual-card",
        title: "Virtual",
        subtitle: "··2270",
        detail: "A separate virtual card for safer online purchases and subscriptions.",
        systemImage: "wave.3.right.circle.fill",
        tint: .cyan,
        searchTerms: "virtual digital card online subscriptions",
        cardColors: [Color(red: 0.59, green: 0.72, blue: 0.77), Color(red: 0.37, green: 0.48, blue: 0.57)]
    )

    static let newCard = BankProduct(
        id: "new-card",
        title: "Get card",
        subtitle: "Choose the right card for you",
        detail: "Compare debit, virtual and premium cards in one place.",
        systemImage: "plus",
        tint: .purple,
        searchTerms: "new get order debit virtual premium card",
        cardColors: [Color(red: 0.43, green: 0.31, blue: 0.70), Color(red: 0.20, green: 0.17, blue: 0.34)]
    )

    static let cards = [disposableCard, virtualCard, newCard]

    static let savings = BankProduct(
        id: "savings",
        title: "Savings",
        subtitle: "Earn more on your money",
        detail: "Set goals, earn interest and keep savings separate from everyday spending.",
        systemImage: "banknote.fill",
        tint: .yellow,
        artworkName: "safe",
        searchTerms: "savings vault interest goals deposit"
    )

    static let investments = BankProduct(
        id: "investments",
        title: "Investments",
        subtitle: "Start from $10",
        detail: "Build and manage a diversified portfolio of funds, ETFs and stocks.",
        systemImage: "chart.line.uptrend.xyaxis",
        tint: .yellow,
        artworkName: "coin",
        searchTerms: "investments portfolio funds etf stocks wealth"
    )

    static let insurance = BankProduct(
        id: "insurance",
        title: "Insurance",
        subtitle: "Protect what matters",
        detail: "Protection for your home, travel, health and everyday life.",
        systemImage: "shield.fill",
        tint: .green,
        artworkName: "shield",
        searchTerms: "insurance protection home travel health cover"
    )

    static let credit = BankProduct(
        id: "credit",
        title: "Credit & loans",
        subtitle: "Flexible money when needed",
        detail: "Explore transparent credit options with clear repayment schedules.",
        systemImage: "banknote.fill",
        tint: .orange,
        searchTerms: "credit loan borrow installment money"
    )

    static let travel = BankProduct(
        id: "travel",
        title: "Travel",
        subtitle: "Cards, FX and cover abroad",
        detail: "Pay in multiple currencies and stay protected when you travel.",
        systemImage: "airplane",
        tint: .cyan,
        searchTerms: "travel card foreign exchange fx insurance abroad"
    )

    static let subscriptions = BankProduct(
        id: "subscriptions",
        title: "Subscriptions",
        subtitle: "Manage recurring plans",
        detail: "Track recurring payments, upcoming renewals and monthly totals.",
        systemImage: "repeat.circle.fill",
        tint: .purple,
        searchTerms: "subscriptions recurring plans payments renewals"
    )

    static let premium = BankProduct(
        id: "premium",
        title: "Premium banking",
        subtitle: "More rewards and benefits",
        detail: "Unlock elevated rewards, travel benefits and priority support.",
        systemImage: "sparkles",
        tint: .pink,
        searchTerms: "premium membership rewards benefits support"
    )

    static let crypto = BankProduct(
        id: "crypto",
        title: "Crypto",
        subtitle: "Buy and sell digital assets",
        detail: "Explore supported cryptocurrencies with clear pricing and simple order controls.",
        systemImage: "bitcoinsign.circle.fill",
        tint: .purple,
        searchTerms: "crypto bitcoin digital assets buy sell"
    )

    static let jointAccounts = BankProduct(
        id: "joint-accounts",
        title: "Joint accounts",
        subtitle: "Spend and save together",
        detail: "Share an account for household spending, bills and common savings goals.",
        systemImage: "person.2.fill",
        tint: .teal,
        searchTerms: "joint shared account household couple family"
    )

    static let business = BankProduct(
        id: "business",
        title: "Business banking",
        subtitle: "Payments, cards and expenses",
        detail: "Manage business payments, cards and expenses from a dedicated account.",
        systemImage: "building.2.fill",
        tint: .blue,
        artworkName: "wallet",
        searchTerms: "business company payments cards expenses account"
    )

    static let esim = BankProduct(
        id: "esim",
        title: "eSIM",
        subtitle: "Mobile data",
        detail: "Buy and manage mobile data plans for travel without changing your physical SIM.",
        systemImage: "antenna.radiowaves.left.and.right",
        tint: .cyan,
        artworkName: "plane",
        searchTerms: "esim mobile data travel roaming connectivity"
    )

    static let categories = [
        credit,
        travel,
        subscriptions,
        premium,
        crypto,
        jointAccounts,
        business,
        esim
    ]

    static let searchableProducts = cards + [savings, investments, insurance] + categories
}

#Preview {
    ProductsView()
        .environment(\.appThemePalette, AppThemePalette(accent: .blue))
}
