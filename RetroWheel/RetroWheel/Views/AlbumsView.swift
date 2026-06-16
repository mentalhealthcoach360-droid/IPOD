import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel

    private var sortedAlbums: [String] {
        playerVM.albums.keys.sorted()
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(sortedAlbums, id: \.self) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumTileView(album: album,
                                          songs: playerVM.albums[album] ?? [])
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
        }
        .navigationTitle("Albums")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct AlbumTileView: View {
    let album: String
    let songs: [Song]

    private var representative: Song? { songs.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkView(song: representative, size: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)

            Text(album)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)

            if let artist = representative?.artist {
                Text(artist)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
            }
        }
    }
}

struct AlbumDetailView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    let album: String

    private var songs: [Song] {
        (playerVM.albums[album] ?? []).sorted { $0.title < $1.title }
    }

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            List {
                // Album hero header
                Section {
                    HStack(spacing: 14) {
                        ArtworkView(song: songs.first, size: 80)
                            .cornerRadius(6)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(album)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text(songs.first?.artist ?? "")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.6))
                            Text("\(songs.count) tracks")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                Section {
                    ForEach(songs) { song in
                        Button { playerVM.play(song: song, queue: songs) } label: {
                            SongRowView(song: song,
                                        isPlaying: playerVM.currentSong == song && playerVM.isPlaying)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.white.opacity(0.1))
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(album)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
