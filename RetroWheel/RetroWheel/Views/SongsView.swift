import SwiftUI

struct SongsView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var searchText  = ""
    @State private var showPaywall = false

    private var filtered: [Song] {
        guard !searchText.isEmpty else { return playerVM.allSongs }
        return playerVM.allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            if playerVM.isLoadingLibrary {
                ProgressView("Loading…")
                    .tint(.white)
                    .foregroundStyle(Color.white)
            } else if filtered.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    List(filtered) { song in
                        Button {
                            if playerVM.canPlay(hasFullAccess: purchaseManager.hasFullAccess) {
                                playerVM.play(song: song,
                                              queue: filtered,
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
                    .searchable(text: $searchText, prompt: "Songs, artists…")

                    if !purchaseManager.hasFullAccess {
                        UpgradeBanner()
                            .environmentObject(purchaseManager)
                    }
                }
            }
        }
        .navigationTitle("Songs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 44))
                .foregroundStyle(Color.white.opacity(0.3))
            Text(playerVM.musicAuthStatus == .authorized || playerVM.localAuthGranted
                 ? "No songs found"
                 : "Connect a music source")
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.5))
            if playerVM.musicAuthStatus != .authorized {
                Button("Connect Streaming Library") {
                    Task { await playerVM.requestMusicKitAuthorization() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
            }
        }
    }
}

struct SongRowView: View {
    let song: Song
    let isPlaying: Bool
    var isLocked: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(song: song, size: 44)
                .cornerRadius(4)
                .opacity(isLocked ? 0.4 : 1.0)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 14, weight: isPlaying ? .bold : .medium))
                    .foregroundStyle(isLocked ? Color.white.opacity(0.4) : Color.white.opacity(isPlaying ? 1 : 0.9))
                    .lineLimit(1)
                Text(song.artist)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(isLocked ? 0.25 : 0.55))
                    .lineLimit(1)
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.3))
            } else if isPlaying {
                Image(systemName: "waveform")
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
            } else {
                Text(formatDuration(song.duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        guard d > 0 else { return "" }
        let s = Int(d)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
