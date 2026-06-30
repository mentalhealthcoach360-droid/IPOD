import Foundation
import Combine
import AVFoundation
import MusicKit
import MediaPlayer

@MainActor
final class MusicPlayerViewModel: ObservableObject {

    // MARK: - Playback state
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0          // 0–1
    @Published var currentTime: TimeInterval = 0
    @Published var shuffle: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var volume: Float = AVAudioSession.sharedInstance().outputVolume

    // MARK: - Library
    @Published var allSongs: [Song] = []
    @Published var artists: [String: [Song]] = [:]
    @Published var albums: [String: [Song]] = [:]
    @Published var playlists: [PlaylistItem] = []

    // MARK: - Auth / permissions
    @Published var musicAuthStatus: MusicAuthorization.Status = .notDetermined
    @Published var localAuthGranted: Bool = false
    @Published var isLoadingLibrary: Bool = false

    // MARK: - Navigation
    @Published var activeSection: LibrarySection = .music
    @Published var selectedShellColor: ShellColor = .black
    /// The NavigationStack path owned here so both the wheel (back/select) and
    /// views can read and mutate it without passing Bindings through the hierarchy.
    @Published var menuNavigationPath: [LibrarySection] = []

    // MARK: - Wheel navigation
    /// Incremented/decremented by the touch wheel's rotary drag.
    /// Views observe this to update their local scroll-selection index.
    @Published private(set) var wheelScrollStep: Int = 0
    /// Incremented when the wheel's center button is pressed.
    @Published private(set) var wheelSelectTick: Int = 0
    /// Incremented when the wheel's MENU/back button is pressed.
    @Published private(set) var wheelBackTick: Int = 0

    // MARK: - Free tier tracking
    /// Number of distinct songs played this app session (resets on cold launch).
    @Published private(set) var songsPlayedThisSession: Int = 0
    @Published var showPaywall: Bool = false

    // MARK: - Private
    private var musicKitService = MusicKitService()
    private var localService = LocalMusicService()
    private var cancellables = Set<AnyCancellable>()
    private var progressTimer: AnyCancellable?

    // ApplicationMusicPlayer for MusicKit tracks
    private let mkPlayer = ApplicationMusicPlayer.shared
    // AVPlayer for local files
    private var avPlayer: AVPlayer?

    enum RepeatMode { case off, one, all }

    struct PlaylistItem: Identifiable {
        let id: String
        let name: String
        let songs: [Song]
    }

    // MARK: - Init

    init() {
        Task { await setup() }
    }

    private func setup() async {
        await requestMusicKitAuthorization()
        loadLocalLibrary()
        startProgressTimer()
        observeSystemVolume()
    }

    // MARK: - Authorisation

    func requestMusicKitAuthorization() async {
        let status = await MusicAuthorization.request()
        musicAuthStatus = status
        if status == .authorized {
            await loadMusicKitLibrary()
        }
    }

    func requestLocalLibraryAccess() {
        MPMediaLibrary.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                self?.localAuthGranted = status == .authorized
                if status == .authorized { self?.loadLocalLibrary() }
            }
        }
    }

    // MARK: - Library loading

    func loadMusicKitLibrary() async {
        isLoadingLibrary = true
        defer { isLoadingLibrary = false }

        let mkSongs = await musicKitService.fetchLibrarySongs()
        let converted = mkSongs.map { Song(from: $0) }
        mergeIntoLibrary(converted)

        let mkPlaylists = await musicKitService.fetchPlaylists()
        let convertedPlaylists = mkPlaylists.map { pl in
            PlaylistItem(
                id: pl.id.rawValue,
                name: pl.name,
                songs: (pl.tracks ?? []).compactMap { track in
                    if case .song(let s) = track { return Song(from: s) }
                    return nil
                }
            )
        }
        playlists = convertedPlaylists
    }

    func loadLocalLibrary() {
        let items = localService.fetchAllSongs()
        let converted = items.map { Song(from: $0) }
        mergeIntoLibrary(converted)
    }

    private func mergeIntoLibrary(_ songs: [Song]) {
        let existing = Set(allSongs.map(\.id))
        let newSongs = songs.filter { !existing.contains($0.id) }
        allSongs.append(contentsOf: newSongs)
        allSongs.sort { $0.title < $1.title }
        rebuildGroupings()
    }

    private func rebuildGroupings() {
        artists = Dictionary(grouping: allSongs, by: \.artist)
        albums  = Dictionary(grouping: allSongs, by: \.album)
    }

    // MARK: - Playback control

    /// Call before `play` to decide whether the free tier allows another song.
    func canPlay(hasFullAccess: Bool) -> Bool {
        hasFullAccess || songsPlayedThisSession < PurchaseManager.freeSongLimit
    }

    func play(song: Song, queue: [Song]? = nil, hasFullAccess: Bool = true) {
        guard canPlay(hasFullAccess: hasFullAccess) else {
            showPaywall = true
            return
        }
        // Only count newly started songs (not resume/seek on the same track)
        if song != currentSong { songsPlayedThisSession += 1 }
        currentSong = song
        stopCurrentPlayback()

        if let mkSong = song.musicKitSong {
            let songs = queue?.compactMap(\.musicKitSong) ?? [mkSong]
            mkPlayer.queue = ApplicationMusicPlayer.Queue(for: songs, startingAt: mkSong)
            Task {
                do {
                    try await mkPlayer.play()
                    isPlaying = true
                } catch {
                    print("MusicKit play error:", error)
                }
            }
        } else if let item = song.mediaItem,
                  let url = item.assetURL {
            avPlayer = AVPlayer(url: url)
            avPlayer?.play()
            isPlaying = true
        }
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        mkPlayer.pause()
        avPlayer?.pause()
        isPlaying = false
    }

    func resume() {
        if currentSong?.musicKitSong != nil {
            Task {
                try? await mkPlayer.play()
                isPlaying = true
            }
        } else {
            avPlayer?.play()
            isPlaying = true
        }
    }

    func skipForward() {
        guard let current = currentSong else { return }
        let list = currentQueue()
        guard let idx = list.firstIndex(of: current), idx + 1 < list.count else {
            if repeatMode == .all { play(song: list[0], queue: list) }
            return
        }
        play(song: list[idx + 1], queue: list)
    }

    func skipBack() {
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard let current = currentSong else { return }
        let list = currentQueue()
        guard let idx = list.firstIndex(of: current), idx > 0 else { return }
        play(song: list[idx - 1], queue: list)
    }

    func seek(to fraction: Double) {
        guard let song = currentSong else { return }
        let target = song.duration * fraction
        if song.musicKitSong != nil {
            mkPlayer.playbackTime = target
        } else {
            let time = CMTime(seconds: target, preferredTimescale: 600)
            avPlayer?.seek(to: time)
        }
    }

    func setVolume(_ v: Float) {
        volume = v
        avPlayer?.volume = v
    }

    // MARK: - Wheel navigation

    func wheelScrollDown() { wheelScrollStep += 1 }
    func wheelScrollUp()   { wheelScrollStep -= 1 }

    func wheelSelect() {
        // Views observe wheelSelectTick and decide what "select" means in context.
        // (MainMenuView navigates; NowPlayingView may toggle play/pause.)
        wheelSelectTick += 1
    }

    func wheelBack() {
        // Pop one level; if already at the root menu, this is a no-op for the path.
        if !menuNavigationPath.isEmpty {
            menuNavigationPath.removeLast()
        }
        wheelBackTick += 1
    }

    // MARK: - Helpers

    private func stopCurrentPlayback() {
        mkPlayer.pause()
        avPlayer?.pause()
        avPlayer = nil
        isPlaying = false
        currentTime = 0
        playbackProgress = 0
    }

    private func currentQueue() -> [Song] {
        switch activeSection {
        case .artists:
            return artists[currentSong?.artist ?? ""]?.sorted { $0.title < $1.title } ?? allSongs
        case .albums:
            return albums[currentSong?.album ?? ""]?.sorted { $0.title < $1.title } ?? allSongs
        default:
            return allSongs
        }
    }

    private func startProgressTimer() {
        progressTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateProgress()
            }
    }

    private func updateProgress() {
        guard let song = currentSong, song.duration > 0 else { return }

        if song.musicKitSong != nil {
            let t = mkPlayer.playbackTime
            currentTime = t
            playbackProgress = t / song.duration
        } else if let player = avPlayer {
            let t = player.currentTime().seconds
            currentTime = t.isNaN ? 0 : t
            playbackProgress = currentTime / song.duration
        }
    }

    private func observeSystemVolume() {
        NotificationCenter.default.publisher(
            for: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification")
        )
        .sink { [weak self] _ in
            self?.volume = AVAudioSession.sharedInstance().outputVolume
        }
        .store(in: &cancellables)
    }
}
