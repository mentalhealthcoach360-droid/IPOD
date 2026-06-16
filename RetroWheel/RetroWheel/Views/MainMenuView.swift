import SwiftUI

/// The top-level RetroWheel menu screen.
struct MainMenuView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel

    private let menuItems: [LibrarySection] = [
        .nowPlaying, .playlists, .artists, .albums, .songs, .settings
    ]

    var body: some View {
        ZStack {
            // iOS 6-era linen background
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Status bar / title
                menuHeader

                List(menuItems) { item in
                    NavigationLink(value: item) {
                        menuRow(item)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.white.opacity(0.12))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // Mini now-playing strip at bottom
                if let song = playerVM.currentSong {
                    miniNowPlaying(song: song)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Sub-views

    private var menuHeader: some View {
        HStack {
            Text("RetroWheel")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            Spacer()
            Text(Date(), style: .time)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
    }

    @ViewBuilder
    private func menuRow(_ item: LibrarySection) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.systemIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 28)

            Text(item.rawValue)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white)

            Spacer()
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private func miniNowPlaying(song: Song) -> some View {
        NavigationLink(value: LibrarySection.nowPlaying) {
            HStack(spacing: 10) {
                ArtworkView(song: song, size: 38)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 1) {
                    Text(song.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineLimit(1)
                }

                Spacer()

                Button { playerVM.togglePlayPause() } label: {
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.07))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainMenuView()
        .environmentObject(MusicPlayerViewModel())
}
