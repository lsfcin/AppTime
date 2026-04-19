# AppTime — Condensed History

## M8 — Core fixes and monitoring model
- Stabilized overlay persistence; treated disappearance as a critical bug.
- Reworked overlay positioning/configuration: fixed directional placement issues, considered simpler top-center fallback, and explored alignment with the clock bar.
- Fixed or removed unreliable UI controls: font size, border toggle, and vertical/horizontal displacement.
- Investigated unblock counting, foreground-only usage accounting, and screen-locked usage inflation.
- Evaluated Android-native usage data vs. custom tracking for higher precision.
- Changed reporting concept from “Today” to “24h”.

## M9 — Polish
- Added “Insight of the day” on HomeScreen with ~50 PT-BR texts and 3-minute rotation.
- Confirmed/checked adaptive launcher icon support.
- Documented edge cases: MIUI home behavior, reboot auto-start limitation, and active session rollover.

## M10 — Analysis blocks
- Redesigned Analysis into 3 subtabs: 24h, 7 days, 30 days.
- Added 9 analysis blocks:
  - Sleep Hygiene and Circadian Rhythm
  - Impulsivity Index / Checking Habit
  - Focus Fragmentation
  - Engagement Balance
  - Dopamine Drain
  - Relapse and Trend Analysis
  - Opportunity Cost
  - Weekend Spike Pattern
  - Phubbing Alert
- Added new SharedPreferences schema for hourly usage, opens, unlocks, and session-duration buckets.

## M11 — Insights
- Built `InsightsScreen` with two tabs: **Alertas** and **Soluções**.
- Added 40 research-backed PT-BR cards across themes like impulsivity, sleep, focus, passive consumption, physical health, social impact, habit change, recovery, and environment.
- Added rotating HomeScreen insight card linked to `lib/data/insights.dart`.

## M12 — Permissions onboarding
- Added first-launch onboarding and permission gating.
- Step flow:
  - Welcome
  - Overlay permission (`SYSTEM_ALERT_WINDOW`)
  - Usage Stats permission (`PACKAGE_USAGE_STATS`)
- Auto-advances after permission grants and skips on later launches when both permissions are already granted.

## M13 — Language support
- Added manual i18n system via `AppLocalizations` (no codegen).
- Implemented PT-BR and EN-US localization files.
- Added `flutter_localizations` and persisted language choice via `StorageService.languageCode`.
- Auto-detects system locale on first launch.
- Migrated all 6 screens away from hardcoded strings.

## M14 — Goals and dynamic overlay
- Added goal tiers in Kotlin + Dart mirrors: minimal, normal, extensive.
- Defined goal thresholds for 6 metrics: phone time, app time, unlocks, session, sleep cutoff, wakeup hour.
- Added 6 predefined personalized-message scenarios.
- Rewrote overlay feedback into 3 behaviors:
  - Breathing Nudge
  - Visual Weight
  - Personalized Message
- Added per-app goal overrides and a new GoalScreen with research rationale and threshold chips.
- Moved goal access into Settings.
- Added goal-related localization strings.

## M15 — Fixes and refinements
- Investigated missing unblocks; issue persisted.
- Reworked personalized messages:
  - same position as overlay
  - no final dot
  - lower-case start
  - stronger, shorter copy
  - longer display time
- Ensured timer overlay should remain visible except when replaced by another message.
- Changed Insights UI to carousel-style one-at-a-time browsing and ordered cards by relevance.
- Added request for valid hyperlinks in insights.
- Tweaked engagement classification card, including clearer classification explanation and smaller donut chart.
- Replaced the weak weekend pattern analysis with a detailed weekly grid/horizontal stacked-hour view.
- Added anti-double-counting tolerance for quick app reopens/reinitializations.
- Investigated overlay touch interception.
- Ensured overlay time displays seconds even after 1 hour.
- Reworked per-app control to list all apps with sorting and per-app monitoring/goal options.

## M16 — More fixes and structural changes
- Made overlay effectively always visible unless the app is unmonitored or the launcher/home screen is intentionally excluded.
- Added a setting to monitor or ignore the home screen/launcher.
- Fixed PM text clipping and sizing.
- Fixed launcher usage inflation caused by mixing days in the rolling window.
- Localized the engagement balance text.
- Renamed and corrected week-pattern visualization logic, including fill proportionality, top-5 app visibility, and “other apps” handling.
- Added 30-day retention pruning to keep bounded storage.
- Introduced a 4am day boundary instead of midnight.
- Renamed 24h analytics context to “Today” and made it truly same-day-only.
- Separated “monitoring on/off” from overlay visibility.
- Fixed insights link behavior and improved reference formatting.
- Moved goals into a dedicated Monitoring tab and consolidated per-app control there.
- Cleaned per-app goal list: hid system/background apps, improved app names, and added icons.
- Adjusted home-screen unlock behavior to avoid confusing immediate counts after navigation-button transitions.
- Corrected PM trigger timing so context-specific messages fire at the right moment.
- Expanded insights coverage requests for brain-rot and phone-vs-drug addiction comparisons, with both diagnosis and strategy-focused cards.

## M17 — Persistent bugs and final hardening
- Confirmed/fixed top-5 app chart behavior: top 5 by usage with distinct colors and caption; remaining apps collapsed into “other”.
- Restored access to Per-app control through Settings.
- Fixed overlay font-size slider by reading the value continuously instead of only once at service startup.
- Removed the vertical position slider entirely.
- Fixed timer disappearing while using AppTime itself by properly canceling the breathing animation before alpha changes.
- Fixed overlay disappearance after long use in the same app by falling back to the last known package when UsageEvents returns null.
- Replaced technical terms like “overlay” and “launcher” with PT-BR user-friendly wording.
- Fixed launcher counters freezing or inflating past 21h by flushing sessions on screen-off, guarding with `isInteractive()`, and repairing corrupted values on startup.
- Fixed hour×weekday heatmap accuracy by distributing each session across the correct hourly buckets using start/end accumulation.
- Added 4am-aligned date handling to support more realistic daily boundaries and consistent analytics.