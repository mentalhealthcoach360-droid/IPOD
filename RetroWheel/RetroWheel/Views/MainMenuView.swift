import SwiftUI

/// The top-level RetroWheel menu screen.
struct MainMenuView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager

    private let menuItems: [LibrarySection] = [
        .nowPlaying, .playlists, .artists, .albums, .songs, .extras, .settings
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.07)],
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
                    .listRowSeparatorTint(Color.white.opacity(0.10))
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

    // MARK: - Header

    private var menuHeader: some View {
        HStack(spacing: 8) {
            Text("RetroWheel")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)

            if purchaseManager.isInTrial && !purchaseManager.isUnlocked {
                Text("TRIAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.18))
                    .cornerRadius(6)
            }

            Spacer()

            Text(Date(), style: .time)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Menu rows

    @ViewBuilder
    private func menuRow(_ item: LibrarySection) -> some View {
        let locked = isLocked(item)
        HStack(spacing: 14) {
            Image(systemName: item.systemIcon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(locked ? Color.white.opacity(0.30) : rowAccent(item))
                .frame(width: 26)

            Text(item.rawValue)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(locked ? Color.white.opacity(0.40) : Color.white)

            Spacer()

            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.yellow.opacity(0.6))
            }
        }
        .padding(.vertical, 5)
    }

    private func isLocked(_ section: LibrarySection) -> Bool {
        guard !purchaseManager.hasFullAccess else { return false }
        return section == .playlists
    }

    private func rowAccent(_ section: LibrarySection) -> Color {
        switch section {
        case .nowPlaying: return Color.white.opacity(0.9)
        case .extras:     return Color(red: 0.4, green: 0.8, blue: 0.4).opacity(0.9)
        case .settings:   return Color.white.opacity(0.65)
        default:          return Color.white.opacity(0.80)
        }
    }

    // MARK: - Mini now-playing

    @ViewBuilder
    private func miniNowPlaying(song: Song) -> some View {
        NavigationLink(value: LibrarySection.nowPlaying) {
            HStack(spacing: 10) {
                ArtworkView(song: song, size: 36)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 1) {
                    Text(song.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.60))
                        .lineLimit(1)
                }

                Spacer()

                Button { playerVM.togglePlayPause() } label: {
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MainMenuView()
    }
    .environmentObject(MusicPlayerViewModel())
    .environmentObject(PurchaseManager())
    .environmentObject(AppSettings())
}
