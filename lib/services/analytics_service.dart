import '../services/storage_service.dart';

class AppUsage {
  const AppUsage({
    required this.packageName,
    required this.dailyMs,
    required this.openCount,
  });

  final String packageName;
  final int dailyMs; // ms acumulados no dia
  final int openCount;
}

class DaySummary {
  const DaySummary({
    required this.date,
    required this.totalMs,
    required this.unlockCount,
    required this.apps,
  });

  final String date; // YYYY-MM-DD
  final int totalMs;
  final int unlockCount;
  final List<AppUsage> apps;

  List<AppUsage> get topApps {
    final sorted = [...apps]..sort((a, b) => b.dailyMs.compareTo(a.dailyMs));
    return sorted.take(5).toList();
  }
}

class AnalyticsService {
  const AnalyticsService(this._storage);

  final StorageService _storage;

  /// Retorna sumário para os últimos [days] dias (1, 7 ou 30).
  /// i=0 → today (since 04:00). i>0 → previous 4am-bounded days.
  List<DaySummary> getSummaries(int days) {
    // 4am day boundary — mirrors MonitoringService.kt
    final today = _anchor(DateTime.now());
    final summaries = <DaySummary>[];

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = _fmt(date);
      final packages = i == 0
          ? _storage.packagesLast24h()      // uses _todayKey() which is already anchored
          : _storage.packagesDailyMs(dateStr);
      final disabled = _storage.disabledApps;
      final apps = packages
          .where((pkg) => !disabled.contains(pkg))
          .map((pkg) {
        return AppUsage(
          packageName: pkg,
          dailyMs: i == 0
              ? _storage.getLast24hMs(pkg)
              : _storage.getDailyMs(pkg, date: dateStr),
          openCount: i == 0
              ? _storage.getOpenCount(pkg)
              : _storage.getOpenCount(pkg, date: dateStr),
        );
      }).toList();
      summaries.add(DaySummary(
        date: i == 0 ? 'today' : dateStr,
        totalMs: i == 0
            ? _storage.getDeviceLast24hMs()
            : _storage.getDeviceDailyMs(date: dateStr),
        unlockCount: i == 0
            ? _storage.getUnlockLast24h()
            : _storage.getUnlockCount(date: dateStr),
        apps: apps,
      ));
    }

    return summaries;
  }

  /// 4am day anchor — hours 00–03 belong to the previous calendar day.
  static DateTime _anchor(DateTime dt) =>
      dt.hour < 4 ? dt.subtract(const Duration(days: 1)) : dt;

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
