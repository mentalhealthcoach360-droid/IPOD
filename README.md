# RetroWheel

> **RetroWheel** is a nostalgic touch-wheel music player designed for people who miss the simplicity of classic handheld MP3 players. Import your own songs, browse your library, and control playback with a smooth retro-inspired wheel interface.

A skeuomorphic iOS app that fills your screen with a retro-styled handheld music player shell, with a fully functional music player running inside the virtual screen.

**Free to download.** The app is free to try for 7 days from first launch — no payment required. After that, a one-time $4.99 in-app purchase unlocks everything permanently. This is a **non-consumable IAP, not an auto-renewable subscription** — users are never charged again.

---

## What it looks like

Your entire screen becomes a retro music device. The rounded metal body, the home button, the side volume rocker, and the sleep/wake button are all rendered in SwiftUI — no images, pure code. Tap the home button and it clicks with haptic feedback. The virtual screen inside hosts a clean, dark music player interface inspired by the golden era of handheld audio.

---

## Features

### Device Shell
- Retro-styled handheld device proportions scaled to any iPhone screen
- Five colour variants — **Black, White, Pink, Yellow, Blue** — switchable in Settings
- Sheen highlight, body gradient, side buttons, and home button with press animation + haptic feedback
- Portrait-only orientation locks the shell in place

### Monetization Model

| Tier | Price | What you get |
|------|-------|-------------|
| **Free** | $0 | Browse the full retro interface, play up to 3 local tracks per session |
| **Free to try** | Free, 7 days | Full access from first launch — no payment required |
| **Lifetime unlock** | $4.99 (one-time IAP) | Unlimited songs, all playlists, streaming library, all 5 shell colours |

- Bundle ID: `com.marcustrise.retrowheel`
- Product ID: `com.marcustrise.retrowheel.unlock`
- IAP type: **Non-consumable** — one-time purchase, restores automatically via StoreKit 2
- **Not an auto-renewable subscription** — users are never charged again after the one-time unlock
- Free to try for 7 days from first launch (tracked locally — no StoreKit subscription needed)

### Music Player
| Screen | What it does |
|--------|-------------|
| **Now Playing** | Large album art, animated waveform indicator, scrubber with elapsed/remaining time, shuffle / repeat, transport controls, volume slider, blurred artwork background |
| **Songs** | Searchable full list with artwork, artist, duration; live waveform animation on active track |
| **Artists** | Grouped by artist → artist detail view with all tracks |
| **Albums** | 2-column artwork grid → album detail with track list and header |
| **Playlists** | Streaming and local playlists; tap to enter and play |
| **Main Menu** | Classic dark list menu; mini now-playing strip at the bottom links to full player |

### Music Sources

#### Streaming Library (MusicKit)
- Access your personal streaming music library and browse available tracks via MusicKit (iOS 16+)
- Playlists, recently played, and search
- Requires an active music streaming subscription on the user's device
- No additional server infrastructure required

#### Local Files
- Songs synced from your computer appear automatically via the device media library
- Album art rendered from embedded track metadata
- Works fully offline, no subscription needed

### Background Playback
Audio background mode is enabled in `Info.plist` — music continues when the screen locks or you switch apps.

---

## Project Structure

```
RetroWheel/
├── RetroWheel.xcodeproj/
│   └── project.pbxproj
└── RetroWheel/
    ├── App/
    │   ├── RetroWheelApp.swift        — @main entry, injects MusicPlayerViewModel
    │   └── ContentView.swift          — Black canvas, centres RetroShellView
    ├── Views/
    │   ├── RetroShellView.swift       — The device shell rendered in SwiftUI
    │   ├── ClassicMusicScreen.swift   — NavigationStack router inside the shell
    │   ├── MainMenuView.swift         — Top-level RetroWheel menu
    │   ├── NowPlayingView.swift       — Full player with artwork, scrubber, controls
    │   ├── ArtworkView.swift          — Resolves streaming / local artwork
    │   ├── SongsView.swift            — Searchable song list (free-tier cap enforced)
    │   ├── PaywallView.swift          — Full-access paywall + upgrade banner
    │   ├── ArtistsView.swift          — Artist list + detail
    │   ├── AlbumsView.swift           — Album grid + detail
    │   ├── PlaylistsView.swift        — Playlist list + detail
    │   └── SettingsView.swift         — Colour picker, source auth, about
    ├── ViewModels/
    │   └── MusicPlayerViewModel.swift — Playback state, library loading, routing
    ├── Services/
    │   ├── MusicKitService.swift      — MusicKit API calls
    │   ├── LocalMusicService.swift    — Local media library queries
    │   └── PurchaseManager.swift      — StoreKit 2 non-consumable IAP, 7-day free-to-try period, free-tier limits
    ├── Models/
    │   ├── Song.swift                 — Unified song model (streaming + local)
    │   ├── ShellColor.swift           — 5-colour enum with gradient definitions
    │   └── LibrarySection.swift       — Navigation section enum
    └── Resources/
        ├── Info.plist                 — Music library usage description + audio background mode
        ├── RetroWheel.entitlements    — MusicKit entitlement
        └── Assets.xcassets/
```

---

## Getting Started

### Requirements
- **Xcode 15.4** or later
- **iOS 16.0** deployment target
- A **developer account** enrolled in the Developer Program (free tier works for device testing; paid enrollment required for App Store distribution)
- A music streaming subscription to test streaming playback (local library works without one)

### Setup

1. Clone the repo and open `RetroWheel/RetroWheel.xcodeproj` in Xcode.
2. Select the **RetroWheel** target → **Signing & Capabilities**:
   - Set your **Team**
   - Bundle Identifier is set to `com.marcustrise.retrowheel` — update Team only
3. Add the **MusicKit** capability (Signing & Capabilities → + → MusicKit).
4. Add **Background Modes → Audio, AirPlay, and Picture in Picture**.
5. Build and run on a real device (MusicKit does not work on the Simulator).

### First Launch
On first launch the app requests access to your music library. Tap **Allow** to connect your streaming library. For local-only playback, tap **Not Now** and grant local library access in Settings instead.

---

## App Store Submission Checklist

### App setup
- [ ] Bundle ID is `com.marcustrise.retrowheel` — set your **Team** in Signing & Capabilities
- [ ] Add a 1024×1024 app icon to `Assets.xcassets/AppIcon.appiconset/`
- [ ] Screenshot on iPhone 6.7-inch and 6.5-inch for the listing
- [ ] Fill in App Store Connect metadata (name, subtitle, keywords, description)
- [ ] Submit for review with category **Music**

### Pricing (freemium)
- [ ] Set app price to **Free** in App Store Connect → Pricing and Availability
- [ ] Create an In-App Purchase in App Store Connect:
  - Type: **Non-Consumable**
  - Product ID: `com.marcustrise.retrowheel.unlock`
  - Price: **$4.99** (Tier 5)
  - Display name: `Unlock RetroWheel`
  - Description: `Unlock unlimited songs, playlists, streaming library access, and all shell colour options. One-time purchase — not a subscription, no recurring charges.`
- [ ] `PurchaseManager.productID` is already set to `com.marcustrise.retrowheel.unlock`
- [ ] Test the IAP flow in sandbox mode before submitting

### App Store Description

> RetroWheel is a nostalgic touch-wheel music player designed for people who miss the simplicity of classic handheld MP3 players. Import your own songs, browse your library, and control playback with a smooth retro-inspired wheel interface.
>
> Your screen becomes a retro music device — body, home button, side buttons, and all. Browse by song, artist, or album. Connect your streaming library or play tracks synced from your computer. Five colour options. Tap the home button and feel it click.
>
> **Free to download.** The app is free to try for 7 days — no payment required. After that, unlock everything permanently for a one-time $4.99. Not a subscription. No recurring charges. Ever.

---

## Architecture Notes

- **MusicPlayerViewModel** is a single `@MainActor ObservableObject` injected at the root. It owns both the MusicKit music player (streaming) and `AVPlayer` (local files) and routes play calls to the correct engine based on the track source.
- **Song** is a unified value type wrapping either a MusicKit track or a local media item, so all views are source-agnostic.
- **RetroShellView** is 100% SwiftUI gradients and shapes — no image assets, no UIKit.
- Zero third-party dependencies.

---

## Roadmap Ideas

| Feature | Notes |
|---------|-------|
| Cover Flow | Horizontal scroll through album art with 3D perspective |
| EQ Visualizer | Animated bars on the Now Playing screen |
| Shake to shuffle | Motion-based shuffle trigger |
| Lock screen / Control Centre integration | `MPNowPlayingInfoCenter` (add to ViewModel) |
| Dial navigation mode | Touch-wheel dial for menu scrolling, toggled in Settings |
| Timed lyrics view | MusicKit provides synced lyrics for streaming tracks |

---

## License

Private / proprietary. All rights reserved. Not open-source.
