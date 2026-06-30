import SwiftUI
import AudioToolbox

/// Interactive circular control at the bottom of the RetroWheel screen.
///
/// All gestures (rotary drag + directional taps) are captured by a single
/// .simultaneousGesture on the outer ZStack container, keyed to a named
/// coordinate space.  This avoids the layer-ordering problem where child
/// views (innerDisc overlays, directionLabels) intercept touches before
/// they can reach a gesture on the bottom-most outerRing layer.
///
/// Tap-zone map (ring quadrant → action):
///   Top    (-135°…-45°)  → MENU / back
///   Bottom ( +45°…+135°) → play / pause
///   Left   (>135° | <-135°) → previous track
///   Right  (-45°…+45°)   → next track
///
/// Center button (inner disc) keeps its own Button for the select action.
struct TouchWheelView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var appSettings: AppSettings

    @State private var lastAngle: Double? = nil
    @State private var accumulatedDelta: Double = 0

    /// Degrees of rotary arc required to fire one scroll step.
    private var stepThreshold: Double { 18.0 / appSettings.wheelSensitivity }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                outerRing(size: size)
                innerDisc(size: size)
                centerButton(size: size)
                directionLabels(size: size)
                    .allowsHitTesting(false)   // purely decorative
            }
            .frame(width: size, height: size)
            // Name the coordinate space BEFORE the centering frame so that
            // DragGesture coordinates map to (0,0)…(size,size).
            .coordinateSpace(name: "wheel")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Single gesture for the entire wheel.
            // .simultaneousGesture lets the center Button still receive taps.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("wheel"))
                    .onChanged { value in
                        let moved = hypot(value.translation.width,
                                         value.translation.height)
                        // Only treat as a rotation once the finger has clearly moved.
                        if moved > 6 {
                            handleRotation(value: value, size: size)
                        }
                    }
                    .onEnded { value in
                        let moved = hypot(value.translation.width,
                                         value.translation.height)
                        // Small total displacement → the user tapped; detect zone.
                        if moved < 10 {
                            handleZoneTap(at: value.startLocation, size: size)
                        }
                        lastAngle = nil
                        accumulatedDelta = 0
                    }
            )
        }
    }

    // MARK: - Visual layers (no gestures)

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
                    .stroke(Color.white.opacity(color.isLight ? 0.2 : 0.12),
                            lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
            .frame(width: size, height: size)
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
    }

    private func centerButton(size: CGFloat) -> some View {
        let color = appSettings.shellColor
        return Button(action: centerTapped) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.homeButtonColor.opacity(0.9),
                                 color.homeButtonColor],
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

    // MARK: - Rotary drag

    private func handleRotation(value: DragGesture.Value, size: CGFloat) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let dx = value.location.x - center.x
        let dy = value.location.y - center.y
        let radius = sqrt(dx * dx + dy * dy)

        // Restrict rotation tracking to the annular ring zone.
        let innerRadius = size * 0.30
        let outerRadius = size / 2
        guard radius > innerRadius && radius < outerRadius else {
            lastAngle = nil
            return
        }

        let angle = atan2(dy, dx) * (180 / .pi)   // -180 … +180

        if let prev = lastAngle {
            var delta = angle - prev
            if delta >  180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            accumulatedDelta += delta
        }
        lastAngle = angle

        while accumulatedDelta >= stepThreshold {
            accumulatedDelta -= stepThreshold
            playerVM.wheelScrollDown()
            print("[Wheel] ↓ scrollDown  wheelStep=\(playerVM.wheelScrollStep)")
            fireWheelFeedback()
        }
        while accumulatedDelta <= -stepThreshold {
            accumulatedDelta += stepThreshold
            playerVM.wheelScrollUp()
            print("[Wheel] ↑ scrollUp    wheelStep=\(playerVM.wheelScrollStep)")
            fireWheelFeedback()
        }
    }

    // MARK: - Zone tap detection

    private func handleZoneTap(at location: CGPoint, size: CGFloat) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let radius = sqrt(dx * dx + dy * dy)

        // Inner disc taps (center button area) are handled by the Button itself.
        let innerRadius = size * 0.30
        let outerRadius = size / 2
        guard radius > innerRadius && radius <= outerRadius else {
            print("[Wheel] tap inside center disc — handled by Button (r=\(Int(radius)))")
            return
        }

        // Quadrant from angle (-180 to +180, 0° = right, -90° = top).
        let angle = atan2(dy, dx) * 180 / .pi

        if angle > -135 && angle < -45 {
            print("[Wheel] tap: TOP → MENU / back  (angle=\(Int(angle))°)")
            backTapped()
        } else if angle > 45 && angle < 135 {
            print("[Wheel] tap: BOTTOM → play/pause  (angle=\(Int(angle))°)")
            playPauseTapped()
        } else if angle >= 135 || angle <= -135 {
            print("[Wheel] tap: LEFT → prev  (angle=\(Int(angle))°)")
            prevTapped()
        } else {
            print("[Wheel] tap: RIGHT → next  (angle=\(Int(angle))°)")
            nextTapped()
        }
    }

    // MARK: - Button actions

    private func centerTapped() {
        print("[Wheel] CENTER button tapped → wheelSelect()")
        playerVM.wheelSelect()
        fireTapFeedback()
    }

    private func backTapped() {
        print("[Wheel] MENU → wheelBack()")
        playerVM.wheelBack()
        fireTapFeedback()
    }

    private func nextTapped() {
        print("[Wheel] RIGHT → skipForward()")
        playerVM.skipForward()
        fireTapFeedback()
    }

    private func prevTapped() {
        print("[Wheel] LEFT → skipBack()")
        playerVM.skipBack()
        fireTapFeedback()
    }

    private func playPauseTapped() {
        print("[Wheel] BOTTOM → togglePlayPause()")
        playerVM.togglePlayPause()
        fireTapFeedback()
    }

    // MARK: - Feedback

    private func fireWheelFeedback() {
        if appSettings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if appSettings.clickSoundsEnabled {
            print("[Wheel] click sound 1519")
            AudioServicesPlaySystemSound(1519)
        }
    }

    private func fireTapFeedback() {
        if appSettings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        if appSettings.clickSoundsEnabled {
            print("[Wheel] tap sound 1520")
            AudioServicesPlaySystemSound(1520)
        }
    }
}

struct TouchWheelView_Previews: PreviewProvider {
    static var previews: some View {
        TouchWheelView()
            .environmentObject(MusicPlayerViewModel())
            .environmentObject(AppSettings())
            .frame(width: 300, height: 300)
            .background(Color.black)
    }
}
