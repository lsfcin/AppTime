# AppTime

Android app to reduce phone addiction through awareness — without blocking or punishing a native floating overlay shows real-time session counts and cumulative screen time for the active app and provide analytics.

## Setup

Android only · min SDK 21 · Flutter (UI) + Kotlin (overlay + monitoring)

## Architecture

`Flutter UI → SharedPreferences ← MonitoringService (Kotlin) → OverlayService (Kotlin)`
`BootReceiver (Kotlin) → starts MonitoringService on device reboot`

Full module breakdown, interfaces, and constraints → [SPECS.md](SPECS.md)
Roadmap and pending milestones → [ROADMAP.md](ROADMAP.md)
Completed milestones → [HISTORY.md](HISTORY.md)

## Status

| Item | Value |
|------|-------|
| Phase | In dev |
| Last milestone | M17 Persistent Bugs + hour-split fix ✓ |
| Next | M18 Prepare to PlayStore submission |
