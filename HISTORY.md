# AppTime — Condensed History

## M8 — Core fixes and monitoring model
x Stabilized overlay persistence; treated disappearance as a critical bug.
x Reworked overlay positioning/configuration: fixed directional placement issues, considered simpler top-center fallback, and explored alignment with the clock bar.
x Fixed or removed unreliable UI controls: font size, border toggle, and vertical/horizontal displacement.
x Investigated unblock counting, foreground-only usage accounting, and screen-locked usage inflation.
x Evaluated Android-native usage data vs. custom tracking for higher precision.
x Changed reporting concept from “Today” to “24h”.

## M9 — Polish
x Added “Insight of the day” on HomeScreen with ~50 PT-BR texts and 3-minute rotation.
x Confirmed/checked adaptive launcher icon support.
x Documented edge cases: MIUI home behavior, reboot auto-start limitation, and active session rollover.

## M10 — Analysis blocks
x Redesigned Analysis into 3 subtabs: 24h, 7 days, 30 days.
x Added 9 analysis blocks:
  x Sleep Hygiene and Circadian Rhythm
  x Impulsivity Index / Checking Habit
  x Focus Fragmentation
  x Engagement Balance
  x Dopamine Drain
  x Relapse and Trend Analysis
  x Opportunity Cost
  x Weekend Spike Pattern
  x Phubbing Alert
x Added new SharedPreferences schema for hourly usage, opens, unlocks, and session-duration buckets.

## M11 — Insights
x Built `InsightsScreen` with two tabs: **Alertas** and **Soluções**.
x Added 40 research-backed PT-BR cards across themes like impulsivity, sleep, focus, passive consumption, physical health, social impact, habit change, recovery, and environment.
x Added rotating HomeScreen insight card linked to `lib/data/insights.dart`.

## M12 — Permissions onboarding
x Added first-launch onboarding and permission gating.
x Step flow:
  x Welcome
  x Overlay permission (`SYSTEM_ALERT_WINDOW`)
  x Usage Stats permission (`PACKAGE_USAGE_STATS`)
x Auto-advances after permission grants and skips on later launches when both permissions are already granted.

## M13 — Language support
x Added manual i18n system via `AppLocalizations` (no codegen).
x Implemented PT-BR and EN-US localization files.
x Added `flutter_localizations` and persisted language choice via `StorageService.languageCode`.
x Auto-detects system locale on first launch.
x Migrated all 6 screens away from hardcoded strings.

## M14 — Goals and dynamic overlay
x Added goal tiers in Kotlin + Dart mirrors: minimal, normal, extensive.
x Defined goal thresholds for 6 metrics: phone time, app time, unlocks, session, sleep cutoff, wakeup hour.
x Added 6 predefined personalized-message scenarios.
x Rewrote overlay feedback into 3 behaviors:
  x Breathing Nudge
  x Visual Weight
  x Personalized Message
x Added per-app goal overrides and a new GoalScreen with research rationale and threshold chips.
x Moved goal access into Settings.
x Added goal-related localization strings.

## M15 — Fixes and refinements
x Investigated missing unblocks; issue persisted.
x Reworked personalized messages:
  x same position as overlay
  x no final dot
  x lower-case start
  x stronger, shorter copy
  x longer display time
x Ensured timer overlay should remain visible except when replaced by another message.
x Changed Insights UI to carousel-style one-at-a-time browsing and ordered cards by relevance.
x Added request for valid hyperlinks in insights.
x Tweaked engagement classification card, including clearer classification explanation and smaller donut chart.
x Replaced the weak weekend pattern analysis with a detailed weekly grid/horizontal stacked-hour view.
x Added anti-double-counting tolerance for quick app reopens/reinitializations.
x Investigated overlay touch interception.
x Ensured overlay time displays seconds even after 1 hour.
x Reworked per-app control to list all apps with sorting and per-app monitoring/goal options.

## M16 — More fixes and structural changes
x Made overlay effectively always visible unless the app is unmonitored or the launcher/home screen is intentionally excluded.
x Added a setting to monitor or ignore the home screen/launcher.
x Fixed PM text clipping and sizing.
x Fixed launcher usage inflation caused by mixing days in the rolling window.
x Localized the engagement balance text.
x Renamed and corrected week-pattern visualization logic, including fill proportionality, top-5 app visibility, and “other apps” handling.
x Added 30-day retention pruning to keep bounded storage.
x Introduced a 4am day boundary instead of midnight.
x Renamed 24h analytics context to “Today” and made it truly same-day-only.
x Separated “monitoring on/off” from overlay visibility.
x Fixed insights link behavior and improved reference formatting.
x Moved goals into a dedicated Monitoring tab and consolidated per-app control there.
x Cleaned per-app goal list: hid system/background apps, improved app names, and added icons.
x Adjusted home-screen unlock behavior to avoid confusing immediate counts after navigation-button transitions.
x Corrected PM trigger timing so context-specific messages fire at the right moment.
x Expanded insights coverage requests for brain-rot and phone-vs-drug addiction comparisons, with both diagnosis and strategy-focused cards.

## M19 — Security and privacy hardening
x Added `android:usesCleartextTraffic="false"` to manifest.
x Added 90-day automatic data pruning on app start (`StorageService.pruneOldData`).
x Added "Delete all data" action in Settings → Data & Privacy.
x Drafted privacy policy HTML at `docs/privacy_policy.html`; linked from Settings.
x Verified overlay `FLAG_NOT_TOUCHABLE` — confirmed non-intercepting.
x Code review: logged 3 findings in ROADMAP (dead permission, BootReceiver export gap, `parseDisabledApps` silent failure).

## M18 — Navigation, analytics, and UX polish
x Settings tab moved to first (left-most) position.
x Auto-starts monitoring on first launch once permissions are granted.
x Control level terminology standardized: Off / Light / Moderate / Intense.
x Per-app chip labels fixed (were showing "min"/"max" instead of renamed levels).
x `com.google.android.googlequicksearchbox` treated as launcher (excluded from per-app lists, overlay follows launcher rules).
x App colors: Threads and ChatGPT use black (B&W icon apps); AI Studio added.
x Overlay simplified: timer-only display, no count phase, no delays or fades; show/hide is immediate.
x Overlay correctly hidden on apps the user marks as unmonitored (fixed cross-process `disabledApps` encoding: `setStringList` → JSON via `setString`).
x Analytics: yesterday pattern and last-7-days pattern charts added (horizontal stacked bars, per-hour rows, per-app colors).
x Horizontal time axis (0 → 1h) added to both pattern charts.
x Per-app usage caption shows 7-day total.
x `_debugCheckColorConflicts` moved to once-per-session (was causing 172-frame skips on every rebuild).
x Gap backfill on service restart: replays `UsageEvents` for periods when service was not running.

## M17 — Persistent bugs and final hardening
x Confirmed/fixed top-5 app chart behavior: top 5 by usage with distinct colors and caption; remaining apps collapsed into “other”.
x Restored access to Per-app control through Settings.
x Fixed overlay font-size slider by reading the value continuously instead of only once at service startup.
x Removed the vertical position slider entirely.
x Fixed timer disappearing while using AppTime itself by properly canceling the breathing animation before alpha changes.
x Fixed overlay disappearance after long use in the same app by falling back to the last known package when UsageEvents returns null.
x Replaced technical terms like “overlay” and “launcher” with PT-BR user-friendly wording.
x Fixed launcher counters freezing or inflating past 21h by flushing sessions on screen-off, guarding with `isInteractive()`, and repairing corrupted values on startup.
x Fixed hour×weekday heatmap accuracy by distributing each session across the correct hourly buckets using start/end accumulation.
x Added 4am-aligned date handling to support more realistic daily boundaries and consistent analytics.

## Milestone — Security and privacy check

x Point core security issues apps may impose on users

x Assess which of those are relevant to our app/context

x Add all relevant points to this milestone and go fix or propose solutions, one by one.

### Relevant issues and fixes

x `android:usesCleartextTraffic="false"` — declare in AndroidManifest; proves to Play scanners no network communication is possible

x Data retention — auto-delete SharedPreferences keys older than 90 days on app start; prevents unbounded accumulation of sensitive usage history

x Delete all data — add a "Delete all data" action in Settings so the user can wipe their history at any time (right to erasure, expected by Play reviewers)

x Privacy policy — draft a minimal policy (data stays on-device, no network, no third parties); host on GitHub Pages; link from Settings and store listing
  x Hosted at https://lsfcin.github.io/apptime/privacy_policy.html

x Overlay clickjacking — verify FLAG_NOT_TOUCHABLE is set on the overlay window; confirm overlay cannot intercept user input (already implemented — mark after verification)

x Encrypted storage — deferred post-launch; EncryptedSharedPreferences requires migrating both Flutter plugin and Kotlin service; revisit if Play rejects

x Perform a major code review checking for possible hacker/malicious activities. Injections, don't know, it is not my area, but we must review our code thorouglhy to guarantee with the best of our knowledge that our app is safe. If you find any points then do not fix it yet, place bullets here.

### Code review findings

x Dead permission `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` in AndroidManifest — declared but never called in code. Play Store reviewers will demand justification for every dangerous permission; remove it.

x `BootReceiver` exported without `android:permission` guard — `BOOT_COMPLETED` is a protected broadcast (only OS can send it), but `QUICKBOOT_POWERON` is a vendor-custom action; any app on the device could broadcast it and unexpectedly start MonitoringService. Fix: add `android:permission="android.permission.RECEIVE_BOOT_COMPLETED"` to the receiver declaration in the manifest.

x `parseDisabledApps` swallows all JSON exceptions silently returning `emptySet()` — corrupted or tampered SharedPreferences data (rooted device) would silently re-enable the overlay on all apps the user disabled. Fix: validate that every element of the decoded array is a non-empty string matching a package-name pattern before trusting it.
