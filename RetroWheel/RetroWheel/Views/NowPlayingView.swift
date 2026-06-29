import SwiftUI

/// Full now-playing screen with large album art and transport controls.
struct NowPlayingView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @Environment(\.dismiss) var dismiss

    @State private var scrubbing = false
    @State private var scrubValue: Double = 0

    private var progress: Double {
        scrubbing ? scrubValue : playerVM.playbackProgress
    }

    var body: some View {
        ZStack {
            // Dynamic blurred background from artwork colour
            artworkBackground

            VStack(spacing: 0) {
                navigationBar
                    .padding(.top, 6)

                Spacer(minLength: 0)

                // Album art
                ArtworkView(song: playerVM.currentSong, size: 220)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
                    .padding(.horizontal, 24)
                    .scaleEffect(playerVM.isPlaying ? 1.0 : 0.88)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: playerVM.isPlaying)

                Spacer(minLength: 0)

                // Song info
                songInfo
                    .padding(.horizontal, 20)

                // Scrubber
                scrubber
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                // Transport
                transportControls
                    .padding(.horizontal, 28)
                    .padding(.top, 12)

                // Volume
                volumeSlider
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onReceive(playerVM.$playbackProgress) { p in
            if !scrubbing { scrubValue = p }
        }
    }

    // MARK: - Sub-views

    private var artworkBackground: some View {
        ZStack {
            Color.black
            ArtworkView(song: playerVM.currentSong, size: 400)
                .blur(radius: 60)
                .opacity(0.55)
                .scaleEffect(1.4)
        }
        .ignoresSafeArea()
    }

    private var navigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(8)
            }
            Spacer()
            Text("Now Playing")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
            Spacer()
            // Placeholder to balance chevron
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 8)
    }

    private var songInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(playerVM.currentSong?.title ?? "Not Playing")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            Text(playerVM.currentSong?.artist ?? "")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scrubber: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { progress },
                    set: { v in
                        scrubbing = true
                        scrubValue = v
                    }
                ),
                in: 0...1
            ) { editing in
                if !editing {
                    playerVM.seek(to: scrubValue)
                    scrubbing = false
                }
            }
            .tint(Color.white)
            .accentColor(Color.white)

            HStack {
                Text(formatTime(playerVM.currentTime))
                Spacer()
                Text("-" + formatTime(
                    (playerVM.currentSong?.duration ?? 0) - playerVM.currentTime
                ))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.65))
        }
    }

    private var transportControls: some View {
        HStack(spacing: 0) {
            // Shuffle
            toggleButton(
                icon: "shuffle",
                active: playerVM.shuffle
            ) { playerVM.shuffle.toggle() }

            Spacer()

            // Previous / rewind
            Button { playerVM.skipBack() } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(RetroButtonStyle())

            Spacer()

            // Play / Pause
            Button { playerVM.togglePlayPause() } label: {
                Image(systemName: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(RetroButtonStyle())

            Spacer()

            // Next
            Button { playerVM.skipForward() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(RetroButtonStyle())

            Spacer()

            // Repeat
            repeatButton
        }
    }

    private var repeatButton: some View {
        let (icon, active): (String, Bool) = {
            switch playerVM.repeatMode {
            case .off: return ("repeat", false)
            case .all: return ("repeat", true)
            case .one: return ("repeat.1", true)
            }
        }()
        return toggleButton(icon: icon, active: active) {
            switch playerVM.repeatMode {
            case .off: playerVM.repeatMode = .all
            case .all: playerVM.repeatMode = .one
            case .one: playerVM.repeatMode = .off
            }
        }
    }

    @ViewBuilder
    private func toggleButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(active ? Color.white : Color.white.opacity(0.35))
        }
        .buttonStyle(RetroButtonStyle())
    }

    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.5))

            Slider(value: Binding(
                get: { Double(playerVM.volume) },
                set: { playerVM.setVolume(Float($0)) }
            ), in: 0...1)
            .tint(Color.white.opacity(0.8))

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// Subtle press-scale effect for transport buttons.
struct RetroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
            .environmentObject(MusicPlayerViewModel())
            .environmentObject(PurchaseManager())
    }
}
