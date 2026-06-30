import SwiftUI

/// The top-level RetroWheel menu screen.
struct MainMenuView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager

    private let menuItems: [LibrarySection] = [
        .nowPlaying, .playlists, .artists, .albums, .songs, .extras, .settings
    ]

    // MARK: - Wheel selection state
    /// Index of the currently wheel-highlighted row (0 … menuItems.count-1).
    @State private var wheelSelectedIndex: Int = 0
    /// Last observed wheelScrollStep value; used to compute delta each tick.
    @State private var lastWheelStep: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                menuHeader

                // ScrollView + VStack so that row highlighting driven by
                // wheelSelectedIndex is a direct .background on the row view,
                // not mediated by List's internal cell caching.
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(menuItems.enumerated()), id: \.element.id) { idx, item in
                            NavigationLink(value: item) {
                                menuRow(item,
                                        isHighlighted: idx == wheelSelectedIndex)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .background(Color.white.opacity(0.10))
                        }
                    }
                }

                if let song = playerVM.currentSong {
                    miniNowPlaying(song: song)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $playerVM.showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
        // Sync lastWheelStep when this view becomes active so accumulated
        // steps from other screens don't cause a jump on re-entry.
        .onAppear {
            lastWheelStep = playerVM.wheelScrollStep
            print("[Menu] appeared — lastWheelStep=\(lastWheelStep)  selectedIndex=\(wheelSelectedIndex)")
        }
        // Rotary drag → move highlight up/down the menu list.
        .onChange(of: playerVM.wheelScrollStep) { newStep in
            let delta = newStep - lastWheelStep
            lastWheelStep = newStep
            let count = menuItems.count
            wheelSelectedIndex = ((wheelSelectedIndex + delta) % count + count) % count
            print("[Menu] wheelScrollStep=\(newStep)  delta=\(delta)  selectedIndex=\(wheelSelectedIndex)  item=\(menuItems[wheelSelectedIndex].rawValue)")
        }
        // Center button → navigate to the highlighted item.
        // Only act when this screen is currently visible (path is empty).
        .onChange(of: playerVM.wheelSelectTick) { _ in
            guard playerVM.menuNavigationPath.isEmpty else { return }
            let section = menuItems[wheelSelectedIndex]
            print("[Menu] CENTER SELECT → \(section.rawValue)")
            playerVM.menuNavigationPath.append(section)
        }
        // MENU/back tap while at the root resets the highlight to the top.
        .onChange(of: playerVM.wheelBackTick) { _ in
            print("[Menu] BACK → reset selectedIndex to 0")
            wheelSelectedIndex = 0
        }
    }

    // MARK: - Header

    private var menuHeader: some View {
        HStack(spacing: 8) {
            Text("RetroWheel")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)

            Spacer()

            Text(Date(), style: .time)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Menu rows

    @ViewBuilder
    private func menuRow(_ item: LibrarySection, isHighlighted: Bool = false) -> some View {
        let locked = isLocked(item)
        HStack(spacing: 14) {
            Image(systemName: item.systemIcon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(locked ? Color.white.opacity(0.30) : rowAccent(item))
                .frame(width: 26)

            Text(item.rawValue)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(locked ? Color.white.opacity(0.40) : Color.white)

            Spacer()

            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.yellow.opacity(0.6))
            }

            // Wheel selection indicator (chevron style)
            if isHighlighted {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        // Direct background on the row content — guaranteed to update
        // because this value is passed through the view argument, not
        // read from external state inside the List cell cache.
        .background(
            isHighlighted
                ? Color.white.opacity(0.18)
                : Color.white.opacity(0.04)
        )
    }

    private func isLocked(_ section: LibrarySection) -> Bool {
        guard !purchaseManager.hasFullAccess else { return false }
        return section == .playlists
    }

    private func rowAccent(_ section: LibrarySection) -> Color {
        switch section {
        case .nowPlaying: return Color.white.opacity(0.9)
        case .extras:     return Color(red: 0.4, green: 0.8, blue: 0.4).opacity(0.9)
        case .settings:   return Color.white.opacity(0.65)
        default:          return Color.white.opacity(0.80)
        }
    }

    // MARK: - Mini now-playing

    @ViewBuilder
    private func miniNowPlaying(song: Song) -> some View {
        NavigationLink(value: LibrarySection.nowPlaying) {
            HStack(spacing: 10) {
                ArtworkView(song: song, size: 36)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 1) {
                    Text(song.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.60))
                        .lineLimit(1)
                }

                Spacer()

                Button { playerVM.togglePlayPause() } label: {
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
        }
        .buttonStyle(.plain)
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainMenuView()
        }
        .environmentObject(MusicPlayerViewModel())
        .environmentObject(PurchaseManager())
        .environmentObject(AppSettings())
    }
}
