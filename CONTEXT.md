# AppTime

Android app to reduce phone addiction through awareness — without blocking. A native floating overlay shows real-time session time for the active app and delivers behavioral nudges based on configurable goal levels.

## Setup

Android only · min SDK 21 · Flutter (UI) + Kotlin (overlay + monitoring)

## Architecture

`Flutter UI → SharedPreferences ← MonitoringService (Kotlin) → OverlayService (Kotlin)`
`BootReceiver (Kotlin) → starts MonitoringService on device reboot`

Full module breakdown, interfaces, and constraints → [SPECS.md](SPECS.md)
Roadmap and pending milestones → [ROADMAP.md](ROADMAP.md)
Completed milestones → [HISTORY.md](HISTORY.md)

## Current feature set

- Overlay: `TYPE_APPLICATION_OVERLAY`, `FLAG_NOT_TOUCHABLE`, shows daily timer per app; hidden on unmonitored apps and (optionally) the launcher
- Goal system: 4 levels (Off/Light/Moderate/Intense) → breathing nudge, visual weight, personalized messages; per-app overrides
- Analytics: 1d/7d/30d tabs; hourly stacked-bar pattern charts (yesterday + last 7 days); sleep hygiene, focus fragmentation, engagement balance, dopamine drain, weekly trend, 30-day trend
- Insights screen: 40+ research-backed cards in Alerts and Solutions tabs
- Per-app control: enable/disable overlay per app; goal level override per app
- Storage: SharedPreferences via Flutter plugin (`FlutterSharedPreferences` namespace); data auto-pruned after 90 days; delete-all action in Settings
- i18n: PT-BR + EN, auto-detect from system, manual override in Settings
- Privacy: no network, no analytics SDKs; `usesCleartextTraffic=false`; privacy policy at `docs/privacy_policy.html`

## Key constraints

- Day boundary is 04:00 (not midnight) — affects all date keys and analytics windows
- SharedPreferences keys use `flutter.` prefix (Flutter plugin adds it); Kotlin reads them with that prefix directly
- Integer values stored as `Long` by Flutter plugin on Android — Kotlin must use `getLong()`, not `getInt()`
- `disabledApps` stored as JSON string via `setString` (not `setStringList`) for cross-process compatibility
- `com.google.android.googlequicksearchbox` is treated as a launcher (excluded from per-app lists, overlay follows launcher rules)

## Status

| Item | Value |
|------|-------|
| Phase | Pre-release — security & Play Store prep |
| Last milestone | M19 — Security & privacy hardening ✓ |
| Next | Play Store submission (see ROADMAP) |
