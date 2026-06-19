import SwiftUI

/// Full-screen RetroWheel layout.
///
/// The entire display becomes the retro music device:
///  ┌─────────────────────────────┐
///  │  top bar  (camera · grille) │
///  │  ┌───────────────────────┐  │
///  │  │  screen content area  │  │
///  │  └───────────────────────┘  │
///  │         touch wheel         │
///  └─────────────────────────────┘
struct RetroShellView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        GeometryReader { geo in
            let color = appSettings.shellColor

            ZStack(alignment: .top) {
                // ── Full-screen shell background ─────────────────────
                LinearGradient(
                    colors: color.bodyGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top decoration inside safe area
                    topBar(color: color)
                        .padding(.top, geo.safeAreaInsets.top + 6)

                    // Embedded screen area
                    screenPanel(geo: geo)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)

                    Spacer(minLength: 0)

                    // Touch wheel
                    TouchWheelView()
                        .frame(
                            width: wheelDiameter(geo),
                            height: wheelDiameter(geo)
                        )
                        .padding(.bottom, geo.safeAreaInsets.bottom + 10)
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Top bar

    private func topBar(color: ShellColor) -> some View {
        let tint = color.isLight ? Color.black.opacity(0.35) : Color.white.opacity(0.35)
        return HStack(spacing: 14) {
            // Front camera dot
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            // Earpiece grille
            Capsule()
                .fill(tint)
                .frame(width: 52, height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 24)
    }

    // MARK: - Screen panel

    private func screenPanel(geo: GeometryProxy) -> some View {
        let h = screenHeight(geo)
        return ZStack {
            // Screen bezel
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.55), radius: 8, y: 3)

            // Screen content
            ClassicMusicScreen()
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(height: h)
    }

    // MARK: - Layout math

    private func screenHeight(_ geo: GeometryProxy) -> CGFloat {
        let total   = geo.size.height
        let wheel   = wheelDiameter(geo)
        let topBar  = CGFloat(30)
        let topPad  = geo.safeAreaInsets.top + 6 + 8
        let botPad  = geo.safeAreaInsets.bottom + 10
        let spacing = CGFloat(12)    // spacer + padding
        return max(200, total - wheel - topBar - topPad - botPad - spacing)
    }

    private func wheelDiameter(_ geo: GeometryProxy) -> CGFloat {
        // Wheel takes ~38% of screen width, capped so it stays comfortable
        min(geo.size.width * 0.80, 300)
    }
}

#Preview {
    RetroShellView()
        .environmentObject(MusicPlayerViewModel())
        .environmentObject(PurchaseManager())
        .environmentObject(AppSettings())
}
