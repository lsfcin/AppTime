import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'screens/analytics_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.storage,
    required this.onLocaleChange,
  });

  final StorageService storage;
  final void Function(String?) onLocaleChange;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      SettingsScreen(
        storage: widget.storage,
        onLocaleChange: widget.onLocaleChange,
      ),
      MonitoringScreen(storage: widget.storage),
      AnalyticsScreen(storage: widget.storage),
      InsightsScreen(storage: widget.storage),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_heart_outlined),
            selectedIcon: const Icon(Icons.monitor_heart),
            label: l10n.navMonitoring,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navAnalysis,
          ),
          NavigationDestination(
            icon: const Icon(Icons.lightbulb_outlined),
            selectedIcon: const Icon(Icons.lightbulb),
            label: l10n.navInsights,
          ),
        ],
      ),
    );
  }
}
