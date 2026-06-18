import SwiftUI
import AudioToolbox

/// Interactive circular control at the bottom of the RetroWheel screen.
///
/// - Center button: play / pause (or select highlighted menu item)
/// - Top arc tap: back / menu
/// - Right arc tap: next track
/// - Left arc tap: previous track
/// - Bottom arc tap: play / pause (duplicate)
/// - Rotary drag: scroll menus (with haptic + optional click sound)
struct TouchWheelView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var appSettings: AppSettings

    // Accumulated rotation angle used to fire discrete scroll steps
    @State private var lastAngle: Double? = nil
    @State private var accumulatedDelta: Double = 0

    // Degrees of drag required for one scroll step, divided by sensitivity
    private var stepThreshold: Double { 18.0 / appSettings.wheelSensitivity }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                outerRing(size: size)
                innerDisc(size: size)
                centerButton(size: size)
                directionLabels(size: size)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Sub-views

    private func outerRing(size: CGFloat) -> some View {
        let color = appSettings.shellColor
        return Circle()
            .fill(
                LinearGradient(
                    colors: [
                        color.bodyGradient[0].opacity(0.75),
                        color.bodyGradient[1].opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(color.isLight ? 0.2 : 0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
            .frame(width: size, height: size)
            // Rotary drag for scrolling
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        handleDrag(value: value, size: size)
                    }
                    .onEnded { _ in
                        lastAngle = nil
                        accumulatedDelta = 0
                    }
            )
            // Tap on the ring — detect quadrant
            .onTapGesture { /* handled by overlay buttons */ }
    }

    private func innerDisc(size: CGFloat) -> some View {
        let color = appSettings.shellColor
        return Circle()
            .fill(
                LinearGradient(
                    colors: [
                        color.bodyGradient[1],
                        color.bodyGradient[0].opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.60, height: size * 0.60)
            // Transparent quadrant tap targets on the ring area
            .overlay(alignment: .top)    { arcButton(size: size * 0.60, action: backTapped)    }
            .overlay(alignment: .bottom) { arcButton(size: size * 0.60, action: playPauseTapped) }
            .overlay(alignment: .leading) { arcButton(size: size * 0.60, action: prevTapped)   }
            .overlay(alignment: .trailing){ arcButton(size: size * 0.60, action: nextTapped)   }
    }

    private func arcButton(size: CGFloat, action: @escaping () -> Void) -> some View {
        Color.clear
            .frame(width: size * 0.50, height: size * 0.32)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private func centerButton(size: CGFloat) -> some View {
        let color = appSettings.shellColor
        return Button(action: centerTapped) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.homeButtonColor.opacity(0.9), color.homeButtonColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.30, height: size * 0.30)
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func directionLabels(size: CGFloat) -> some View {
        let light = appSettings.shellColor.isLight
        let labelColor = light ? Color.black.opacity(0.45) : Color.white.opacity(0.45)
        let f = Font.system(size: size * 0.058, weight: .medium)
        return ZStack {
            Text("MENU")
                .font(f).foregroundStyle(labelColor)
                .offset(y: -(size * 0.36))
            Text("◀")
                .font(f).foregroundStyle(labelColor)
                .offset(x: -(size * 0.36))
            Text("▶")
                .font(f).foregroundStyle(labelColor)
                .offset(x: size * 0.36)
            Text("▶▶")
                .font(.system(size: size * 0.048, weight: .medium))
                .foregroundStyle(labelColor)
                .offset(y: size * 0.37)
        }
    }

    // MARK: - Gesture handling

    private func handleDrag(value: DragGesture.Value, size: CGFloat) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let dx = value.location.x - center.x
        let dy = value.location.y - center.y
        let radius = sqrt(dx * dx + dy * dy)

        // Only respond to touches on the ring, not the center disc
        let innerRadius = size * 0.30
        let outerRadius = size / 2
        guard radius > innerRadius && radius < outerRadius else {
            lastAngle = nil
            return
        }

        let angle = atan2(dy, dx) * (180 / .pi)   // -180 to +180 degrees

        if let prev = lastAngle {
            var delta = angle - prev
            // Handle 180°/-180° wrap
            if delta > 180  { delta -= 360 }
            if delta < -180 { delta += 360 }
            accumulatedDelta += delta
        }
        lastAngle = angle

        // Fire a step whenever accumulated delta crosses the threshold
        while accumulatedDelta >= stepThreshold {
            accumulatedDelta -= stepThreshold
            playerVM.wheelScrollDown()
            fireWheelFeedback()
        }
        while accumulatedDelta <= -stepThreshold {
            accumulatedDelta += stepThreshold
            playerVM.wheelScrollUp()
            fireWheelFeedback()
        }
    }

    // MARK: - Button actions

    private func centerTapped() {
        playerVM.wheelSelect()
        fireTapFeedback()
    }

    private func backTapped() {
        playerVM.wheelBack()
        fireTapFeedback()
    }

    private func nextTapped() {
        playerVM.skipForward()
        fireTapFeedback()
    }

    private func prevTapped() {
        playerVM.skipBack()
        fireTapFeedback()
    }

    private func playPauseTapped() {
        playerVM.togglePlayPause()
        fireTapFeedback()
    }

    // MARK: - Feedback

    private func fireWheelFeedback() {
        if appSettings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if appSettings.clickSoundsEnabled {
            AudioServicesPlaySystemSound(1519)   // UIKit peek sound — subtle
        }
    }

    private func fireTapFeedback() {
        if appSettings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        if appSettings.clickSoundsEnabled {
            AudioServicesPlaySystemSound(1520)   // UIKit pop sound
        }
    }
}

#Preview {
    TouchWheelView()
        .environmentObject(MusicPlayerViewModel())
        .environmentObject(AppSettings())
        .frame(width: 300, height: 300)
        .background(Color.black)
}
