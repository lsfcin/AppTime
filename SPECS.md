# AppTime — Specs

## Setup

| Layer | Technology |
|-------|------------|
| UI | Flutter / Dart — Android only, min SDK 21 |
| Overlay + monitoring | Kotlin native services |
| Storage | SharedPreferences |

**Libraries:** shared_preferences ^2.3.3 · permission_handler ^12.0.1 · fl_chart ^0.70.2 · flutter_launcher_icons ^0.14.3 (dev)

**Android permissions:** SYSTEM_ALERT_WINDOW · PACKAGE_USAGE_STATS · FOREGROUND_SERVICE · FOREGROUND_SERVICE_SPECIAL_USE · REQUEST_IGNORE_BATTERY_OPTIMIZATIONS · POST_NOTIFICATIONS · RECEIVE_BOOT_COMPLETED

## Architecture

`Flutter UI ↔ SharedPreferences ← MonitoringService (foreground, Kotlin) → OverlayService (native View, 500ms poll)`

**Constraints — do not change without ADR**
- Flutter handles UI only; overlay and monitoring are pure Kotlin
- Communication via SharedPreferences pull, not EventChannel — avoids Flutter engine zombie state
- Overlay uses `WindowManager.addView()` with `START_STICKY` — no `flutter_overlay_window`
- Sessions tracked manually — never use `totalTimeInForeground` (excludes active session)
- Launchers treated as special mode, not regular apps
- Screen off = event type `SCREEN_NON_INTERACTIVE` → immediately flush and close active session

**Usage data strategy — why we do not use Android's native UsageStatsManager totals**
Android's `UsageStats.totalTimeInForeground` excludes the currently active (open) session,
which would make the live overlay display always lag by one session. We use `UsageEvents`
only to detect the *current* foreground app (1-min sliding window query), and accumulate
session durations ourselves in `daily_ms_{pkg}_{date}`. This gives us:
- Live accuracy: current session is always included in the displayed total
- No dependency on battery-intensive background queries
- Deterministic data: we control exactly what counts (screen-on + foreground only)
The tradeoff is that a service crash loses the in-progress session. This is acceptable:
we write to SharedPreferences on every app switch and on screen-off, so loss is bounded
to the interval since the last write (≤ the watchdog period, currently 30s).

**SharedPreferences keys**

| Key | Type | Description |
|-----|------|-------------|
| `overlay_text` | String | Text shown in overlay |
| `overlay_visible` | Boolean | Whether overlay should appear |
| `overlay_font_size` | Float | Overlay text size (10–30 sp) |
| `overlay_top_dp` | Float | Vertical offset from top of screen |
| `overlay_show_border` | Boolean | Whether to draw border around overlay |
| `overlay_show_background` | Boolean | Whether to draw background behind overlay |
| `daily_ms_{pkg}_{date}` | Long | Accumulated ms for app that calendar day |
| `open_count_{pkg}_{date}` | Int | App opens that calendar day |
| `unlock_count_{date}` | Int | Device unlocks that calendar day |
| `device_daily_ms_{date}` | Long | Total device usage that calendar day |
| `device_hourly_ms_{date}_{h}` | Long | Total device ms in hour h (0–23) |
| `hourly_opens_{pkg}_{date}_{h}` | Int | Per-app opens in hour h |
| `hourly_unlocks_{date}_{h}` | Int | Device unlocks in hour h |
| `session_bucket_{i}_{date}` | Int | Session count for bucket i (0=<1m 1=1-5m 2=5-15m 3=>15m) |
| `disabled_apps` | StringList | Packages with overlay disabled |
| `daily_goal_minutes` | Int | Legacy per-device goal (superseded by `goal_level`) |
| `onboarding_done` | Boolean | Whether onboarding has been completed |
| `language_code` | String? | `null`=system · `"pt"` · `"en"` |
| `goal_level` | Int | 0=none 1=minimal 2=normal 3=extensive |
| `app_goal_{pkg}` | Int | Per-app goal override; 0=inherit global |
| `current_pkg` | String | Foreground package right now (written each tick) |
| `current_session_start_ms` | Long | Epoch ms when current session began |

**Overlay display**
- Phase 0 (first 5s after open): open count → `"13x"`
- Phase 1 (after): cumulative time → `"0:45"` (`M:SS` if <1h, `H:MM` if ≥1h)
- On launcher — phase 0: unlocks (`"86x"`), phase 1: total device usage (`"2.3h"`)
- Overlay resilience: try-catch on addView/updateViewLayout resets `isViewAdded`; 30s watchdog restarts OverlayService

**MethodChannel** `"apptime/service"`: `startMonitoring` · `stopMonitoring` · `isRunning` · `requestOverlayPermission` · `hasOverlayPermission` · `requestUsagePermission` · `hasUsagePermission`

## Screens

| Screen | Description |
|--------|-------------|
| `OnboardingScreen` | First-launch flow: welcome → overlay permission → usage permission. Auto-detects grants via `WidgetsBindingObserver`. |
| `HomeScreen` | Rotating "Insight do dia" card + monitoring summary card |
| `AnalyticsScreen` | 3-tab layout: 24h (sleep hygiene, impulsivity, focus, phubbing, opportunity cost) · 7d (trends, dopamine drain, engagement balance) · 30d (line chart, weekend spike heatmap) |
| `InsightsScreen` | 2-tab layout: Alertas + Soluções — 40 PT-BR research-backed cards |
| `SettingsScreen` | Overlay appearance, per-app toggle, Goals tile |
| `GoalScreen` | Global goal level selector (4 cards with rationale + threshold chips) + per-app goal override dropdown table |
| `PerAppScreen` | Enable/disable overlay per package |

## Features

| Feature | Status |
|---------|--------|
| Native floating overlay — open count + cumulative time | ✓ |
| Background app monitoring + session tracking | ✓ |
| Screen-off detection / launcher special mode | ✓ |
| Overlay resilience — watchdog + try-catch recovery | ✓ |
| Hourly usage breakdown (device + per-app + unlocks) | ✓ |
| Session duration bucketing (<1m · 1-5m · 5-15m · >15m) | ✓ |
| Rolling 24h window (analytics) | ✓ |
| OnboardingScreen — permission flow | ✓ |
| HomeScreen — rotating daily insight | ✓ |
| AnalyticsScreen — 9 analysis blocks across 3 tabs | ✓ |
| InsightsScreen — 40 PT-BR research cards | ✓ |
| SettingsScreen — appearance, goals, per-app control | ✓ |
| Adaptive launcher icon | ✓ |
| BootReceiver — service auto-start after reboot | ✓ |
| Language support (pt-BR / en-US i18n) | ✓ |
| Goal tiers (GoalThresholds.kt + goal_config.dart, 3 levels × 6 metrics) | ✓ |
| F.BN Breathing Nudge — random alpha cycle via Handler + ObjectAnimator | ✓ |
| F.VW Visual Weight — overlay scale 1.0→1.2 as usage climbs 80%→200% of limit | ✓ |
| F.PM Personalized Message — centred WindowManager overlay, 3s fade-in/10s/3s fade-out, 60s cooldown | ✓ |
| Per-app goal overrides (app_goal_{pkg}, evaluated in OverlayService) | ✓ |
| GoalScreen — level selector + per-app goal table | ✓ |

## Conventions

**Theme:** primary #4F6EF7 · primaryDark #3A55D4 · surface #F7F8FC / #1A1D2E · card white / #242740 · success #34D399 · error #F87171

Spacing: XS=4 SM=8 MD=16 LG=24 XL=32 · Radius: SM=8 MD=12 LG=16 XL=24 · Material3, light/dark auto, cards elevation 0 with thin border
