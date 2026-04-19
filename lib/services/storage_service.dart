import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper tipado sobre SharedPreferences.
/// Também é a interface de leitura/escrita usada pelos serviços Kotlin via prefs nativas.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  // ── Overlay state (escrito pelo MonitoringService Kotlin, lido pelo OverlayService) ──

  String get overlayText => _prefs.getString('overlay_text') ?? '';
  set overlayText(String v) => _prefs.setString('overlay_text', v);

  bool get overlayVisible => _prefs.getBool('overlay_visible') ?? false;
  set overlayVisible(bool v) => _prefs.setBool('overlay_visible', v);

  // ── Overlay appearance (escrito pelo Flutter, lido pelo OverlayService) ──

  // Stored as Int so the Kotlin OverlayService can read it with getInt() reliably.
  // Handles legacy double values that may be stored from older builds.
  double get overlayFontSize {
    final raw = _prefs.get('overlay_font_size');
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    return 14.0;
  }
  set overlayFontSize(double v) => _prefs.setInt('overlay_font_size', v.round());

  double get overlayTopDp => _prefs.getDouble('overlay_top_dp') ?? 40.0;
  set overlayTopDp(double v) => _prefs.setDouble('overlay_top_dp', v);

  bool get overlayShowBorder => _prefs.getBool('overlay_show_border') ?? false;
  set overlayShowBorder(bool v) => _prefs.setBool('overlay_show_border', v);

  bool get overlayShowBackground => _prefs.getBool('overlay_show_background') ?? false;
  set overlayShowBackground(bool v) => _prefs.setBool('overlay_show_background', v);

  /// Controls whether the floating overlay is shown at all.
  /// Monitoring (data collection) continues regardless of this flag.
  bool get overlayEnabled => _prefs.getBool('overlay_enabled') ?? true;
  set overlayEnabled(bool v) => _prefs.setBool('overlay_enabled', v);

  // ── Session data (escrito pelo MonitoringService Kotlin) ──

  /// The "day" starts at 04:00. Hours 00–03 belong to the previous calendar day,
  /// matching the 4 AM day-boundary used by the Kotlin monitoring service.
  DateTime _dayAnchor(DateTime dt) =>
      dt.hour < 4 ? dt.subtract(const Duration(days: 1)) : dt;

  String _todayKey() {
    final d = _dayAnchor(DateTime.now());
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  int getDailyMs(String packageName, {String? date}) =>
      _prefs.getInt('daily_ms_${packageName}_${date ?? _todayKey()}') ?? 0;

  int getOpenCount(String packageName, {String? date}) =>
      _prefs.getInt('open_count_${packageName}_${date ?? _todayKey()}') ?? 0;

  int getUnlockCount({String? date}) =>
      _prefs.getInt('unlock_count_${date ?? _todayKey()}') ?? 0;

  int getDeviceDailyMs({String? date}) =>
      _prefs.getInt('device_daily_ms_${date ?? _todayKey()}') ?? 0;

  // ── Hourly breakdown ──

  int getDeviceHourlyMs({required String date, required int hour}) =>
      _prefs.getInt('device_hourly_ms_${date}_$hour') ?? 0;

  int getHourlyUnlocks({required String date, required int hour}) =>
      _prefs.getInt('hourly_unlocks_${date}_$hour') ?? 0;

  int getHourlyOpens(String packageName, {required String date, required int hour}) =>
      _prefs.getInt('hourly_opens_${packageName}_${date}_$hour') ?? 0;

  int getHourlyMs(String packageName, {required String date, required int hour}) =>
      _prefs.getInt('hourly_ms_${packageName}_${date}_$hour') ?? 0;

  /// 24-element list — index = hour of day (0–23), value = device ms in that hour.
  List<int> getDeviceHourlyBreakdown(String date) =>
      List.generate(24, (h) => getDeviceHourlyMs(date: date, hour: h));

  /// 24-element list — index = hour of day (0–23), value = unlock count.
  List<int> getHourlyUnlockBreakdown(String date) =>
      List.generate(24, (h) => getHourlyUnlocks(date: date, hour: h));

  /// pkg → 24-element list of hourly ms for the given date.
  /// Only packages that have any non-zero hourly data are included.
  Map<String, List<int>> getAppHourlyBreakdown(String date) {
    final result = <String, List<int>>{};
    for (final pkg in packagesDailyMs(date)) {
      final hourly = List.generate(24, (h) => getHourlyMs(pkg, date: date, hour: h));
      if (hourly.any((v) => v > 0)) result[pkg] = hourly;
    }
    return result;
  }

  // ── Session duration buckets ──
  // Bucket 0: < 1 min · 1: 1–5 min · 2: 5–15 min · 3: > 15 min

  /// Returns [bucket0, bucket1, bucket2, bucket3] counts for the given date.
  List<int> getSessionBuckets({String? date}) =>
      List.generate(4, (i) =>
          _prefs.getInt('session_bucket_${i}_${date ?? _todayKey()}') ?? 0);

  // ── Rolling 24h helpers ──
  // Since data is stored per calendar day we approximate the rolling 24h window
  // as: yesterday's total * fraction still within the window + all of today's total.
  // Assumption: usage is roughly uniform throughout the day (best we can do with
  // daily-granularity storage without a full schema change).

  String _yesterdayKey() {
    final d = _dayAnchor(DateTime.now()).subtract(const Duration(days: 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Today's usage ms for a package (since 04:00 of the current day).
  int getTodayMs(String packageName) => getDailyMs(packageName);

  /// Yesterday's usage ms for a package (full 04:00–04:00 window).
  int getYesterdayMs(String packageName) =>
      getDailyMs(packageName, date: _yesterdayKey());

  /// Device-level today/yesterday helpers.
  int getDeviceTodayMs() => getDeviceDailyMs();
  int getDeviceYesterdayMs() => getDeviceDailyMs(date: _yesterdayKey());

  int getUnlockToday() => getUnlockCount();
  int getUnlockYesterday() => getUnlockCount(date: _yesterdayKey());

  // Legacy rolling-24h helpers kept for compatibility with AnalyticsService.
  // They now simply return today's totals (since the day starts at 4am, this
  // is a cleaner window than the old fractional approximation).
  int getLast24hMs(String packageName) => getTodayMs(packageName);
  int getDeviceLast24hMs() => getDeviceTodayMs();
  int getUnlockLast24h() => getUnlockToday();

  /// Packages that have any usage data today (since 04:00) or yesterday.
  List<String> packagesLast24h() {
    final today = _todayKey();
    final yesterday = _yesterdayKey();
    // Flutter's getKeys() strips the 'flutter.' storage prefix — match without it.
    const prefix = 'daily_ms_';
    final packages = <String>{};
    for (final k in _prefs.getKeys()) {
      if (k.startsWith(prefix)) {
        if (k.endsWith('_$today') || k.endsWith('_$yesterday')) {
          packages.add(k.substring(prefix.length, k.lastIndexOf('_')));
        }
      }
    }
    return packages.toList();
  }

  // ── Per-app control ──

  /// Whether the overlay should be shown while on the launcher / home screen.
  bool get monitorLauncher => _prefs.getBool('monitor_launcher') ?? true;
  set monitorLauncher(bool v) => _prefs.setBool('monitor_launcher', v);

  Set<String> get disabledApps {
    final raw = _prefs.get('disabled_apps');
    if (raw == null) return {};
    // Legacy format: setStringList stored a List<String> directly.
    if (raw is List) return raw.cast<String>().toSet();
    // New format: setString stores a JSON-encoded string readable by Kotlin.
    if (raw is String) {
      try { return (jsonDecode(raw) as List).cast<String>().toSet(); }
      catch (_) { return {}; }
    }
    return {};
  }

  set disabledApps(Set<String> apps) =>
      _prefs.setString('disabled_apps', jsonEncode(apps.toList()));

  void toggleApp(String packageName) {
    final apps = disabledApps;
    if (apps.contains(packageName)) {
      apps.remove(packageName);
    } else {
      apps.add(packageName);
    }
    disabledApps = apps;
  }

  // ── Onboarding / first-run ──

  bool get onboardingDone => _prefs.getBool('onboarding_done') ?? false;
  set onboardingDone(bool v) => _prefs.setBool('onboarding_done', v);

  /// True once we have auto-started monitoring for the first time.
  /// Prevents repeated auto-start if the user manually stops monitoring.
  bool get monitoringEverStarted => _prefs.getBool('monitoring_ever_started') ?? false;
  set monitoringEverStarted(bool v) => _prefs.setBool('monitoring_ever_started', v);

  // ── Daily goal ──

  int get dailyGoalMinutes => _prefs.getInt('daily_goal_minutes') ?? 0;
  set dailyGoalMinutes(int v) => _prefs.setInt('daily_goal_minutes', v);

  // ── Language ──
  // null = follow system locale; 'pt' or 'en' = explicit override.

  String? get languageCode => _prefs.getString('language_code');
  set languageCode(String? v) {
    if (v == null) {
      _prefs.remove('language_code');
    } else {
      _prefs.setString('language_code', v);
    }
  }

  // ── Goal level ──
  // 0 = none, 1 = minimal, 2 = normal, 3 = extensive.
  // Mirrors GoalLevel enum index.

  int get goalLevel => _prefs.getInt('goal_level') ?? 0;
  set goalLevel(int v) => _prefs.setInt('goal_level', v);

  /// Per-app goal override. 0 = inherit global.
  int getAppGoalLevel(String packageName) =>
      _prefs.getInt('app_goal_$packageName') ?? 0;

  void setAppGoalLevel(String packageName, int level) =>
      _prefs.setInt('app_goal_$packageName', level);

  // ── Weekday-pattern helpers ───────────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns the last [n] dates (YYYY-MM-DD) that fall on [weekday] (1=Mon … 7=Sun).
  /// Uses the 4am day anchor so dates match the keys stored by MonitoringService.
  List<String> lastNDatesForWeekday(int weekday, int n) {
    final result = <String>[];
    var d = _dayAnchor(DateTime.now()).subtract(const Duration(days: 1));
    final cutoff = _dayAnchor(DateTime.now()).subtract(const Duration(days: 90));
    while (result.length < n) {
      if (d.weekday == weekday) result.add(_fmt(d));
      d = d.subtract(const Duration(days: 1));
      if (d.isBefore(cutoff)) break;
    }
    return result;
  }

  /// Average device hourly ms (24 values) across [dates].
  List<int> avgDeviceHourlyMs(List<String> dates) => List.generate(24, (h) {
        if (dates.isEmpty) return 0;
        final total =
            dates.fold<int>(0, (s, d) => s + getDeviceHourlyMs(date: d, hour: h));
        return total ~/ dates.length;
      });

  /// For [dates], returns pkg → 24-element list of average hourly ms.
  /// Only packages that have any non-zero data in those dates are included.
  Map<String, List<int>> avgAppHourlyMs(List<String> dates) {
    final result = <String, List<int>>{};
    if (dates.isEmpty) return result;
    // Collect all packages that have data on these dates
    final packages = <String>{};
    for (final d in dates) {
      packages.addAll(packagesDailyMs(d));
    }
    for (final pkg in packages) {
      final hourly = List.generate(24, (h) {
        final total =
            dates.fold<int>(0, (s, d) => s + getHourlyMs(pkg, date: d, hour: h));
        return total ~/ dates.length;
      });
      if (hourly.any((v) => v > 0)) result[pkg] = hourly;
    }
    return result;
  }

  // ── Query helpers ──

  /// Erases all usage history keys (daily_ms_, device_daily_ms_, open_count_,
  /// unlock_count_, device_hourly_ms_, hourly_*, session_bucket_).
  /// Settings (overlay, goals, language, etc.) are preserved.
  Future<void> deleteAllData() async {
    const historyPrefixes = [
      'daily_ms_', 'device_daily_ms_', 'open_count_', 'unlock_count_',
      'device_hourly_ms_', 'hourly_ms_', 'hourly_opens_', 'hourly_unlocks_',
      'session_bucket_',
    ];
    for (final k in List.of(_prefs.getKeys())) {
      if (historyPrefixes.any((p) => k.startsWith(p))) await _prefs.remove(k);
    }
  }

  /// Removes all per-day and per-hour keys older than [keepDays] days.
  /// Call once on app start to prevent unbounded data accumulation.
  Future<void> pruneOldData({int keepDays = 90}) async {
    final cutoff = _dayAnchor(DateTime.now()).subtract(Duration(days: keepDays));
    final datePrefixes = <String, bool>{};
    // Build a set of date strings that are within the retention window.
    for (final k in _prefs.getKeys()) {
      // Keys with date suffixes look like: daily_ms_com.pkg_2024-01-15
      // or device_hourly_ms_2024-01-15_3
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').allMatches(k).lastOrNull;
      if (dateMatch == null) continue;
      final dateStr = dateMatch.group(0)!;
      if (datePrefixes.containsKey(dateStr)) continue;
      final parts = dateStr.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      datePrefixes[dateStr] = dt.isAfter(cutoff);
    }
    for (final k in List.of(_prefs.getKeys())) {
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').allMatches(k).lastOrNull;
      if (dateMatch == null) continue;
      final dateStr = dateMatch.group(0)!;
      if (datePrefixes[dateStr] == false) await _prefs.remove(k);
    }
  }

  /// Retorna packages que têm dados de uso para a data dada (formato YYYY-MM-DD).
  List<String> packagesDailyMs(String date) {
    // Flutter's getKeys() strips the 'flutter.' storage prefix — match without it.
    const prefix = 'daily_ms_';
    final suffix = '_$date';
    return _prefs
        .getKeys()
        .where((k) => k.startsWith(prefix) && k.endsWith(suffix))
        .map((k) => k.substring(prefix.length, k.length - suffix.length))
        .toList();
  }
}
