import SwiftUI

struct CardOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedFinish = CardFinish.spaceGrey
    @State private var showingOrderConfirmation = false

    var body: some View {
        ZStack {
            AppScreenBackdrop(accentColor: selectedFinish.backdropAccent)

            VStack(spacing: 0) {
                ZStack {
                    VisaCardShadow(finish: selectedFinish)
                        .frame(width: 258.4)

                    TabView(selection: $selectedFinish) {
                        ForEach(CardFinish.allCases) { finish in
                            VisaCardPreview(finish: finish)
                                .frame(width: 258.4)
                                .tag(finish)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 440)

                finishPicker
                    .padding(.top, 24)

                Spacer(minLength: 16)

                orderContent
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .foregroundStyle(.white)
        .navigationTitle("Select design")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Card ordered", isPresented: $showingOrderConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text(
                String(
                    format: String(localized: "Your %@ card is being prepared."),
                    selectedFinish.title
                )
            )
        }
        .preferredColorScheme(.dark)
    }

    private var finishPicker: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(CardFinish.allCases) { finish in
                            CardFinishSwatch(
                                finish: finish,
                                isSelected: selectedFinish == finish
                            ) {
                                withAnimation(.snappy(duration: 0.28)) {
                                    selectedFinish = finish
                                }
                            }
                            .id(finish)
                        }
                    }
                    .padding(.horizontal, max((geometry.size.width - 40) / 2, 0))
                }
                .onChange(of: selectedFinish) { _, finish in
                    withAnimation(.snappy(duration: 0.28)) {
                        proxy.scrollTo(finish, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 54)
    }

    private var orderContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                finishTitle

                Text("Made from plastic with a subtle shimmer finish. Choose the colour that feels most like you.")
                    .appFont(size: 17, weight: .medium, relativeTo: .body)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 330)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 14)

            Button {
                showingOrderConfirmation = true
            } label: {
                Text("Proceed to details")
                    .appFont(.headline, weight: .bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(.white, in: .capsule)
        }
        .padding(.horizontal, 20)
    }

    private var finishTitle: some View {
        ZStack {
            if reduceMotion {
                finishTitleText
            } else {
                finishTitleText
                    .id(selectedFinish)
                    .transition(.blurReplace)
            }
        }
        .appFont(size: 29, weight: .bold, relativeTo: .title)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? nil : .smooth(duration: 0.24), value: selectedFinish)
    }

    private var finishTitleText: Text {
        Text(
            String(
                format: String(localized: "Premium · %@"),
                selectedFinish.title
            )
        )
    }
}

enum CardFinish: String, CaseIterable, Identifiable {
    case spaceGrey
    case blush
    case lavender
    case midnight
    case ocean
    case sage
    case sand

    var id: Self { self }

    var title: String {
        switch self {
        case .spaceGrey: String(localized: "Space Grey")
        case .blush: String(localized: "Blush")
        case .lavender: String(localized: "Lavender")
        case .midnight: String(localized: "Midnight")
        case .ocean: String(localized: "Ocean")
        case .sage: String(localized: "Sage")
        case .sand: String(localized: "Sand")
        }
    }

    var color: Color {
        switch self {
        case .spaceGrey: Color(red: 0.44, green: 0.45, blue: 0.48)
        case .blush: Color(red: 0.91, green: 0.67, blue: 0.66)
        case .lavender: Color(red: 0.61, green: 0.65, blue: 0.83)
        case .midnight: Color(red: 0.08, green: 0.11, blue: 0.19)
        case .ocean: Color(red: 0.13, green: 0.42, blue: 0.49)
        case .sage: Color(red: 0.45, green: 0.55, blue: 0.47)
        case .sand: Color(red: 0.76, green: 0.63, blue: 0.43)
        }
    }

    var backdropAccent: Color {
        switch self {
        case .spaceGrey: Color(red: 0.18, green: 0.29, blue: 0.70)
        case .blush: Color(red: 0.58, green: 0.22, blue: 0.40)
        case .lavender: Color(red: 0.30, green: 0.31, blue: 0.72)
        case .midnight: Color(red: 0.12, green: 0.18, blue: 0.52)
        case .ocean: Color(red: 0.08, green: 0.54, blue: 0.64)
        case .sage: Color(red: 0.22, green: 0.55, blue: 0.34)
        case .sand: Color(red: 0.72, green: 0.42, blue: 0.12)
        }
    }
}

private struct VisaCardShadow: View {
    let finish: CardFinish

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(finish.color)
                .shadow(color: finish.color.opacity(0.20), radius: 28, y: 14)

            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.black)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .aspectRatio(691.0 / 1096.0, contentMode: .fit)
        .animation(.easeInOut(duration: 0.28), value: finish)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum CardPreviewOrientation {
    case portrait
    case landscape

    var aspectRatio: CGFloat {
        switch self {
        case .portrait: 691.0 / 1096.0
        case .landscape: 1096.0 / 691.0
        }
    }
}

struct VisaCardPreview: View {
    let finish: CardFinish
    var orientation: CardPreviewOrientation = .portrait

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(finish.color)

            artwork
        }
        .aspectRatio(orientation.aspectRatio, contentMode: .fit)
        .compositingGroup()
        .clipShape(.rect(cornerRadius: 11))
        .animation(.easeInOut(duration: 0.28), value: finish)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                String(
                    format: String(localized: "Premium · %@"),
                    finish.title
                )
            )
        )
    }

    @ViewBuilder
    private var artwork: some View {
        switch orientation {
        case .portrait:
            Image("visa_card_overlay")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .allowsHitTesting(false)
        case .landscape:
            GeometryReader { geometry in
                Image("visa_card_overlay")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.height, height: geometry.size.width)
                    .rotationEffect(.degrees(-90))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct CardFinishSwatch: View {
    let finish: CardFinish
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(finish.color)
                .frame(width: 32, height: 32)
                .padding(4)
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(isSelected ? 0.86 : 0), lineWidth: 2)
                }
                .overlay {
                    Circle()
                        .strokeBorder(.black.opacity(isSelected ? 0.86 : 0), lineWidth: 3)
                        .padding(3)
                }
                .scaleEffect(isSelected ? 1 : 0.92)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(finish.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
