import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            if !purchaseManager.hasFullAccess {
                lockedState
            } else if playerVM.playlists.isEmpty {
                emptyState
            } else {
                List(playerVM.playlists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)
                        .environmentObject(purchaseManager)) {
                        playlistRow(playlist)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.white.opacity(0.1))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
    }

    private var lockedState: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.yellow.opacity(0.6))
            Text("Playlists are included\nwith full access")
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
            Button("Unlock — \(purchaseManager.formattedPrice)") {
                showPaywall = true
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(20)
        }
    }

    private func playlistRow(_ playlist: MusicPlayerViewModel.PlaylistItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: "music.note.list")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                Text("\(playlist.songs.count) songs")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(Color.white.opacity(0.25))
            Text("No playlists yet")
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.4))
            Text("Create playlists in your music app\nor sync them from your computer.")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }
}

struct PlaylistDetailView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    let playlist: MusicPlayerViewModel.PlaylistItem

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            List(playlist.songs) { song in
                Button { playerVM.play(song: song, queue: playlist.songs) } label: {
                    SongRowView(song: song,
                                isPlaying: playerVM.currentSong == song && playerVM.isPlaying)
                }
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color.white.opacity(0.1))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
