import SwiftUI

/// Full-screen RetroWheel device shell rendered entirely in SwiftUI.
/// The virtual screen content lives inside the cutout region.
struct RetroShellView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @State private var homeButtonPressed = false

    // Classic handheld device proportions (4-inch ratio, 1136×640)
    private let deviceAspect: CGFloat = 1136 / 640

    var body: some View {
        GeometryReader { geo in
            let deviceWidth  = min(geo.size.width * 0.88, 375)
            let deviceHeight = deviceWidth  * deviceAspect
            let screenWidth  = deviceWidth  * 0.865
            let screenHeight = screenWidth  * deviceAspect * 0.86
            let cornerRadius = deviceWidth  * 0.13
            let color        = playerVM.selectedShellColor

            ZStack {
                // ── Body ──────────────────────────────────────────────────
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: color.bodyGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: deviceWidth, height: deviceHeight)
                    .shadow(color: .black.opacity(0.6), radius: 24, y: 12)

                // Sheen highlight
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(color.isLight ? 0.25 : 0.12),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: deviceWidth, height: deviceHeight)

                VStack(spacing: 0) {
                    // ── Top decoration: front camera + earpiece ────────────
                    topDecor(width: deviceWidth, color: color)
                        .frame(height: deviceHeight * 0.085)

                    // ── Virtual screen ─────────────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black)
                            .frame(width: screenWidth, height: screenHeight)

                        ClassicMusicScreen()
                            .frame(width: screenWidth, height: screenHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(width: screenWidth, height: screenHeight)

                    Spacer()

                    // ── Home button ────────────────────────────────────────
                    homeButton(color: color, deviceWidth: deviceWidth)
                        .padding(.bottom, deviceHeight * 0.035)
                }
                .frame(width: deviceWidth, height: deviceHeight)

                // ── Side buttons ───────────────────────────────────────────
                sideButtons(deviceWidth: deviceWidth,
                            deviceHeight: deviceHeight,
                            color: color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Sub-components

    @ViewBuilder
    private func topDecor(width: CGFloat, color: ShellColor) -> some View {
        let tint = color.isLight ? Color.black.opacity(0.4) : Color.white.opacity(0.4)
        HStack(spacing: width * 0.06) {
            Circle()
                .fill(tint)
                .frame(width: width * 0.04, height: width * 0.04)
            Capsule()
                .fill(tint)
                .frame(width: width * 0.22, height: width * 0.025)
        }
    }

    @ViewBuilder
    private func homeButton(color: ShellColor, deviceWidth: CGFloat) -> some View {
        let size = deviceWidth * 0.155
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                homeButtonPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { homeButtonPressed = false }
                playerVM.activeSection = .music
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.homeButtonColor.opacity(0.9),
                                     color.homeButtonColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)

                RoundedRectangle(cornerRadius: size * 0.08)
                    .stroke(
                        color.isLight ? Color.black.opacity(0.2) : Color.white.opacity(0.25),
                        lineWidth: size * 0.06
                    )
                    .frame(width: size * 0.4, height: size * 0.4)
            }
            .scaleEffect(homeButtonPressed ? 0.88 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sideButtons(deviceWidth: CGFloat,
                              deviceHeight: CGFloat,
                              color: ShellColor) -> some View {
        let btnW: CGFloat = deviceWidth * 0.028
        let accent = color.isLight
            ? color.bodyGradient[0].opacity(0.6)
            : Color.white.opacity(0.25)

        sideButton(width: btnW, height: deviceHeight * 0.07, color: accent)
            .offset(x: -(deviceWidth / 2 + btnW / 2), y: -deviceHeight * 0.16)

        sideButton(width: btnW, height: deviceHeight * 0.065, color: accent)
            .offset(x: -(deviceWidth / 2 + btnW / 2), y: -deviceHeight * 0.07)

        sideButton(width: btnW, height: deviceHeight * 0.055, color: accent)
            .offset(x: deviceWidth / 2 + btnW / 2, y: -deviceHeight * 0.40)
    }

    private func sideButton(width: CGFloat, height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: width * 0.4)
            .fill(color)
            .frame(width: width, height: height)
    }
}

#Preview {
    RetroShellView()
        .environmentObject(MusicPlayerViewModel())
        .background(Color.black)
}
