import Foundation
import MusicKit
import MediaPlayer

/// Unified song model that wraps both MusicKit tracks and local MPMediaItems.
struct Song: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artworkURL: URL?

    // Underlying sources — at most one will be non-nil
    let musicKitSong: MusicKit.Song?
    let mediaItem: MPMediaItem?

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}

extension Song {
    /// Convenience initialiser from a MusicKit Song.
    init(from mkSong: MusicKit.Song) {
        id = mkSong.id.rawValue
        title = mkSong.title
        artist = mkSong.artistName
        album = mkSong.albumTitle ?? ""
        duration = mkSong.duration ?? 0
        artworkURL = mkSong.artwork?.url(width: 600, height: 600)
        musicKitSong = mkSong
        mediaItem = nil
    }

    /// Convenience initialiser from a local MPMediaItem.
    init(from item: MPMediaItem) {
        id = String(item.persistentID)
        title = item.title ?? "Unknown Title"
        artist = item.artist ?? "Unknown Artist"
        album = item.albumTitle ?? "Unknown Album"
        duration = item.playbackDuration
        artworkURL = nil          // artwork fetched separately via MPMediaItemArtwork
        musicKitSong = nil
        mediaItem = item
    }
}
