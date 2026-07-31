# lib
> ← add description

<!-- routing:start -->
## Routing

| Subdirectory | Description |
|--------------|-------------|
| [`data/`](data/CONTEXT.md) | — |
| [`l10n/`](l10n/CONTEXT.md) | — |
| [`screens/`](screens/CONTEXT.md) | — |

| File | Interface | Description |
|------|-----------|-------------|
| [`main.dart`](main.dart) | [`main.dart.api`](main.dart.api) | App entry point: initializes Flutter, requests usage permissions, and routes to onboarding or home |
| [`main_screen.dart`](main_screen.dart) | [`main_screen.dart.api`](main_screen.dart.api) | Main scaffold: bottom navigation between Home, Monitoring, Analytics, Insights, and Settings tabs |
| [`models/goal_config.dart`](models/goal_config.dart) | [`models/goal_config.dart.api`](models/goal_config.dart.api) | / Goal level chosen by the user. |
| [`services/analytics_service.dart`](services/analytics_service.dart) | [`services/analytics_service.dart.api`](services/analytics_service.dart.api) | AnalyticsService: computes daily/weekly/monthly usage aggregates from StorageService data |
| [`services/app_info_service.dart`](services/app_info_service.dart) | [`services/app_info_service.dart.api`](services/app_info_service.dart.api) | AppInfoService: fetches app labels and launcher packages from the native platform channel |
| [`services/service_channel.dart`](services/service_channel.dart) | [`services/service_channel.dart.api`](services/service_channel.dart.api) | ServiceChannel: MethodChannel bridge to Kotlin OverlayService and MonitoringService |
| [`services/storage_service.dart`](services/storage_service.dart) | [`services/storage_service.dart.api`](services/storage_service.dart.api) | StorageService: typed SharedPreferences wrapper for screen time, goals, and settings |
| [`services/storage_service_queries.dart`](services/storage_service_queries.dart) | — | StorageService query helpers: weekday-pattern aggregation and data maintenance methods |
| [`services/storage_service_settings.dart`](services/storage_service_settings.dart) | — | StorageService extension: per-app control, onboarding, language, and goal level settings |
| [`theme/app_theme.dart`](theme/app_theme.dart) | [`theme/app_theme.dart.api`](theme/app_theme.dart.api) | App theme: color palette, text styles, and ThemeData for light and dark mode |
| [`utils/app_info.dart`](utils/app_info.dart) | [`utils/app_info.dart.api`](utils/app_info.dart.api) | App info utilities: three-tier app name resolution (PackageManager, curated map, package fallback) |
| [`utils/app_info_meta.dart`](utils/app_info_meta.dart) | — | Known app metadata: curated labels and brand colors (Tier 2 of the naming strategy) |
| [`utils/date_utils.dart`](utils/date_utils.dart) | [`utils/date_utils.dart.api`](utils/date_utils.dart.api) | Day-boundary helpers — all dates use the 4 AM anchor (hours 00–03 belong |
| [`utils/duration_format.dart`](utils/duration_format.dart) | [`utils/duration_format.dart.api`](utils/duration_format.dart.api) | Duration format helper: converts Duration to a human-readable hours/minutes string |
| [`utils/time_utils.dart`](utils/time_utils.dart) | [`utils/time_utils.dart.api`](utils/time_utils.dart.api) | / Formats milliseconds as a compact human-readable duration. |
| [`widgets/section_header.dart`](widgets/section_header.dart) | [`widgets/section_header.dart.api`](widgets/section_header.dart.api) | SectionHeader widget: styled section title bar used across multiple screens |
<!-- routing:end -->
