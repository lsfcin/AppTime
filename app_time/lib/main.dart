import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'overlay/app_time_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SetupScreen(),
  ));
}

// OBRIGATÓRIO: O motor nativo procura essa função globalmente aqui no main
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AppTimeOverlay(),
  ));
}