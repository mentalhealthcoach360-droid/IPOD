import SwiftUI
import MusicKit
import MediaPlayer

/// Resolves and displays album artwork from either a MusicKit song or a local MPMediaItem.
struct ArtworkView: View {
    let song: Song?
    let size: CGFloat

    var body: some View {
        Group {
            if let song {
                if let mkSong = song.musicKitSong {
                    MusicKitArtworkView(song: mkSong, size: size)
                } else if let item = song.mediaItem {
                    LocalArtworkView(item: item, size: size)
                } else {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.22), Color(white: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: size * 0.35))
                .foregroundStyle(Color.white.opacity(0.3))
        }
        .cornerRadius(6)
    }
}

// MARK: - MusicKit artwork

private struct MusicKitArtworkView: View {
    let song: MusicKit.Song
    let size: CGFloat

    var body: some View {
        if let artwork = song.artwork {
            ArtworkImage(artwork, width: size, height: size)
                .cornerRadius(6)
        } else {
            placeholderView(size: size)
        }
    }
}

// MARK: - Local MPMediaItem artwork

private struct LocalArtworkView: View {
    let item: MPMediaItem
    let size: CGFloat

    var body: some View {
        if let image = item.artwork?.image(at: CGSize(width: size, height: size)) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()
                .cornerRadius(6)
        } else {
            placeholderView(size: size)
        }
    }
}

private func placeholderView(size: CGFloat) -> some View {
    ZStack {
        LinearGradient(
            colors: [Color(white: 0.22), Color(white: 0.14)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        Image(systemName: "music.note")
            .font(.system(size: size * 0.35))
            .foregroundStyle(Color.white.opacity(0.3))
    }
    .cornerRadius(6)
}
