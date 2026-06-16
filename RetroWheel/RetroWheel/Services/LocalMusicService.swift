import Foundation
import MediaPlayer

/// Fetches music from the device's local MediaPlayer library.
final class LocalMusicService {

    func fetchAllSongs() -> [MPMediaItem] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return [] }
        let query = MPMediaQuery.songs()
        return query.items ?? []
    }

    func fetchArtists() -> [MPMediaItemCollection] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return [] }
        let query = MPMediaQuery.artists()
        return query.collections ?? []
    }

    func fetchAlbums() -> [MPMediaItemCollection] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return [] }
        let query = MPMediaQuery.albums()
        return query.collections ?? []
    }

    func fetchPlaylists() -> [MPMediaPlaylist] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return [] }
        let query = MPMediaQuery.playlists()
        return (query.collections ?? []).compactMap { $0 as? MPMediaPlaylist }
    }

    /// Returns the UIImage artwork for a local MPMediaItem at the given size.
    func artwork(for item: MPMediaItem, size: CGSize) -> UIImage? {
        item.artwork?.image(at: size)
    }
}
