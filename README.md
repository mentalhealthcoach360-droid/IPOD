# iPod Revival

A skeuomorphic iOS music player that renders a full-screen **iPod touch 5th-generation shell** on your iPhone, with a fully functional music player inside the virtual screen.  Priced at a one-time $4.99 purchase on the App Store.

---

## What it looks like

The entire screen becomes an iPod touch 5.  The aluminum body, the home button, the side volume rocker, the sleep/wake button, and the front camera bump are all rendered in SwiftUI — to scale.  Tap the home button and it clicks with haptic feedback.  The virtual screen hosts a faithful recreation of the classic iPod touch Music app, dark and minimal.

---

## Features

### iPod Shell
- Accurate iPod touch 5 proportions (4-inch / 1136 × 640 screen ratio)
- All five original color variants — **Black, White, Pink, Yellow, Blue** — switchable in Settings with a tap
- Sheen highlight, body gradient, side buttons, and home button with press animation + haptic feedback
- Portrait-only orientation locks the shell in place exactly as the physical device sat in your hand

### Music Player
| Screen | What it does |
|--------|-------------|
| **Now Playing** | Large album art, animated waveform, scrubber with time display, shuffle / repeat, transport controls, system volume slider, blurred artwork background |
| **Songs** | Searchable full list with artwork, artist, duration; live "now playing" waveform animation |
| **Artists** | Grouped by artist → tap into artist detail with all tracks |
| **Albums** | 2-column art grid → tap into album detail with track list and hero header |
| **Playlists** | Apple Music and local playlists, tap to enter and play |
| **Main Menu** | Classic iPod-style dark list; mini now-playing strip at the bottom taps into full player |

### Music Sources

#### Apple Music / MusicKit (recommended)
- Full Apple Music catalog and personal iCloud library via Apple's **MusicKit** framework (iOS 15+)
- Playlists, recently played, and catalog search
- Requires an Apple Music subscription on the user's device
- No extra server cost — Apple handles all streaming

#### Local Files
- Songs synced via Finder (macOS) or iTunes (Windows) appear automatically
- Album art rendered from embedded metadata
- Works completely offline, no subscription needed

### Background Playback
Declare `audio` in `UIBackgroundModes` (already done in Info.plist) and music keeps playing when the screen locks or you switch apps.

---

## Project Structure

```
iPodRevival/
├── iPodRevival.xcodeproj/
│   └── project.pbxproj
└── iPodRevival/
    ├── App/
    │   ├── iPodRevivalApp.swift      — @main entry, injects MusicPlayerViewModel
    │   └── ContentView.swift         — Black canvas, centres iPodShellView
    ├── Views/
    │   ├── iPodShellView.swift       — The physical device shell (SwiftUI)
    │   ├── iPodScreenView.swift      — NavigationStack router inside the shell
    │   ├── MainMenuView.swift        — Top-level iPod menu
    │   ├── NowPlayingView.swift      — Full player with artwork, scrubber, controls
    │   ├── ArtworkView.swift         — Resolves MusicKit / local artwork
    │   ├── SongsView.swift           — Searchable song list
    │   ├── ArtistsView.swift         — Artist list + detail
    │   ├── AlbumsView.swift          — Album grid + detail
    │   ├── PlaylistsView.swift       — Playlist list + detail
    │   └── SettingsView.swift        — Colour picker, source auth, about
    ├── ViewModels/
    │   └── MusicPlayerViewModel.swift — Playback state, library loading, routing
    ├── Services/
    │   ├── MusicKitService.swift     — All MusicKit API calls
    │   └── LocalMusicService.swift   — MediaPlayer framework queries
    ├── Models/
    │   ├── Song.swift                — Unified song model (MusicKit + local)
    │   ├── iPodColor.swift           — 5-colour enum with gradient definitions
    │   └── LibrarySection.swift      — Navigation section enum
    └── Resources/
        ├── Info.plist                — NSAppleMusicUsageDescription + audio background mode
        ├── iPodRevival.entitlements  — MusicKit entitlement
        └── Assets.xcassets/
```

---

## Getting Started

### Requirements
- **Xcode 15.4** or later
- **iOS 16.0** deployment target (MusicKit `MusicLibraryRequest` requires iOS 16+)
- An **Apple Developer account** (free tier works for personal testing; paid required for App Store)
- An **Apple Music subscription** to test streaming (local library works without one)

### Setup

1. Clone the repo and open `iPodRevival/iPodRevival.xcodeproj` in Xcode.
2. In the project navigator select the **iPodRevival** target → **Signing & Capabilities**:
   - Set your **Team**
   - Change the **Bundle Identifier** to something unique (e.g. `com.yourname.iPodRevival`)
3. Add the **MusicKit** capability (Signing & Capabilities → + → MusicKit).
4. Add **Background Modes → Audio, AirPlay, and Picture in Picture**.
5. Build and run on a real device (MusicKit does not work on the simulator).

### First Launch
On first launch the app requests Apple Music permission.  Tap **Allow** to connect your library.  If you only want local music, tap **Not Now** and grant local library access in Settings instead.

---

## App Store Submission Checklist

- [ ] Replace `com.yourcompany.iPodRevival` bundle ID with your own
- [ ] Set correct Team in Signing & Capabilities
- [ ] Add a 1024×1024 app icon to `Assets.xcassets/AppIcon.appiconset/`
- [ ] Screenshot on iPhone 6.7-inch and 6.5-inch for App Store listing
- [ ] Set price to **$4.99** (Tier 5) in App Store Connect → Pricing and Availability
- [ ] Fill in App Store Connect metadata (name, subtitle, keywords, description)
- [ ] Submit for review with category **Music**

### Suggested App Store Description

> Remember the iPod touch 5?  Now your iPhone *is* one.
>
> iPod Revival covers your screen with a pixel-perfect iPod touch 5 shell — body, home button, side buttons, and all — and puts a full music player behind the glass.  Connect your Apple Music library or play tracks synced from your computer.  Five classic colours.  Tap the home button and feel it click.
>
> One price.  No subscriptions.  No ads.  Just music.

---

## Architecture Notes

- **MusicPlayerViewModel** is a single `@MainActor ObservableObject` injected at the root.  It owns both `ApplicationMusicPlayer` (MusicKit) and `AVPlayer` (local files) and routes play calls to the correct engine based on which source the track came from.
- **Song** is a unified value type that wraps either a `MusicKit.Song` or an `MPMediaItem`, so every view can be source-agnostic.
- The **iPod shell** is 100% SwiftUI paths and gradients — no images, no UIKit, no external dependencies.
- The app has **zero third-party dependencies**.

---

## Roadmap Ideas

| Feature | Notes |
|---------|-------|
| Cover Flow | Horizontal scroll through album art with 3D perspective, just like iOS 6 |
| EQ Visualizer | Animated bars on the Now Playing screen |
| Shake to shuffle | `CMMotionManager` on device shake |
| Lock screen / Control Centre integration | Already works via `MPNowPlayingInfoCenter` (add to ViewModel) |
| iPod classic Click Wheel mode | Alternative navigation UX, toggled in Settings |
| Dark/light mode inner screen | Match the physical iPod colour's brightness |
| Lyrics view | MusicKit provides timed lyrics for Apple Music tracks |

---

## License

Private / proprietary.  All rights reserved.  Not open-source.
