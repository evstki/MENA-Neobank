import SwiftUI

struct AnimatedBlurBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    let accentColor: Color

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: reduceMotion
            )
        ) { timeline in
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        shader(
                            size: geometry.size,
                            date: timeline.date
                        )
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func shader(size: CGSize, date: Date) -> Shader {
        let time = reduceMotion
            ? 0
            : date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 4_096)

        var shader = ShaderLibrary.animatedBlurBackground(
            .float2(size),
            .float(time),
            .float(reduceMotion ? 0 : 1),
            .color(accentColor),
            .float(colorScheme == .dark ? 1 : 0)
        )

        shader.dithersColor = true
        return shader
    }
}

struct HomeAnimatedBackdrop: View {
    @Environment(\.appThemePalette) private var palette

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                AnimatedBlurBackground(accentColor: palette.accent)
                    .frame(height: geometry.size.height * 0.54)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white, location: 0.74),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                Spacer(minLength: 0)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
