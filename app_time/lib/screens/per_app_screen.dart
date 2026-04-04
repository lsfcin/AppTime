import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class PerAppScreen extends StatefulWidget {
  const PerAppScreen({super.key});

  @override
  State<PerAppScreen> createState() => _PerAppScreenState();
}

class _PerAppScreenState extends State<PerAppScreen> {
  List<_AppEntry> _apps = [];
  bool _loading = true;

  static const List<String> _launchers = [
    "com.google.android.apps.nexuslauncher",
    "com.sec.android.app.launcher",
    "com.miui.home",
    "com.android.launcher",
    "com.android.launcher3",
  ];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 7));
      final stats = await UsageStats.queryUsageStats(start, end);

      final disabled = StorageService.disabledApps;

      final entries = stats
          .where((s) =>
              s.packageName != null &&
              s.totalTimeInForeground != null &&
              !_launchers.contains(s.packageName) &&
              (int.tryParse(s.totalTimeInForeground!) ?? 0) > 0)
          .map((s) => _AppEntry(
                packageName: s.packageName!,
                minutesUsed: (int.tryParse(s.totalTimeInForeground!) ?? 0) / 60000,
                enabled: !disabled.contains(s.packageName!),
              ))
          .toList()
        ..sort((a, b) => b.minutesUsed.compareTo(a.minutesUsed));

      if (mounted) {
        setState(() {
          _apps = entries;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(int index, bool value) {
    final pkg = _apps[index].packageName;
    StorageService.setAppEnabled(pkg, value);
    setState(() => _apps[index] = _apps[index].copyWith(enabled: value));
  }

  void _enableAll() {
    for (int i = 0; i < _apps.length; i++) {
      StorageService.setAppEnabled(_apps[i].packageName, true);
    }
    setState(() {
      _apps = _apps.map((e) => e.copyWith(enabled: true)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Por aplicativo"),
        actions: [
          if (!_loading && _apps.any((a) => !a.enabled))
            TextButton(
              onPressed: _enableAll,
              child: const Text("Ativar todos"),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    child: Text(
                      "Nenhum app detectado ainda.\nUse o celular normalmente e volte aqui.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingMD, AppTheme.spacingMD, AppTheme.spacingMD, 0),
                      child: Text(
                        "Desative o overlay para apps onde ele atrapalha. "
                        "Baseado nos últimos 7 dias.",
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD, vertical: AppTheme.spacingSM),
                        itemCount: _apps.length,
                        separatorBuilder: (context, idx) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final app = _apps[i];
                          return SwitchListTile(
                            title: Text(
                              _prettifyPackageName(app.packageName),
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              '${app.packageName}\n${_formatUsage(app.minutesUsed)} nos últimos 7 dias',
                              style: theme.textTheme.bodySmall,
                            ),
                            isThreeLine: true,
                            value: app.enabled,
                            onChanged: (v) => _toggle(i, v),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSM, vertical: 2),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  static String _prettifyPackageName(String pkg) {
    const noise = {
      'com', 'org', 'net', 'io', 'co', 'android', 'app', 'apps',
      'google', 'phone', 'mobile', 'inc',
    };
    final parts = pkg.split('.');
    final meaningful = parts.where((p) => !noise.contains(p.toLowerCase()) && p.length > 2);
    final best = meaningful.isNotEmpty ? meaningful.last : parts.last;
    return best[0].toUpperCase() + best.substring(1);
  }

  static String _formatUsage(double minutes) {
    if (minutes < 60) return '${minutes.round()} min';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }
}

class _AppEntry {
  final String packageName;
  final double minutesUsed;
  final bool enabled;

  const _AppEntry({
    required this.packageName,
    required this.minutesUsed,
    required this.enabled,
  });

  _AppEntry copyWith({bool? enabled}) => _AppEntry(
        packageName: packageName,
        minutesUsed: minutesUsed,
        enabled: enabled ?? this.enabled,
      );
}
