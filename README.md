# RetroWheel

> **RetroWheel** is a nostalgic music player designed for people who miss the simplicity of classic handheld MP3 players. Import your own songs, browse your library, and control playback with a smooth touch-wheel interface.

A skeuomorphic iOS app that renders a full-screen **classic handheld music player shell** on your iPhone, with a fully functional music player inside the virtual screen. Priced at a one-time $4.99 purchase on the App Store.

---

## What it looks like

The entire screen becomes a RetroWheel device. The aluminum body, the home button, the side volume rocker, the sleep/wake button, and the front camera bump are all rendered in SwiftUI — to scale. Tap the home button and it clicks with haptic feedback. The virtual screen hosts a faithful recreation of the classic touch music app, dark and minimal.

---

## Features

### Device Shell
- Accurate device proportions scaled to any iPhone screen
- All five colour variants — **Black, White, Pink, Yellow, Blue** — switchable in Settings with a tap
- Sheen highlight, body gradient, side buttons, and home button with press animation + haptic feedback
- Portrait-only orientation locks the shell in place exactly as a physical device sits in your hand

### Music Player
| Screen | What it does |
|--------|-------------|
| **Now Playing** | Large album art, animated waveform, scrubber with time display, shuffle / repeat, transport controls, system volume slider, blurred artwork background |
| **Songs** | Searchable full list with artwork, artist, duration; live "now playing" waveform animation |
| **Artists** | Grouped by artist → tap into artist detail with all tracks |
| **Albums** | 2-column art grid → tap into album detail with track list and hero header |
| **Playlists** | Apple Music and local playlists, tap to enter and play |
| **Main Menu** | Classic dark list menu; mini now-playing strip at the bottom taps into full player |

### Music Sources

#### Apple Music / MusicKit (recommended)
- Full Apple Music catalog and personal iCloud library via Apple's **MusicKit** framework (iOS 16+)
- Playlists, recently played, and catalog search
- Requires an Apple Music subscription on the user's device
- No extra server cost — Apple handles all streaming

#### Local Files
- Songs synced via Finder (macOS) or iTunes (Windows) appear automatically
- Album art rendered from embedded metadata
- Works completely offline, no subscription needed

### Background Playback
Audio background mode is declared in `Info.plist` — music keeps playing when the screen locks or you switch apps.

---

## Project Structure

```
RetroWheel/
├── RetroWheel.xcodeproj/
│   └── project.pbxproj
└── RetroWheel/
    ├── App/
    │   ├── RetroWheelApp.swift       — @main entry, injects MusicPlayerViewModel
    │   └── ContentView.swift         — Black canvas, centres the device shell
    ├── Views/
    │   ├── iPodShellView.swift       — The physical device shell (SwiftUI)
    │   ├── iPodScreenView.swift      — NavigationStack router inside the shell
    │   ├── MainMenuView.swift        — Top-level RetroWheel menu
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
        ├── RetroWheel.entitlements   — MusicKit entitlement
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

1. Clone the repo and open `RetroWheel/RetroWheel.xcodeproj` in Xcode.
2. In the project navigator select the **RetroWheel** target → **Signing & Capabilities**:
   - Set your **Team**
   - Change the **Bundle Identifier** to something unique (e.g. `com.yourname.RetroWheel`)
3. Add the **MusicKit** capability (Signing & Capabilities → + → MusicKit).
4. Add **Background Modes → Audio, AirPlay, and Picture in Picture**.
5. Build and run on a real device (MusicKit does not work on the Simulator).

### First Launch
On first launch the app requests Apple Music permission. Tap **Allow** to connect your library. If you only want local music, tap **Not Now** and grant local library access in Settings instead.

---

## App Store Submission Checklist

- [ ] Replace `com.yourcompany.RetroWheel` bundle ID with your own
- [ ] Set correct Team in Signing & Capabilities
- [ ] Add a 1024×1024 app icon to `Assets.xcassets/AppIcon.appiconset/`
- [ ] Screenshot on iPhone 6.7-inch and 6.5-inch for App Store listing
- [ ] Set price to **$4.99** (Tier 5) in App Store Connect → Pricing and Availability
- [ ] Fill in App Store Connect metadata (name, subtitle, keywords, description)
- [ ] Submit for review with category **Music**

### App Store Description

> RetroWheel is a nostalgic music player designed for people who miss the simplicity of classic handheld MP3 players. Import your own songs, browse your library, and control playback with a smooth touch-wheel interface.
>
> Your entire screen becomes a retro music player — body, home button, side buttons, and all — with a full music player behind the glass. Connect your Apple Music library or play tracks synced from your computer. Five classic colour options. Tap the home button and feel it click.
>
> One price. No subscriptions. No ads. Just music.

---

## Architecture Notes

- **MusicPlayerViewModel** is a single `@MainActor ObservableObject` injected at the root. It owns both `ApplicationMusicPlayer` (MusicKit) and `AVPlayer` (local files) and routes play calls to the correct engine based on which source the track came from.
- **Song** is a unified value type that wraps either a `MusicKit.Song` or an `MPMediaItem`, so every view can be source-agnostic.
- The **device shell** is 100% SwiftUI paths and gradients — no images, no UIKit, no external dependencies.
- The app has **zero third-party dependencies**.

---

## Roadmap Ideas

| Feature | Notes |
|---------|-------|
| Cover Flow | Horizontal scroll through album art with 3D perspective |
| EQ Visualizer | Animated bars on the Now Playing screen |
| Shake to shuffle | `CMMotionManager` on device shake |
| Lock screen / Control Centre integration | `MPNowPlayingInfoCenter` (add to ViewModel) |
| Click Wheel mode | Alternative dial-based navigation, toggled in Settings |
| Lyrics view | MusicKit provides timed lyrics for Apple Music tracks |

---

## License

Private / proprietary. All rights reserved. Not open-source.
