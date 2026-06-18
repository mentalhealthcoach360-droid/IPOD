import SwiftUI

/// Content rendered inside the RetroWheel virtual screen.
/// Routes between the main menu and all sub-screens.
/// AppSettings propagates automatically through the environment — no explicit declaration needed here.
struct ClassicMusicScreen: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var navigationPath: [LibrarySection] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MainMenuView()
                .navigationDestination(for: LibrarySection.self) { section in
                    sectionView(for: section)
                }
        }
        .tint(.white)
        .onReceive(playerVM.$activeSection) { section in
            if section == .music {
                navigationPath = []
            }
        }
    }

    @ViewBuilder
    private func sectionView(for section: LibrarySection) -> some View {
        switch section {
        case .nowPlaying:  NowPlayingView()
        case .music:       MainMenuView()
        case .playlists:   PlaylistsView()
        case .artists:     ArtistsView()
        case .albums:      AlbumsView()
        case .songs:       SongsView()
        case .extras:      ExtrasView()
        case .settings:    SettingsView()
        }
    }
}
