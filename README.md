# Local Host Party Games

Cross-platform **Flutter** party games for Project **1234 Localhost** — **web**, **Android**, and **iOS**.

Colorful 2×3 tile menu, six 2-player-style minigames, pass-and-play, and **same-network-only** Local Host + QR. No accounts. No internet required for play.

> **Supersedes** the SwiftUI iOS prototype ([PR #1](https://github.com/code-vibes/localhost-party-games/pull/1)). Native sources live under [`archive/swiftui-ios/`](archive/swiftui-ios/).

## Games

| Tile | Game |
|------|------|
| 🏓 | Cup Pong |
| 🛞 | Wheelie |
| 🐱 | Animal Stack |
| 🏀 | Basketball Hoops |
| 🧠 | Brainrot Stack |
| 🏹 | Archery |

## Quick start

```bash
flutter pub get
flutter run -d chrome          # web
flutter run                    # connected device / emulator
```

### Release builds

```bash
flutter build web --release
flutter build apk --release    # → build/app/outputs/flutter-apk/app-release.apk
flutter build ios --no-codesign
# Signed iOS (Mac or CI with secrets):
flutter build ipa
```

### Local Host (LAN)

1. **Host** on Android/iOS (or CLI): start a Local Session → show QR / code.  
2. **Join** from another device on the same Wi‑Fi/hotspot via QR or code + host IP.  
3. Web browsers **cannot bind** the host socket — use a phone as host, or:

```bash
dart run tool/lan_host.dart
```

Protocol: HTTP + WebSocket on port **7423**. Deep link: `localhostparty://join?code=…&ip=…&port=7423`.

## iOS without your Mac

| Path | What you get |
|------|----------------|
| **GitHub Actions** `ios` job | Unsigned IPA artifact (`ios-unsigned-ipa`) |
| **Codemagic** (`codemagic.yaml`) | Signed build → TestFlight when Apple creds are set |
| **Actions + Apple secrets** | `flutter build ipa` in CI with signing |

You still need Apple Developer + a physical iPhone (or someone else's Mac) for a signed install. You do **not** need *your* Mac day-to-day once CI is wired.

## CI

Workflow template: [`docs/github-actions-build.yml`](docs/github-actions-build.yml)  
(copy to `.github/workflows/build.yml` once a token with the `workflow` scope can write Actions files). Builds:

- `web-build` — static site
- `android-apk` — release APK
- `ios-unsigned-ipa` — macOS runner, no codesign

Signed iOS / TestFlight: [`codemagic.yaml`](codemagic.yaml).

## Layout

```
lib/           Flutter app (UI, games, networking)
tool/          CLI LAN host for web demos
archive/       Archived SwiftUI iOS prototype
ios/ android/ web/   Flutter platform folders
codemagic.yaml Signed iOS / TestFlight path
```

## Design notes

Warm coral/cream palette, playful display type, full-bleed game canvases — inspired by casual 2 PLAYER GAMES tile menus. Local Host branding is first-class on home and lobby screens.
