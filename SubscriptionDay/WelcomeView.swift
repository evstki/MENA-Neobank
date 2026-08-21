import SwiftUI
import simd

struct AppRootView: View {
    var body: some View {
        ContentView()
    }
}

private struct WelcomeView: View {
    @Environment(\.appAccentColor) private var accentColor

    let action: () -> Void

    private let services: [ServiceBrand] = [
        "YouTube Premium", "Spotify Premium", "Netflix", "ChatGPT",
        "iCloud+", "Apple Music", "Amazon Prime", "Disney+",
        "HBO Max", "Google One", "Microsoft 365", "PlayStation Plus",
        "Xbox Game Pass", "Figma Professional", "Canva Pro", "Claude",
        "Cursor", "Uber One", "Tinder", "NordVPN", "1Password",
        "Apple TV+", "Paramount+", "Hulu", "Peacock",
        "Crunchyroll", "Audible", "DashPass", "Notion Plus",
        "GitHub Pro", "Zoom", "LinkedIn Premium", "Apple One",
        "Amazon Prime Video", "Duolingo", "Dropbox", "Discord Nitro",
        "Reddit Premium", "Slack", "Telegram Premium"
    ].map { ServiceCatalog.service(named: $0) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppScreenBackdrop()

                VStack(spacing: 0) {
                    DraggableLogoSphere(services: services)
                        .frame(height: sphereHeight(in: geometry.size))
                        .padding(.top, max(6, geometry.safeAreaInsets.top * 0.20))

                    Spacer(minLength: 8)

                    WelcomeCopy()
                        .padding(.horizontal, 28)
                        .padding(.top, 2)
                        .padding(.bottom, 16)

                    Button(action: action) {
                        Text("Start Tracking")
                            .appFont(.headline, weight: .bold)
                            .foregroundStyle(palette.accentForeground)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.extraLarge)
                    .tint(palette.accent)
                    .foregroundStyle(palette.accentForeground)
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(18, geometry.safeAreaInsets.bottom + 10))
                }
            }
        }
        .environment(\.appThemePalette, palette)
        .tint(palette.accent)
    }

    private var palette: AppThemePalette {
        AppThemePalette(accent: accentColor)
    }

    private func sphereHeight(in size: CGSize) -> CGFloat {
        min(max(size.height * 0.51, 340), 455)
    }
}

private struct WelcomeCopy: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Every subscription. One clear calendar.")
                .appFont(.largeTitle, weight: .heavy)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text("See renewals and understand your spending—without ads, an account, or a paywall.")
                .appFont(.body, weight: .medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct DraggableLogoSphere: View {
    private struct Rotation: Equatable {
        var yaw: Double = 0
        var pitch: Double = -0.16
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation = Rotation()
    @State private var animationStart = Date.now
    @State private var dragTranslation = CGSize.zero

    let nodes: [LogoSphereNode]

    init(services: [ServiceBrand]) {
        nodes = LogoSphereNode.makeNodes(services: services)
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 30.0,
                    paused: reduceMotion
                )
            ) { timeline in
                let diameter = min(geometry.size.width, geometry.size.height)
                let automaticYaw = reduceMotion
                    ? 0
                    : timeline.date.timeIntervalSince(animationStart) * 0.095
                let activeRotation = Rotation(
                    yaw: rotation.yaw + automaticYaw + Double(dragTranslation.width) * 0.009,
                    pitch: clampedPitch(rotation.pitch - Double(dragTranslation.height) * 0.007)
                )

                LogoSphereStage(
                    nodes: nodes,
                    diameter: diameter,
                    rotationYaw: activeRotation.yaw,
                    rotationPitch: activeRotation.pitch
                )
                .frame(width: diameter, height: diameter)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .contentShape(Circle())
        .gesture(rotationGesture)
        .accessibilityHidden(true)
    }

    private var rotationGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dragTranslation = value.translation
                }
            }
            .onEnded { value in
                let releasedRotation = Rotation(
                    yaw: rotation.yaw + Double(value.translation.width) * 0.009,
                    pitch: clampedPitch(rotation.pitch - Double(value.translation.height) * 0.007)
                )
                let momentumWidth = reduceMotion
                    ? 0
                    : momentum(value.predictedEndTranslation.width, from: value.translation.width)
                let momentumHeight = reduceMotion
                    ? 0
                    : momentum(value.predictedEndTranslation.height, from: value.translation.height)
                let target = Rotation(
                    yaw: releasedRotation.yaw + Double(momentumWidth) * 0.009,
                    pitch: clampedPitch(releasedRotation.pitch - Double(momentumHeight) * 0.007)
                )

                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    rotation = releasedRotation
                    dragTranslation = .zero
                }

                if reduceMotion {
                    return
                } else {
                    withAnimation(.spring(duration: 0.28, bounce: 0.06)) {
                        rotation = target
                    }
                }
            }
    }

    private func momentum(_ predicted: CGFloat, from current: CGFloat) -> CGFloat {
        (predicted - current).clamped(to: -110...110) * 0.42
    }

    private func clampedPitch(_ pitch: Double) -> Double {
        pitch.clamped(to: -0.72...0.72)
    }

}

private struct LogoSphereStage: View {
    @Environment(\.appThemePalette) private var palette

    let nodes: [LogoSphereNode]
    let diameter: CGFloat
    let rotationYaw: Double
    let rotationPitch: Double

    var body: some View {
        let worldRotation = worldRotationMatrix

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            palette.accent.opacity(0.20),
                            palette.accent.opacity(0.055),
                            .clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: diameter * 0.48
                    )
                )
                .blur(radius: 18)
                .frame(width: diameter * 0.98, height: diameter * 0.98)

            ForEach(nodes) { node in
                let projection = project(node, worldRotation: worldRotation)

                SphereLogoNodeView(
                    service: node.service,
                    projection: projection
                )
            }
        }
        .accessibilityHidden(true)
    }

    private var worldRotationMatrix: simd_double3x3 {
        let cosYaw = cos(rotationYaw)
        let sinYaw = sin(rotationYaw)
        let cosPitch = cos(rotationPitch)
        let sinPitch = sin(rotationPitch)

        let yaw = simd_double3x3(
            SIMD3(cosYaw, 0, -sinYaw),
            SIMD3(0, 1, 0),
            SIMD3(sinYaw, 0, cosYaw)
        )
        let pitch = simd_double3x3(
            SIMD3(1, 0, 0),
            SIMD3(0, cosPitch, sinPitch),
            SIMD3(0, -sinPitch, cosPitch)
        )

        return pitch * yaw
    }

    private func project(
        _ node: LogoSphereNode,
        worldRotation: simd_double3x3
    ) -> LogoProjection {
        let center = worldRotation * node.normal
        let orientation = worldRotation * node.localOrientation
        let quaternion = simd_quatd(orientation).normalized
        let angle = quaternion.angle
        let axis = angle < 0.000_001
            ? SIMD3<Double>(0, 0, 1)
            : quaternion.axis

        let cameraScale = SphereProjection.cameraDistance
            / (SphereProjection.cameraDistance - center.z)
        let radius = Double(diameter) * SphereProjection.radiusFactor
        let depth = (center.z + 1) / 2

        return LogoProjection(
            x: CGFloat(center.x * radius * cameraScale),
            y: CGFloat(center.y * radius * cameraScale),
            scale: CGFloat(cameraScale),
            opacity: 0.32 + depth * 0.68,
            rotationAngle: angle,
            rotationAxis: axis,
            perspective: CGFloat(1 / SphereProjection.cameraDistance),
            zIndex: center.z
        )
    }
}

private struct SphereLogoNodeView: View {
    let service: ServiceBrand
    let projection: LogoProjection

    var body: some View {
        ServiceLogo(
            service: service,
            size: SphereProjection.logoSize,
            showsShadow: false
        )
            .scaleEffect(projection.scale)
            .rotation3DEffect(
                .radians(projection.rotationAngle),
                axis: (
                    x: CGFloat(projection.rotationAxis.x),
                    y: CGFloat(projection.rotationAxis.y),
                    z: CGFloat(projection.rotationAxis.z)
                ),
                perspective: projection.perspective
            )
            .opacity(projection.opacity)
            .offset(x: projection.x, y: projection.y)
            .zIndex(projection.zIndex)
    }
}

private struct LogoSphereNode: Identifiable {
    let service: ServiceBrand
    let normal: SIMD3<Double>
    let localOrientation: simd_double3x3
    var id: String { service.id }

    static func makeNodes(services: [ServiceBrand]) -> [LogoSphereNode] {
        guard services.count > 1 else { return [] }
        let goldenAngle = Double.pi * (3 - sqrt(5.0))
        let count = Double(services.count)

        return services.enumerated().map { index, service in
            // Sample the center of each equal-area band instead of placing
            // nodes directly on the poles, which visually bunches neighbors.
            let y = 1 - (2 * (Double(index) + 0.5) / count)
            let horizontalRadius = sqrt(max(0, 1 - y * y))
            let theta = goldenAngle * Double(index)

            let normal = SIMD3<Double>(
                cos(theta) * horizontalRadius,
                y,
                sin(theta) * horizontalRadius
            )
            let referenceDown = abs(normal.y) > 0.98
                ? SIMD3<Double>(0, 0, normal.y > 0 ? -1 : 1)
                : SIMD3<Double>(0, 1, 0)
            let down = simd_normalize(
                referenceDown - normal * simd_dot(referenceDown, normal)
            )
            let right = simd_normalize(simd_cross(down, normal))
            let correctedDown = simd_normalize(simd_cross(normal, right))

            return LogoSphereNode(
                service: service,
                normal: normal,
                localOrientation: simd_double3x3(right, correctedDown, normal)
            )
        }
    }
}

private enum SphereProjection {
    static let cameraDistance = 4.2
    static let radiusFactor = 0.513
    static let logoSize: CGFloat = 55
}

private struct LogoProjection {
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    let opacity: Double
    let rotationAngle: Double
    let rotationAxis: SIMD3<Double>
    let perspective: CGFloat
    let zIndex: Double
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    WelcomeView(action: {})
        .environment(\.appAccentColor, .purple)
        .preferredColorScheme(.dark)
}
