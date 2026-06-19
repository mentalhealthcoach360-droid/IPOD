import Foundation

/// Top-level menu items shown inside the RetroWheel shell.
enum LibrarySection: String, CaseIterable, Identifiable {
    case nowPlaying  = "Now Playing"
    case music       = "Music"
    case playlists   = "Playlists"
    case artists     = "Artists"
    case albums      = "Albums"
    case songs       = "Songs"
    case extras      = "Extras"
    case settings    = "Settings"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .nowPlaying: return "music.note"
        case .music:      return "music.note.list"
        case .playlists:  return "text.badge.checkmark"
        case .artists:    return "person.2"
        case .albums:     return "square.stack"
        case .songs:      return "music.quarternote.3"
        case .extras:     return "gamecontroller"
        case .settings:   return "gearshape"
        }
    }
}
