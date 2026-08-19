import SwiftUI

private let serviceAvatarPalette: [Color] = [
    Color(red: 0.31, green: 0.47, blue: 0.94),
    Color(red: 0.47, green: 0.33, blue: 0.88),
    Color(red: 0.78, green: 0.30, blue: 0.62),
    Color(red: 0.91, green: 0.36, blue: 0.32),
    Color(red: 0.89, green: 0.52, blue: 0.22),
    Color(red: 0.24, green: 0.64, blue: 0.42),
    Color(red: 0.18, green: 0.61, blue: 0.70),
    Color(red: 0.26, green: 0.52, blue: 0.78)
]

struct ServiceLogo: View {
    let service: ServiceBrand
    var size: CGFloat = 46

    var body: some View {
        Group {
            if let assetName = service.assetName, assetName.hasPrefix("circle_") {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else if service.isPopular {
                ZStack {
                    Circle().fill(service.logoFillColor)
                    if let assetName = service.assetName {
                        Circle()
                            .fill(.white)
                            .padding(size * 0.10)
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.16)
                    } else {
                        Image(systemName: service.fallbackSymbol)
                            .font(.system(size: size * 0.43, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            } else {
                ZStack {
                    Circle().fill(service.avatarColor)
                    Text(service.initial)
                        .font(.nunito(size: size * 0.44, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
        .accessibilityHidden(true)
    }
}

extension ServiceBrand {
    var logoFillColor: Color {
        switch id {
        case "netflix":
            Color(red: 0.90, green: 0.04, blue: 0.08)
        case "chatgpt":
            Color(red: 0.45, green: 0.67, blue: 0.61)
        case "apple-icloud":
            Color(red: 0.32, green: 0.66, blue: 0.96)
        case "apple-one":
            Color(red: 0.11, green: 0.11, blue: 0.12)
        default:
            Color(hex: fallbackColor)
        }
    }

    var initial: String {
        name.first.map { String($0).uppercased() } ?? "?"
    }

    var avatarColor: Color {
        let index = id.utf8.reduce(0) { partialResult, byte in
            (partialResult * 31 + Int(byte)) % serviceAvatarPalette.count
        }
        return serviceAvatarPalette[index]
    }

    var brandTint: Color {
        guard isPopular else { return avatarColor }

        switch id {
        case "netflix":
            return Color(red: 0.90, green: 0.10, blue: 0.15)
        case "cursor":
            return Color(red: 0.34, green: 0.42, blue: 0.55)
        case "apple-tv":
            return Color(red: 0.39, green: 0.42, blue: 0.52)
        default:
            break
        }

        switch fallbackColor.uppercased() {
        case "F4F4F4", "FFFFFF":
            switch category {
            case .entertainment: return Color(red: 0.56, green: 0.32, blue: 0.92)
            case .productivity: return Color(red: 0.28, green: 0.49, blue: 0.95)
            case .cloud: return Color(red: 0.20, green: 0.59, blue: 0.94)
            case .health: return Color(red: 0.24, green: 0.72, blue: 0.45)
            case .education: return Color(red: 0.94, green: 0.57, blue: 0.20)
            case .shopping: return Color(red: 0.93, green: 0.34, blue: 0.57)
            case .social: return Color(red: 0.63, green: 0.36, blue: 0.91)
            case .other: return Color(red: 0.22, green: 0.67, blue: 0.68)
            }
        default:
            return Color(hex: fallbackColor)
        }
    }
}

struct SDSectionTitle: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.sdRounded(13, weight: .medium))
            .tracking(1.7)
            .foregroundStyle(SDTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SDPanel<Content: View>: View {
    var radius: CGFloat = 10
    @ViewBuilder let content: Content

    init(radius: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .background(SDTheme.panel, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct SDDisclosureRow: View {
    let symbol: String
    let title: String
    var value: String? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: 26)
                Text(title)
                    .font(.sdRounded(15.5))
                Spacer(minLength: 8)
                if let value {
                    Text(value)
                        .font(.sdRounded(15.5))
                        .foregroundStyle(SDTheme.secondaryText)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SDTheme.secondaryText)
            }
            .foregroundStyle(SDTheme.primaryText)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SheetHandle: View {
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.42))
            .frame(width: 36, height: 5)
            .accessibilityHidden(true)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch cleaned.count {
        case 3:
            red = ((value >> 8) & 0xF) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        }
        self.init(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
