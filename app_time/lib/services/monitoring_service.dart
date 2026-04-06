import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../config/overlay_config.dart';
import 'storage_service.dart';

class AppTracker {
  static String lastApp = "";
  static bool _lastAppWasLauncher = false;
  static int sessionSeconds = 0;
  static int launcherSeconds = 0;
  static String lastDailyStats = "0 min";
  static int lastDailyMs = 0; // cached raw ms for overlay rotation
  static String lastDeviceUsage24h = "0 min";
  static double lastGoalPct = 0.0;
  static Timer? _pollTimer;
  static Timer? _healthTimer;

  static void stopPolling() {
    _pollTimer?.cancel();
    _healthTimer?.cancel();
    _pollTimer = null;
    _healthTimer = null;
  }

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
          if (StorageService.showOnLauncher) {
            await _ensureOverlayVisible();
            final unlockCount = await getUnlockCount24h();
            lastDeviceUsage24h = await getDeviceUsage24h();

            // LAUNCHER_WAKE quando acabou de desbloquear (contexto de uso real)
            // LAUNCHER_HOME quando veio de um app (pressionou home) — mesmos dados
            final eventType = unlockedNow ? "LAUNCHER_WAKE" : "LAUNCHER_HOME";
            await _shareDataSafely({
              "type": eventType,
              "unlock_count": unlockCount,
              "device_usage_24h": lastDeviceUsage24h,
            });
          }
        } else if (!StorageService.showOnAppOpen || !StorageService.isAppEnabled(currentApp)) {
          // Overlay desativado globalmente ou para este app específico
        } else {
          await _ensureOverlayVisible();

          int openCount = await getOpenCount24h(currentApp);
          lastDailyMs = await _getAppUsageMs24h(currentApp);
          lastDailyStats = _formatMs(lastDailyMs);
          await _updateGoalPct();

          final payload = <String, dynamic>{
            "type": "APP_OPEN",
            "count": openCount,
            "daily_ms": lastDailyMs,
          };
          if (lastGoalPct > 0) payload['goal_pct'] = lastGoalPct;
          await _shareDataSafely(payload);
        }
      } else if (!isLauncher) {
        sessionSeconds++;

        if (sessionSeconds == 60 || sessionSeconds % 30 == 0) {
          lastDailyMs = await _getAppUsageMs24h(currentApp);
          lastDailyStats = _formatMs(lastDailyMs);
          await _updateGoalPct();
        }

        if (StorageService.showOnAppOpen && StorageService.isAppEnabled(currentApp)) {
          final payload = <String, dynamic>{
            "type": "APP_TICK",
            "seconds": sessionSeconds,
            "daily_ms": lastDailyMs,
          };
          if (lastGoalPct > 0) payload['goal_pct'] = lastGoalPct;
          await _shareDataSafely(payload);
        }
      } else {
        launcherSeconds++;

        if (_lastAppWasLauncher && launcherSeconds % 10 == 0) {
          lastDeviceUsage24h = await getDeviceUsage24h();
          await _updateGoalPct();
          final payload = <String, dynamic>{
            "type": "LAUNCHER_TICK",
            "device_usage_24h": lastDeviceUsage24h,
          };
          if (lastGoalPct > 0) payload['goal_pct'] = lastGoalPct;
          await _shareDataSafely(payload);
        }
      }

      _lastAppWasLauncher = isLauncher;
    });

    // Health check: reativa o overlay a cada 60s se o serviço estiver rodando
    // mas o overlay tiver morrido (ex: baixa memória, reinício do sistema)
    _healthTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (lastApp.isEmpty) return;
      final isActive = await FlutterOverlayWindow.isActive();
      if (!isActive && !launchers.contains(lastApp)) {
        await _ensureOverlayVisible();
      }
    });
  }

  static Future<int> _getAppUsageMs24h(String packageName) async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(hours: 24));
    try {
      final stats = await UsageStats.queryUsageStats(start, end);
      final info = stats.firstWhere((s) => s.packageName == packageName,
          orElse: () => UsageInfo());
      return int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static String _formatMs(int ms) {
    final minutes = ms / 60000;
    if (minutes < 60) return "${minutes.round()} min";
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    return m > 0 ? "${h}h ${m}min" : "${h}h";
  }

  static Future<void> _updateGoalPct() async {
    final goal = StorageService.dailyGoalMinutes;
    if (goal <= 0) {
      lastGoalPct = 0.0;
      return;
    }
    final usedMinutes = await _getDeviceUsageMinutes24h();
    lastGoalPct = usedMinutes / goal;
  }

  static Future<double> _getDeviceUsageMinutes24h() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(hours: 24));
    try {
      final stats = await UsageStats.queryUsageStats(start, end);
      int totalMs = 0;
      for (final item in stats) {
        if (item.totalTimeInForeground == null || item.packageName == null) continue;
        if (launchers.contains(item.packageName!)) continue;
        totalMs += int.tryParse(item.totalTimeInForeground!) ?? 0;
      }
      return totalMs / 60000;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _ensureOverlayVisible() async {
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) return;

    await FlutterOverlayWindow.showOverlay(
      alignment: OverlayConfig.alignment,
      height: OverlayConfig.height,
      width: OverlayConfig.width,
      enableDrag: false,
      flag: OverlayFlag.clickThrough,
      startPosition: const OverlayPosition(0, 0),
      overlayTitle: "Contador ativo",
      overlayContent: "AppTime está monitorando em segundo plano",
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
    return "${(minutes / 60).toStringAsFixed(1)}h";
  }
}
