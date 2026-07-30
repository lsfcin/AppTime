# AppTime
> Android app to reduce phone addiction through awareness, without blocking
> goal: [startapps-apptime](../../brain/goals/startapps-apptime.md)

Android app to reduce phone addiction through awareness — without blocking. A native floating overlay shows real-time session time for the active app and delivers behavioral nudges based on configurable goal levels.

## Setup

Android only · min SDK 23 · Flutter (UI) + Kotlin (overlay + monitoring). Full dev environment: [SETUP.md](SETUP.md)

## Architecture

`Flutter UI → SharedPreferences ← MonitoringService (Kotlin) → OverlayService (Kotlin)`
`BootReceiver (Kotlin) → starts MonitoringService on device reboot`

**Code structure, architecture constraints, SharedPreferences schema, and MethodChannel API → [SPECS.md](SPECS.md)**
  - Consult SPECS.md before editing any module — it maps responsibilities, data flow, SharedPreferences keys, and cross-cutting invariants.
  - Update SPECS.md whenever a module's responsibility, data flow, or key schema changes.

Roadmap and pending milestones → [ROADMAP.md](ROADMAP.md)

## Current feature set

- Overlay: `TYPE_APPLICATION_OVERLAY`, `FLAG_NOT_TOUCHABLE`, shows daily timer per app; hidden on unmonitored apps and (optionally) the launcher; timer-only display, immediate show/hide
- Goal system: 4 levels (Off/Light/Moderate/Intense) → breathing nudge, visual weight, personalized messages; per-app overrides
- Analytics: 1d/7d/30d tabs; hourly stacked-bar pattern charts (yesterday + last 7 days); sleep hygiene, focus fragmentation, engagement balance, dopamine drain, weekly trend, 30-day trend
- Insights screen: 40+ research-backed bilingual (PT+EN) cards in Alerts and Solutions tabs
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

## File Map

**Flutter / Dart (`lib/`)**

- `main.dart` — app entry point; initializes Flutter binding and root widget
- `main_screen.dart` — root navigation shell with bottom navigation bar
- `models/goal_config.dart` — GoalConfig model; goal level enum and per-app overrides
- `services/storage_service.dart` — all SharedPreferences reads/writes; single source of persisted state
- `services/service_channel.dart` — MethodChannel bridge to Kotlin MonitoringService
- `services/analytics_service.dart` — computes usage statistics from raw SharedPreferences data
- `services/app_info_service.dart` — queries installed app metadata from the OS
- `screens/home_screen.dart` — home tab; today's usage summary and quick controls
- `screens/monitoring_screen.dart` — per-app enable/disable and goal override list
- `screens/goal_screen.dart` — global goal level selection (Off/Light/Moderate/Intense)
- `screens/settings_screen.dart` — language toggle, data management, delete-all
- `screens/onboarding_screen.dart` — first-run permissions and setup flow
- `screens/per_app_screen.dart` — per-app detail with usage history and goal override
- `screens/analytics/analytics_screen.dart` — analytics tab shell; day/week/month tab controller
- `screens/analytics/analytics_helpers.dart` — shared computation helpers for all analytics tabs
- `screens/analytics/tab_day.dart` — 1-day hourly chart and daily summary
- `screens/analytics/tab_week.dart` — 7-day trend view
- `screens/analytics/tab_month.dart` — 30-day trend view
- `screens/analytics/classification_message.dart` — behavioral classification message widget
- `screens/insights/insights_screen.dart` — insights tab; research-backed card browser
- `screens/insights/insight_data.dart` — insight card data model and category definitions
- `data/insights.dart` — insight card list (category, tab assignment, content reference)
- `data/insight_content.dart` — full bilingual (PT+EN) text content for insight cards
- `theme/app_theme.dart` — ThemeData; colors, typography, component styles
- `utils/date_utils.dart` — date helpers respecting the 04:00 day boundary
- `utils/time_utils.dart` — time formatting and session duration helpers
- `utils/duration_format.dart` — human-readable duration strings
- `utils/app_info.dart` — app metadata and package name helpers
- `widgets/section_header.dart` — reusable section header widget
- `l10n/app_localizations.dart` — generated base localization class (do not edit manually)
- `l10n/app_localizations_en.dart` — English strings
- `l10n/app_localizations_pt.dart` — Portuguese (PT-BR) strings

**Kotlin (`android/app/src/main/kotlin/com/lsf/apptime/`)**

- `MonitoringService.kt` — foreground service; tracks active app via UsageStatsManager; writes session data to SharedPreferences
- `OverlayService.kt` — manages TYPE_APPLICATION_OVERLAY window; shows/hides timer overlay; reads SharedPreferences
- `MainActivity.kt` — Flutter host activity; registers MethodChannels; requests PACKAGE_USAGE_STATS and overlay permissions
- `BootReceiver.kt` — BroadcastReceiver; auto-starts MonitoringService on BOOT_COMPLETED
- `FeedbackEngine.kt` — computes nudge messages and overlay visual behavior from goal level and usage duration
- `GoalThresholds.kt` — goal level constants and time thresholds (Off/Light/Moderate/Intense)
- `AppConstants.kt` — shared constants: SharedPreferences keys, MethodChannel names
- `DateUtils.kt` — date key computation with 04:00 day boundary
- `HistoryBackfill.kt` — backfills missing historical data from UsageStatsManager on first launch
- `PmMessages.kt` — behavioral nudge message string pools

## Status

| Item | Value |
|------|-------|
| Phase | Pre-release — Play Store submission pending |
| Last milestone | Optimization ✓ |
| Next | Play Store submission (see ROADMAP) |

<!-- routing:start -->
## Routing

| Subdirectory | Description |
|--------------|-------------|
| [`lib/`](lib/CONTEXT.md) | — |
| [`refs/`](refs/CONTEXT.md) | Captured references for apptime — tier-1 links in [REFS.md](REFS.md); promote to |

| File | Interface | API | Description |
|------|-----------|-----|-------------|
| [`README.md`](README.md) | — | — | AppTime |
| [`ROADMAP.md`](ROADMAP.md) | — | — | AppTime — Roadmap |
| [`SETUP.md`](SETUP.md) | — | — | AppTime Setup |
| [`SPECS.md`](SPECS.md) | — | — | AppTime — Code Structure & Reference |
| [`analysis_options.yaml`](analysis_options.yaml) | — | — | This file configures the analyzer, which statically analyzes Dart code to |
| [`docs/privacy_policy.html`](docs/privacy_policy.html) | — | — | ← add first-line comment |
| [`docs/store_listing.md`](docs/store_listing.md) | — | — | AppTime — Play Store Listing Copy |
| [`flutter_launcher_icons.yaml`](flutter_launcher_icons.yaml) | — | — | ← add first-line comment |
| [`pubspec.yaml`](pubspec.yaml) | — | — | ← add first-line comment |
| [`test/goal_thresholds_test.dart`](test/goal_thresholds_test.dart) | [`test/goal_thresholds_test.dart.api`](test/goal_thresholds_test.dart.api) | — | Asserts that GoalThresholds.byLevel (Dart) matches GoalThresholds.kt (Kotlin). |
| [`test/widget_test.dart`](test/widget_test.dart) | [`test/widget_test.dart.api`](test/widget_test.dart.api) | — | ← add first-line comment |
<!-- routing:end -->
