import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../config/overlay_config.dart';

class AppTracker {
  static String lastApp = "";
  static bool _lastAppWasLauncher = false;
  static int sessionSeconds = 0;
  static int launcherSeconds = 0;
  static String lastDailyStats = "0 min";
  static String lastDeviceUsage24h = "0 min";
  static Timer? _pollTimer;
  static final List<String> launchers = [
    "com.google.android.apps.nexuslauncher",
    "com.sec.android.app.launcher",
    "com.miui.home",
    "com.android.launcher",
    "com.android.launcher3",
  ];

  static bool get isPolling => _pollTimer?.isActive ?? false;

  static void startSmartPolling() {
    if (isPolling) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      String currentApp;

      try {
        List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
          DateTime.now().subtract(const Duration(minutes: 1)),
          DateTime.now(),
        );

        if (usageStats.isEmpty) return;

        usageStats = usageStats
            .where((item) => item.packageName != null && item.lastTimeUsed != null)
            .toList();

        if (usageStats.isEmpty) return;

        usageStats.sort((a, b) => b.lastTimeUsed!.compareTo(a.lastTimeUsed!));
        currentApp = usageStats.first.packageName!;
      } catch (e) {
        return;
      }

      final isLauncher = launchers.contains(currentApp);

      if (currentApp != lastApp) {
        final unlockedNow = await _wasUnlockedRecently();

        lastApp = currentApp;
        sessionSeconds = 0;
        launcherSeconds = 0;

        if (isLauncher) {
          await _ensureOverlayVisible();

          if (unlockedNow) {
            final unlockCount = await getUnlockCount24h();
            lastDeviceUsage24h = await getDeviceUsage24h();

            await _shareDataSafely({
              "type": "LAUNCHER_WAKE",
              "unlock_count": unlockCount,
              "device_usage_24h": lastDeviceUsage24h,
            });
          } else {
            await FlutterOverlayWindow.closeOverlay();
          }
        } else {
          await _ensureOverlayVisible();

          int openCount = await getOpenCount24h(currentApp);
          lastDailyStats = await getAppUsage24h(currentApp);

          await _shareDataSafely({"type": "APP_OPEN", "count": openCount});
        }
      } else if (!isLauncher) {
        sessionSeconds++;

        if (sessionSeconds == 60 || sessionSeconds % 30 == 0) {
          lastDailyStats = await getAppUsage24h(currentApp);
        }

        await _shareDataSafely({
          "type": "APP_TICK",
          "seconds": sessionSeconds,
          "daily_stats": lastDailyStats,
        });
      } else {
        launcherSeconds++;

        if (_lastAppWasLauncher && launcherSeconds % 20 == 0) {
          lastDeviceUsage24h = await getDeviceUsage24h();
          await _shareDataSafely({
            "type": "LAUNCHER_TICK",
            "device_usage_24h": lastDeviceUsage24h,
          });
        }
      }

      _lastAppWasLauncher = isLauncher;
    });
  }

  static Future<void> _ensureOverlayVisible() async {
    await FlutterOverlayWindow.showOverlay(
      alignment: OverlayConfig.alignment,
      height: OverlayConfig.height,
      width: OverlayConfig.width,
      enableDrag: false,
      flag: OverlayFlag.clickThrough, 
    );
  }

  static Future<void> _shareDataSafely(Map<String, dynamic> payload) async {
    await FlutterOverlayWindow.shareData(payload);
    Timer(const Duration(milliseconds: 280), () {
      FlutterOverlayWindow.shareData(payload);
    });
  }

  static Future<bool> _wasUnlockedRecently() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(seconds: 25));
    try {
      final events = await UsageStats.queryEvents(start, end);
      return events.any((event) => event.eventType == "18");
    } catch (_) {
      return false;
    }
  }

  static Future<int> getOpenCount24h(String packageName) async {
    DateTime end = DateTime.now();
    DateTime start = end.subtract(const Duration(hours: 24));
    List<EventUsageInfo> events = await UsageStats.queryEvents(start, end);
    return events.where((e) => e.packageName == packageName && e.eventType == "1").length;
  }

  static Future<int> getUnlockCount24h() async {
    DateTime end = DateTime.now();
    DateTime start = end.subtract(const Duration(hours: 24));
    try {
      List<EventUsageInfo> events = await UsageStats.queryEvents(start, end);
      final unlockEvents = events.where((e) => e.eventType == "18").length;
      if (unlockEvents > 0) return unlockEvents;
      return events.where((e) => launchers.contains(e.packageName) && e.eventType == "1").length;
    } catch (_) {
      return 0;
    }
  }

  static Future<String> getAppUsage24h(String packageName) async {
    DateTime end = DateTime.now();
    DateTime start = end.subtract(const Duration(hours: 24));
    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(start, end);
    try {
      UsageInfo stats = usageStats.firstWhere((info) => info.packageName == packageName);
      int totalMs = int.parse(stats.totalTimeInForeground!);
      double minutes = totalMs / 1000 / 60;
      return _format24hUsage(minutes);
    } catch (e) {
      return "0 min";
    }
  }

  static Future<String> getDeviceUsage24h() async {
    DateTime end = DateTime.now();
    DateTime start = end.subtract(const Duration(hours: 24));
    try {
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(start, end);
      int totalMs = 0;
      for (final item in usageStats) {
        if (item.totalTimeInForeground == null || item.packageName == null) continue;
        if (launchers.contains(item.packageName!)) continue;
        totalMs += int.tryParse(item.totalTimeInForeground!) ?? 0;
      }
      final totalMinutes = totalMs / 1000 / 60;
      return _format24hUsage(totalMinutes);
    } catch (_) {
      return "0 min";
    }
  }

  static String _format24hUsage(double minutes) {
    if (minutes < 60) return "${minutes.round()} min";
    return "${(minutes / 60).toStringAsFixed(1)} hrs";
  }
}