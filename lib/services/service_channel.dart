import 'package:flutter/services.dart';

/// Bridge para o MethodChannel Kotlin — OverlayService e MonitoringService.
class ServiceChannel {
  static const _channel = MethodChannel('apptime/service');

  static Future<void> startMonitoring() => _channel.invokeMethod('startMonitoring');
  static Future<void> stopMonitoring() => _channel.invokeMethod('stopMonitoring');
  static Future<bool> isRunning() async =>
      await _channel.invokeMethod<bool>('isRunning') ?? false;

  static Future<void> requestOverlayPermission() =>
      _channel.invokeMethod('requestOverlayPermission');
  static Future<bool> hasOverlayPermission() async =>
      await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;

  static Future<void> requestUsagePermission() =>
      _channel.invokeMethod('requestUsagePermission');
  static Future<bool> hasUsagePermission() async =>
      await _channel.invokeMethod<bool>('hasUsagePermission') ?? false;

  /// Returns a map of packageName → display label for all app-drawer-visible apps.
  static Future<Map<String, String>> getInstalledAppLabels() async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>('getInstalledApps');
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  /// Returns package names of all apps registered as home-screen launchers.
  static Future<Set<String>> getLaunchers() async {
    final raw = await _channel.invokeMethod<List<Object?>>('getLaunchers');
    if (raw == null) return {};
    return raw.map((e) => e.toString()).toSet();
  }
}
