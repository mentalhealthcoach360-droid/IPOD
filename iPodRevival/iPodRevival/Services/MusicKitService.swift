import Foundation
import MusicKit

/// Wraps all MusicKit API calls in one place.
final class MusicKitService {

    // MARK: - Library Songs

    func fetchLibrarySongs() async -> [MusicKit.Song] {
        guard await isAuthorized() else { return [] }
        do {
            var request = MusicLibraryRequest<MusicKit.Song>()
            request.sort(by: \.title, ascending: true)
            let response = try await request.response()
            return Array(response.items)
        } catch {
            print("MusicKit fetchLibrarySongs error:", error)
            return []
        }
    }

    // MARK: - Playlists

    func fetchPlaylists() async -> [MusicKit.Playlist] {
        guard await isAuthorized() else { return [] }
        do {
            var request = MusicLibraryRequest<MusicKit.Playlist>()
            request.sort(by: \.name, ascending: true)
            var response = try await request.response()
            // Eagerly load tracks for each playlist
            var playlists: [MusicKit.Playlist] = []
            for pl in response.items {
                if let detailed = try? await pl.with([.tracks]) {
                    playlists.append(detailed)
                } else {
                    playlists.append(pl)
                }
            }
            return playlists
        } catch {
            print("MusicKit fetchPlaylists error:", error)
            return []
        }
    }

    // MARK: - Catalog Search

    func searchCatalog(query: String) async -> [MusicKit.Song] {
        guard await isAuthorized(), !query.isEmpty else { return [] }
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
            request.limit = 25
            let response = try await request.response()
            return Array(response.songs)
        } catch {
            print("MusicKit catalog search error:", error)
            return []
        }
    }

    // MARK: - Recently Played

    func fetchRecentlyPlayed() async -> [MusicKit.Song] {
        guard await isAuthorized() else { return [] }
        do {
            let request = MusicRecentlyPlayedRequest<MusicKit.Song>()
            let response = try await request.response()
            return Array(response.items)
        } catch {
            print("MusicKit recentlyPlayed error:", error)
            return []
        }
    }

    // MARK: - Private

    private func isAuthorized() async -> Bool {
        MusicAuthorization.currentStatus == .authorized
    }
}
