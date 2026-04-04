import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'overlay/app_time_overlay.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const AppTimeApp());
}

class AppTimeApp extends StatelessWidget {
  const AppTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AppTime',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
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
