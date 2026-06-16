import SwiftUI

/// The top-level RetroWheel menu screen.
struct MainMenuView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager

    private let menuItems: [LibrarySection] = [
        .nowPlaying, .playlists, .artists, .albums, .songs, .settings
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
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

                if let song = playerVM.currentSong {
                    miniNowPlaying(song: song)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $playerVM.showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
    }

    // MARK: - Sub-views

    private var menuHeader: some View {
        HStack {
            Text("RetroWheel")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            Spacer()
            // Trial indicator badge
            if purchaseManager.isInTrial && !purchaseManager.isUnlocked {
                Text("TRIAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.18))
                    .cornerRadius(6)
            }
            Text(Date(), style: .time)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.6))
                .padding(.leading, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
    }

    @ViewBuilder
    private func menuRow(_ item: LibrarySection) -> some View {
        let isLocked = lockedSection(item)
        HStack(spacing: 14) {
            Image(systemName: item.systemIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isLocked ? Color.white.opacity(0.35) : Color.white.opacity(0.85))
                .frame(width: 28)

            Text(item.rawValue)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(isLocked ? Color.white.opacity(0.45) : Color.white)

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.yellow.opacity(0.7))
            }
        }
        .padding(.vertical, 5)
    }

    /// Playlists are locked in free tier.
    private func lockedSection(_ section: LibrarySection) -> Bool {
        guard !purchaseManager.hasFullAccess else { return false }
        return section == .playlists
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
        .environmentObject(PurchaseManager())
}
