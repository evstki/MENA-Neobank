import SwiftUI
import UIKit

struct PayView: View {
    @State private var selectedEntry: PayHubEntry?
    @State private var showingSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackdrop()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        AppPageHeading(
                            title: "Services",
                            description: "Everything for the city, in one place"
                        )
                        PayBentoActionsSection { entry in
                            selectedEntry = entry
                        }
                        PayRewardsCard {
                            selectedEntry = PayHubContent.rewards
                        }
                        PayServicesSection { entry in
                            selectedEntry = entry
                        }
                        PayRecentPaymentsSection { entry in
                            selectedEntry = entry
                        }
                        PayPromotionsSection { entry in
                            selectedEntry = entry
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
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.large)
            .appTopNavigationBar(searchTitle: "Search services") {
                showingSearch = true
            }
            .sheet(item: $selectedEntry) { entry in
                PayHubEntrySheet(entry: entry)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSearch) {
                PayServiceSearchSheet(entries: PayHubContent.searchableEntries)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct PayRewardsCard: View {
    @Environment(\.appThemePalette) private var palette
    let action: () -> Void

    private static let flowerArtwork: UIImage? = {
        guard let url = Bundle.main.url(forResource: "V-flower", withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }()

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Label("City Rewards", systemImage: "star.circle.fill")
                    .appFont(.headline, weight: .bold)

                Text("3,420 points")
                    .appFont(size: 26, weight: .heavy, relativeTo: .title)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("Earn points on city payments and everyday spending")
                    .appFont(.footnote, weight: .medium)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 230, alignment: .leading)
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {

                if let flowerArtwork = Self.flowerArtwork {
                    Image(uiImage: flowerArtwork)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .offset(x: 24)
                        .accessibilityHidden(true)
                }
            }
            .appFloatingSurface(radius: 26)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 0.7)
            }
            .clipShape(.rect(cornerRadius: 26))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct PayBentoActionsSection: View {
    private let blockSpacing: CGFloat = 12
    private let actionColumns = [
        GridItem(.flexible(minimum: 0), spacing: 12, alignment: .top),
        GridItem(.flexible(minimum: 0), spacing: 0, alignment: .top)
    ]
    let action: (PayHubEntry) -> Void

    var body: some View {
        bentoContent
    }

    private var bentoContent: some View {
        VStack(alignment: .leading, spacing: blockSpacing) {
            LazyVGrid(columns: actionColumns, alignment: .leading, spacing: blockSpacing) {
                PayBentoPrimaryButton(entry: PayHubContent.scanAction) {
                    action(PayHubContent.scanAction)
                }
                .frame(height: 220)

                VStack(spacing: blockSpacing) {
                    PayBentoCompactButton(entry: PayHubContent.sendAction) {
                        action(PayHubContent.sendAction)
                    }

                    PayBentoCompactButton(entry: PayHubContent.billsAction) {
                        action(PayHubContent.billsAction)
                    }
                }
                .frame(height: 220)
            }
        }
    }
}

private struct PayBentoPrimaryButton: View {
    let entry: PayHubEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityHint(entry.subtitle)
    }

    @ViewBuilder
    private var cardContent: some View {
        let content = VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .appFont(.headline, weight: .bold)
                .foregroundStyle(.primary)

            Text(entry.subtitle)
                .appFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomTrailing) {
            PayBentoArtwork(entry: entry)
                .frame(width: 190, height: 148)
                .offset(x: 38, y: 18)
        }
        .contentShape(.rect(cornerRadius: 26))

        content
            .clipShape(.rect(cornerRadius: 26))
            .appFloatingSurface(radius: 26)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 0.5)
            }
    }
}

private struct PayBentoCompactButton: View {
    let entry: PayHubEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityHint(entry.subtitle)
    }

    @ViewBuilder
    private var cardContent: some View {
        let content = VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .appFont(.subheadline, weight: .bold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(entry.subtitle)
                .appFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: 88, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomTrailing) {
            PayBentoArtwork(entry: entry)
                .frame(width: 104, height: 80)
                .offset(x: 72, y: 10)
        }
        .contentShape(.rect(cornerRadius: 24))

        content
            .clipShape(.rect(cornerRadius: 24))
            .appFloatingSurface(radius: 24)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 0.5)
            }
    }
}

private struct PayBentoArtwork: View {
    let entry: PayHubEntry

    var body: some View {
        Group {
            if let artworkName = entry.artworkName {
                BundledArtwork(name: artworkName)
            } else {
                Image(systemName: entry.systemImage)
                    .font(.system(size: 38, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(entry.tint)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PayPromotionsSection: View {
    let action: (PayHubEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PaySectionTitle("Promotions")

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(PayHubContent.promotions) { entry in
                        PayPromotionCard(entry: entry) {
                            action(entry)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
}

private struct PayPromotionCard: View {
    let entry: PayHubEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Image(systemName: entry.systemImage)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(entry.tint)
                        .frame(width: 52, height: 52)
                        .background(entry.tint.opacity(0.14), in: .rect(cornerRadius: 16))

                    Spacer(minLength: 20)

                    Text(entry.badge ?? "")
                        .appFont(.footnote, weight: .bold)
                        .foregroundStyle(entry.tint)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(entry.tint.opacity(0.14), in: .capsule)
                }

                Text(entry.title)
                    .appFont(.title3, weight: .bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)

                Text(entry.subtitle)
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1, reservesSpace: true)
            }
            .padding(18)
            .frame(width: 280, alignment: .leading)
            .appFloatingSurface(radius: 22)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 0.6)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PayServicesSection: View {
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    let action: (PayHubEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PaySectionTitle("City & government services")

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(PayHubContent.services) { entry in
                    PayServiceCard(entry: entry) {
                        action(entry)
                    }
                }
            }
        }
    }
}

private struct PayServiceCard: View {
    let entry: PayHubEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: entry.systemImage)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.12), in: .rect(cornerRadius: 14))

                Text(entry.title)
                    .appFont(.headline, weight: .bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text(entry.subtitle)
                    .appFont(.footnote, weight: .medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
            .appFloatingSurface(radius: 22)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 0.6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct PayRecentPaymentsSection: View {
    @Environment(\.appThemePalette) private var palette
    let action: (PayHubEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaySectionTitle("Recent payments")
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)

            ForEach(PayHubContent.recentPayments) { entry in
                Button {
                    action(entry)
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: entry.systemImage)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(entry.tint.opacity(0.74), in: .circle)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title)
                                .appFont(.body, weight: .bold)
                                .foregroundStyle(.primary)

                            Text(entry.subtitle)
                                .appFont(.subheadline, weight: .medium)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)

                        Text("Pay again")
                            .appFont(.subheadline, weight: .bold)
                            .foregroundStyle(palette.accent)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                if entry.id != PayHubContent.recentPayments.last?.id {
                    Divider()
                        .padding(.leading, 73)
                }
            }
        }
        .padding(.bottom, 8)
        .appFloatingSurface(radius: 24)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 0.5)
        }
    }
}

private struct PaySectionTitle: View {
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

private struct PayHubEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let entry: PayHubEntry

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: entry.systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(entry.tint, in: .rect(cornerRadius: 24))

                Text(entry.title)
                    .appFont(.title2, weight: .bold)
                    .multilineTextAlignment(.center)

                Text(entry.subtitle)
                    .appFont(.body, weight: .medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("This service is ready to connect.")
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(.secondary)

                Button("Continue") {
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
            .navigationTitle("Pay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct PayServiceSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appThemePalette) private var palette
    let entries: [PayHubEntry]
    @State private var query = ""
    @State private var selectedEntry: PayHubEntry?

    var body: some View {
        NavigationStack {
            List(filteredEntries) { entry in
                Button {
                    selectedEntry = entry
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title)
                                .appFont(.body, weight: .bold)
                                .foregroundStyle(.primary)

                            Text(entry.subtitle)
                                .appFont(.subheadline, weight: .medium)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: entry.systemImage)
                            .foregroundStyle(entry.tint)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppScreenBackdrop())
            .searchable(text: $query, prompt: Text("Search services"))
            .navigationTitle("Search services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                PayHubEntrySheet(entry: entry)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .tint(palette.accent)
    }

    private var filteredEntries: [PayHubEntry] {
        guard !query.isEmpty else { return entries }
        return entries.filter { entry in
            entry.searchTerms.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct PayHubEntry: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let systemImage: String
    let tint: Color
    let artworkName: String?
    let badge: LocalizedStringResource?
    let searchTerms: String

    init(
        id: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        systemImage: String,
        tint: Color,
        artworkName: String? = nil,
        badge: LocalizedStringResource? = nil,
        searchTerms: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.artworkName = artworkName
        self.badge = badge
        self.searchTerms = searchTerms
    }
}

private enum PayHubContent {
    static let rewards = PayHubEntry(
        id: "rewards",
        title: "City Rewards",
        subtitle: "Earn points on city payments and everyday spending",
        systemImage: "giftcard.fill",
        tint: .yellow,
        searchTerms: "rewards points cashback"
    )

    static let scanAction = PayHubEntry(
        id: "scan",
        title: "Scan & pay",
        subtitle: "Pay any supported QR code",
        systemImage: "qrcode.viewfinder",
        tint: .blue,
        artworkName: "card",
        searchTerms: "scan qr pay"
    )

    static let sendAction = PayHubEntry(
        id: "send",
        title: "Send money",
        subtitle: "Transfer to another person",
        systemImage: "arrow.up.right",
        tint: .teal,
        artworkName: "two cards",
        searchTerms: "send transfer person"
    )

    static let billsAction = PayHubEntry(
        id: "bills",
        title: "Pay bills",
        subtitle: "Household and city bills",
        systemImage: "doc.text.fill",
        tint: .orange,
        artworkName: "wallet",
        searchTerms: "bill utilities payment"
    )

    static let paymentShortcuts: [PayHubEntry] = [
        PayHubEntry(
            id: "top-up",
            title: "Top up",
            subtitle: "Add credit to a mobile number",
            systemImage: "iphone.gen3.radiowaves.left.and.right",
            tint: .purple,
            searchTerms: "top up mobile phone"
        ),
        PayHubEntry(
            id: "request-money",
            title: "Request",
            subtitle: "Create a payment request",
            systemImage: "arrow.down.left",
            tint: .green,
            searchTerms: "request money payment link"
        ),
        PayHubEntry(
            id: "split-bill",
            title: "Split bill",
            subtitle: "Share a payment with friends",
            systemImage: "person.2.fill",
            tint: .pink,
            searchTerms: "split bill friends share"
        ),
        PayHubEntry(
            id: "payment-history",
            title: "History",
            subtitle: "See all previous payments",
            systemImage: "clock.arrow.circlepath",
            tint: .cyan,
            searchTerms: "payment history previous activity"
        )
    ]

    static let quickActions = [scanAction, sendAction, billsAction] + paymentShortcuts

    static let promotions: [PayHubEntry] = [
        PayHubEntry(
            id: "transport-promo",
            title: "20% back on metro and taxis",
            subtitle: "Valid until 31 August",
            systemImage: "tram.fill",
            tint: .cyan,
            badge: "20% back",
            searchTerms: "metro taxi transport promo cashback"
        ),
        PayHubEntry(
            id: "utilities-promo",
            title: "2× points on utility bills",
            subtitle: "This week only",
            systemImage: "bolt.fill",
            tint: .yellow,
            badge: "2× points",
            searchTerms: "utilities bills points promo"
        ),
        PayHubEntry(
            id: "parking-promo",
            title: "25 AED off city parking",
            subtitle: "First three payments",
            systemImage: "parkingsign.circle.fill",
            tint: .green,
            badge: "25 AED",
            searchTerms: "parking discount promo"
        )
    ]

    static let services: [PayHubEntry] = [
        PayHubEntry(
            id: "traffic",
            title: "Traffic & parking",
            subtitle: "Fines, parking and road tolls",
            systemImage: "car.fill",
            tint: .blue,
            searchTerms: "traffic parking fines tolls salik car"
        ),
        PayHubEntry(
            id: "transport",
            title: "Public transport",
            subtitle: "Metro, bus and taxi services",
            systemImage: "tram.fill",
            tint: .cyan,
            searchTerms: "metro bus taxi public transport"
        ),
        PayHubEntry(
            id: "government",
            title: "Government services",
            subtitle: "Visa, Emirates ID and permits",
            systemImage: "building.columns.fill",
            tint: .orange,
            searchTerms: "government visa emirates id permits"
        ),
        PayHubEntry(
            id: "utilities",
            title: "Utilities",
            subtitle: "Electricity, water and gas",
            systemImage: "bolt.fill",
            tint: .yellow,
            searchTerms: "electricity water gas dewa utilities"
        ),
        PayHubEntry(
            id: "telecom",
            title: "Mobile & internet",
            subtitle: "Phone, data and home internet",
            systemImage: "antenna.radiowaves.left.and.right",
            tint: .purple,
            searchTerms: "mobile internet phone data telecom du etisalat"
        ),
        PayHubEntry(
            id: "housing",
            title: "Home & housing",
            subtitle: "Rent, housing fees and services",
            systemImage: "house.fill",
            tint: .pink,
            searchTerms: "home housing rent fees ejari"
        ),
        PayHubEntry(
            id: "education",
            title: "Education",
            subtitle: "Schools, universities and tuition",
            systemImage: "graduationcap.fill",
            tint: .indigo,
            searchTerms: "education school university tuition"
        ),
        PayHubEntry(
            id: "health",
            title: "Health",
            subtitle: "Appointments, insurance and fees",
            systemImage: "cross.case.fill",
            tint: .green,
            searchTerms: "health appointment insurance medical"
        )
    ]

    static let recentPayments: [PayHubEntry] = [
        PayHubEntry(
            id: "dewa",
            title: "DEWA",
            subtitle: "Utilities",
            systemImage: "bolt.fill",
            tint: .yellow,
            searchTerms: "dewa utilities electricity water"
        ),
        PayHubEntry(
            id: "salik",
            title: "Salik",
            subtitle: "Road toll",
            systemImage: "car.fill",
            tint: .blue,
            searchTerms: "salik road toll car"
        ),
        PayHubEntry(
            id: "du-mobile",
            title: "du Mobile",
            subtitle: "Mobile bill",
            systemImage: "antenna.radiowaves.left.and.right",
            tint: .purple,
            searchTerms: "du mobile phone bill telecom"
        )
    ]

    static let searchableEntries = quickActions + services + recentPayments
}

#Preview {
    PayView()
        .environment(\.appThemePalette, AppThemePalette(accent: .blue))
}
