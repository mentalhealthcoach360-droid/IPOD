# RetroWheel

> **RetroWheel** is a nostalgic touch-wheel music player designed for people who miss the simplicity of classic handheld portable music players. Import your own songs, browse your library, and control playback with a smooth retro-inspired wheel interface.

A full-screen iOS experience where the entire display becomes the retro music device — large interactive touch wheel at the bottom, music player screen at the top, no wasted space.

**Free to download.** The free tier lets you browse the full retro interface and play up to 3 local tracks per session. A one-time $4.99 in-app purchase unlocks everything permanently — unlimited songs, all playlists, streaming library, and all 5 shell colours. This is a **non-consumable IAP, not a subscription** — one charge, never recurring.

---

## What it looks like

Your entire screen becomes a retro portable music player. The shell background fills edge-to-edge in your chosen colour. The top portion holds the music player display (library menus, now-playing, artwork). The bottom holds a large circular touch wheel for transport and navigation. Everything is rendered in pure SwiftUI — no images, no external assets.

---

## Features

### Full-Screen Experience
- The entire display is the retro device — no black borders or wasted space
- Shell colour fills edge-to-edge (five choices)
- Music screen and large touch wheel scale to any device size

### Touch Wheel
- Rotary drag scrolls menus with haptic + click sound feedback
- Top tap: back to menu
- Left / right taps: previous / next track
- Center button: play / pause
- Sensitivity, haptics, and click sounds all adjustable in Settings

### Device Shell
- Five colour variants — **Black, White, Pink, Yellow, Blue** — switchable in Settings
- Body gradient fills entire screen; home-button tap resets to main menu
- Portrait-only orientation

### Monetization Model

| Tier | Price | What you get |
|------|-------|-------------|
| **Free** | $0 | Browse the retro interface, play up to 3 local tracks per session, black shell only |
| **Lifetime unlock** | $4.99 (one-time IAP) | Unlimited songs, all playlists, streaming library, all 5 shell colours |

- Bundle ID: `com.marcustrise.retrowheel`
- Product ID: `com.marcustrise.retrowheel.unlock`
- IAP type: **Non-consumable** — one-time purchase, restores automatically via StoreKit 2
- **Not an auto-renewable subscription** — one charge, never recurring
- No trial period

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
    │   ├── PurchaseManager.swift      — StoreKit 2 non-consumable IAP, free-tier song limit
    │   └── KeychainHelper.swift       — Keychain wrapper (Security.framework, no third-party deps)
    ├── Models/
    │   ├── Song.swift                 — Unified song model (streaming + local)
    │   ├── ShellColor.swift           — 5-colour enum with gradient definitions
    │   └── LibrarySection.swift       — Navigation section enum
    └── Resources/
        ├── Info.plist                 — Music library usage description + audio background mode
        ├── RetroWheel.entitlements    — MusicKit entitlement
        ├── RetroWheel.storekit        — Local StoreKit config for Simulator testing
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

### Local StoreKit testing (Simulator)

A StoreKit configuration file is included at `RetroWheel/Resources/RetroWheel.storekit`. This lets you test the full purchase, restore, and paywall flow in the Simulator without a real App Store account.

**One-time setup:**
1. In Xcode, go to **Product → Scheme → Edit Scheme…**
2. Select **Run** → **Options** tab
3. Under **StoreKit Configuration**, choose `RetroWheel.storekit`
4. Close and run on any Simulator

**What you can test with the local config:**
- `PaywallView` loads the product and shows the correct price ($4.99)
- Tapping **Unlock Forever** completes the purchase and unlocks all gated features
- Tapping **Restore Purchase** re-unlocks on a fresh install
- Free-tier song cap (3 songs/session) is enforced correctly
- Locked shell colours become available after unlock
- Playlists screen unlocks after purchase

**The product defined in `RetroWheel.storekit`:**
```
Product ID: com.marcustrise.retrowheel.unlock
Type:       Non-Consumable  ← not a subscription
Price:      $4.99
Name:       Unlock RetroWheel
```

### First Launch
On first launch the app requests access to your music library. Tap **Allow** to connect your streaming library. For local-only playback, tap **Not Now** and grant local library access in Settings instead.

---

## App Store Submission Checklist

### App setup
- [ ] Bundle ID is `com.marcustrise.retrowheel` — set your **Team** in Signing & Capabilities
- [ ] Add a 1024×1024 app icon to `Assets.xcassets/AppIcon.appiconset/`
- [ ] Screenshot on 6.7-inch and 6.5-inch display sizes for the App Store listing
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
> **Free to download.** Play up to 3 tracks with the free tier to experience the retro wheel interface. Unlock everything permanently for a one-time $4.99 — no subscription, no recurring charges.

---

## Architecture Notes

- **MusicPlayerViewModel** is a single `@MainActor ObservableObject` injected at the root. It owns both the MusicKit music player (streaming) and `AVPlayer` (local files) and routes play calls to the correct engine based on the track source.
- **Song** is a unified value type wrapping either a MusicKit track or a local media item, so all views are source-agnostic.
- **RetroShellView** is 100% SwiftUI gradients and shapes — no image assets, no UIKit.
- Zero third-party dependencies.

### KeychainHelper

`KeychainHelper.swift` (≈60 lines, `Security.framework` only, no third-party dependencies) is included as reusable infrastructure and compiles cleanly. It is not called in the current build.

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
