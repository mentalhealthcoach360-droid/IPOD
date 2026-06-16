import SwiftUI

struct ArtistsView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel

    private var sortedArtists: [String] {
        playerVM.artists.keys.sorted()
    }

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            List(sortedArtists, id: \.self) { artist in
                NavigationLink(destination: ArtistDetailView(artist: artist)) {
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
    let artist: String

    private var songs: [Song] {
        (playerVM.artists[artist] ?? []).sorted { $0.album < $1.album }
    }

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            List(songs) { song in
                Button { playerVM.play(song: song, queue: songs) } label: {
                    SongRowView(song: song,
                                isPlaying: playerVM.currentSong == song && playerVM.isPlaying)
                }
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color.white.opacity(0.1))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(artist)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
