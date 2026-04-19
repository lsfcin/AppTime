# AppTime

**Screen-time awareness without blocking.** AppTime shows, in real time, how many times you opened each app and how long you've spent on it — right on your screen, like a discreet clock.

No app blocking. No punishments. Just honest visibility into your own habits.

---

## What it does

- **Floating overlay** — a small counter follows you across every app, showing the current app's daily usage time
- **Goal system** — four control levels (Off / Light / Moderate / Intense) trigger gentle behavioral nudges: breathing animations, visual weight scaling, and research-backed messages
- **Analytics** — daily, 7-day, and 30-day views with hourly usage patterns, focus fragmentation, dopamine drain, engagement balance, sleep hygiene, and trend analysis
- **Insights** — two tabs (Alerts / Solutions) with 40+ research-backed cards on habit change, focus, sleep, and social impact
- **Per-app control** — enable/disable overlay and set goal levels per app independently

## Privacy

All data stays **on your device**. No network calls. No analytics SDKs. No cloud sync. No servers.

Usage records are automatically deleted after 90 days. You can wipe all history at any time from Settings → Data & Privacy.

[Privacy policy](docs/privacy_policy.html)

## Architecture

```
Flutter UI ──→ SharedPreferences ←── MonitoringService (Kotlin)
                                           │
                                     OverlayService (Kotlin)
                                           │
                                     BootReceiver (Kotlin)
```

- **Flutter** handles all UI, settings, analytics rendering, and localization (PT-BR / EN)
- **MonitoringService** polls `UsageStatsManager` every second, accumulates per-app and per-hour usage into SharedPreferences, and writes overlay text
- **OverlayService** reads SharedPreferences every 500 ms and updates the `TYPE_APPLICATION_OVERLAY` window; overlay is non-touchable (`FLAG_NOT_TOUCHABLE`) and cannot intercept user input
- **BootReceiver** restarts monitoring after reboot

Full module breakdown, interfaces, and SharedPreferences schema → [SPECS.md](SPECS.md)

## Permissions

| Permission | Why |
|---|---|
| `PACKAGE_USAGE_STATS` | Reads which app is in the foreground to track usage time |
| `SYSTEM_ALERT_WINDOW` | Draws the floating usage counter over other apps |
| `FOREGROUND_SERVICE` | Keeps monitoring running while the screen is on |
| `RECEIVE_BOOT_COMPLETED` | Restarts monitoring after a device reboot |

## Build

Requires Flutter 3.x and Android SDK ≥ 21.

```bash
flutter pub get
flutter run          # debug on connected device
flutter build apk    # release APK
```

## Status

| | |
|---|---|
| Phase | Pre-release — security & Play Store prep |
| Last milestone | M19 — Security & privacy hardening |
| Next | Play Store submission |

Roadmap → [ROADMAP.md](ROADMAP.md) · History → [HISTORY.md](HISTORY.md)
