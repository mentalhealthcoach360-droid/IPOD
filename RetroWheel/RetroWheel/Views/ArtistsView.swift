import SwiftUI

struct ArtistsView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager

    private var sortedArtists: [String] {
        playerVM.artists.keys.sorted()
    }

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            List(sortedArtists, id: \.self) { artist in
                NavigationLink(destination: ArtistDetailView(artist: artist)
                    .environmentObject(purchaseManager)) {
                    artistRow(artist)
                }
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color.white.opacity(0.1))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Artists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func artistRow(_ artist: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(artist)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                let count = playerVM.artists[artist]?.count ?? 0
                Text("\(count) song\(count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }
}

struct ArtistDetailView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showPaywall = false
    let artist: String

    private var songs: [Song] {
        (playerVM.artists[artist] ?? []).sorted { $0.album < $1.album }
    }

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                List(songs) { song in
                    Button {
                        if playerVM.canPlay(hasFullAccess: purchaseManager.hasFullAccess) {
                            playerVM.play(song: song, queue: songs,
                                          hasFullAccess: purchaseManager.hasFullAccess)
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        SongRowView(
                            song: song,
                            isPlaying: playerVM.currentSong == song && playerVM.isPlaying,
                            isLocked: !purchaseManager.hasFullAccess &&
                                playerVM.songsPlayedThisSession >= PurchaseManager.freeSongLimit
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.white.opacity(0.1))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                if !purchaseManager.hasFullAccess {
                    UpgradeBanner().environmentObject(purchaseManager)
                }
            }
        }
        .navigationTitle(artist)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
    }
}
