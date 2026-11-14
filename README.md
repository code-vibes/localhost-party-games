# Local Host Party Games

A native **SwiftUI** iOS party-games app inspired by colorful “1234 Player Games” tile menus — with **same-phone pass-and-play** and **Local Host** multiplayer over Wi‑Fi / personal hotspot (MultipeerConnectivity + QR join).

## Open in Xcode

1. Clone this repo on a Mac.
2. Open `LocalHostPartyGames/LocalHostPartyGames.xcodeproj` in Xcode 15+.
3. Select an iPhone Simulator or a physical device (Local Host / QR camera needs a device for real multiplayer).
4. Set your **Signing Team** in the target’s Signing & Capabilities tab.
5. Build & run (`⌘R`).

**Requirements:** iOS 17+, Xcode 15+.

## What’s included (v1)

### Flow
Home → player count (1–4) → colorful game grid → playable minigames.

### Games (2P grid, playable stubs / simple gameplay)
1. **Cup Pong** — drag-and-release throws into a cup triangle  
2. **Wheelie** — hold balance in the green zone  
3. **Animal Stack** — drop animals; don’t topple  
4. **Basketball Hoops** — timed swipe shots  
5. **Brainrot Stack** — chaotic drop stack  
6. **Archery** — charge / release for bullseye points  

Session win counters sit on the red/blue (and extra) avatars under the 2P-style grid.

### Local Host multiplayer
- **Host Local Session** — advertises a Bonjour / Multipeer service (`lhost-party`), shows a **4-letter code** + **QR** (`localhostparty://join?...`).
- **Join via QR / LAN** — scan QR or type the code; browser invites the matching host on the same Wi‑Fi / hotspot.
- Lobby lists players, lets the host pick any of the six games, then launches play.
- **Sync MVP:** lobby + start signals for all games; deeper per-frame input sync is prioritized for Cup Pong & Animal Stack next.

Permissions used: Local Network, Bonjour (`_lhost-party._tcp`), Camera (QR).

## Architecture

| Area | Role |
|------|------|
| `Core/GameRegistry.swift` | Add new games by appending a `GameDefinition` + view in `GameContainerView` |
| `UI/` | Home, player count, tile grid matching the flat colorful reference art |
| `Games/` | One folder per minigame |
| `Networking/` | `LocalHostController` (Multipeer), QR generate/scan, lobby UI |

## What runs without a Mac

On this Linux cloud agent you can:
- Read / edit Swift sources  
- Create the GitHub repo and push  

You **cannot** compile, Simulator-run, or device-test the iOS app without Xcode on macOS.

## Try next on a Mac

1. Run in Simulator — walk Home → 2 Players → each of the six games.  
2. On two physical iPhones on the same hotspot: Host on one, Join/QR on the other, confirm lobby roster.  
3. Add your Apple Developer team, then install on device for camera QR.  
4. Extend `LocalHostMessage.gameEvent` for live Cup Pong / Animal Stack sync.
