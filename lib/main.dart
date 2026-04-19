import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'services/service_channel.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();

  // Determine locale: saved preference → auto-detect from system → default pt.
  Locale initialLocale;
  final savedCode = storage.languageCode;
  if (savedCode != null) {
    initialLocale = Locale(savedCode);
  } else {
    final systemLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    initialLocale = systemLang == 'en' ? const Locale('en') : const Locale('pt');
    storage.languageCode = initialLocale.languageCode;
  }

  // Fire-and-forget: prune data older than 90 days in the background.
  storage.pruneOldData();

  final results = await Future.wait([
    ServiceChannel.hasOverlayPermission(),
    ServiceChannel.hasUsagePermission(),
  ]);
  final allGranted = results[0] && results[1];

  // Auto-start monitoring on first use once permissions are granted.
  if (allGranted && !storage.monitoringEverStarted) {
    await ServiceChannel.startMonitoring();
    storage.monitoringEverStarted = true;
  }

  runApp(AppTimeApp(
    storage: storage,
    skipOnboarding: allGranted,
    initialLocale: initialLocale,
  ));
}

class AppTimeApp extends StatefulWidget {
  const AppTimeApp({
    super.key,
    required this.storage,
    required this.skipOnboarding,
    required this.initialLocale,
  });

  final StorageService storage;
  final bool skipOnboarding;
  final Locale initialLocale;

  @override
  State<AppTimeApp> createState() => _AppTimeAppState();
}

class _AppTimeAppState extends State<AppTimeApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  /// Called by SettingsScreen. [languageCode] null = revert to system locale.
  void _setLocale(String? languageCode) {
    final next = languageCode != null ? Locale(languageCode) : const Locale('pt');
    widget.storage.languageCode = languageCode;
    setState(() => _locale = next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppTime',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget.skipOnboarding
          ? MainScreen(storage: widget.storage, onLocaleChange: _setLocale)
          : OnboardingScreen(
              storage: widget.storage, onLocaleChange: _setLocale),
      debugShowCheckedModeBanner: false,
    );
  }
}
