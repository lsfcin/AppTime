import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'monitoring_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  AppTracker.startSmartPolling();
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (ServiceInstance service) => false,
    ),
  );
}
