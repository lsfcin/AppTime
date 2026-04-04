import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/background_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isOverlayGranted = false;
  bool isUsageStatsGranted = false;
  bool isBatteryOptIgnored = false;
  bool isMonitoringActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final overlay = await FlutterOverlayWindow.isPermissionGranted();
      final usage = await UsageStats.checkUsagePermission() ?? false;
      bool battery = false;
      try {
        battery = await Permission.ignoreBatteryOptimizations.isGranted;
      } catch (_) {}
      final monitoring = await FlutterBackgroundService().isRunning();

      if (mounted) {
        setState(() {
          isOverlayGranted = overlay;
          isUsageStatsGranted = usage;
          isBatteryOptIgnored = battery;
          isMonitoringActive = monitoring;
        });
      }
    } catch (e) {
      debugPrint("Erro em _refresh: $e");
    }
  }

  Future<void> _toggleMonitoring() async {
    if (!isOverlayGranted || !isUsageStatsGranted) return;

    if (isMonitoringActive) {
      FlutterBackgroundService().invoke("stopService");
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      await initializeBackgroundService();
      await FlutterBackgroundService().startService();
    }
    await _refresh();
  }

  Future<void> _requestPermission(Future<void> Function() action) async {
    await action();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allGranted = isOverlayGranted && isUsageStatsGranted;

    return Scaffold(
      appBar: AppBar(title: const Text("AppTime")),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isMonitoringActive ? AppTheme.success : theme.colorScheme.outline)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMonitoringActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: isMonitoringActive ? AppTheme.success : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMonitoringActive ? "Monitoramento ativo" : "Monitoramento inativo",
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          isMonitoringActive
                              ? "O overlay está funcionando em segundo plano"
                              : "Inicie o monitoramento para ver o overlay",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingLG),
          Text("Permissões", style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSM),

          _PermissionTile(
            title: "Janela flutuante",
            subtitle: "Exibir o overlay sobre outros apps",
            granted: isOverlayGranted,
            onTap: () => _requestPermission(() async {
              await Permission.systemAlertWindow.request();
            }),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _PermissionTile(
            title: "Estatísticas de uso",
            subtitle: "Detectar qual app está em uso",
            granted: isUsageStatsGranted,
            onTap: () => _requestPermission(() async {
              await UsageStats.grantUsagePermission();
            }),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _PermissionTile(
            title: "Segundo plano",
            subtitle: "Manter o monitoramento sem interrupções",
            granted: isBatteryOptIgnored,
            required: false,
            onTap: () => _requestPermission(() async {
              await Permission.ignoreBatteryOptimizations.request();
            }),
          ),

          const SizedBox(height: AppTheme.spacingXL),

          FilledButton(
            onPressed: allGranted ? _toggleMonitoring : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: isMonitoringActive ? AppTheme.error : AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: Text(
              isMonitoringActive ? "Pausar monitoramento" : "Iniciar monitoramento",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;
  final bool required;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: granted ? null : onTap,
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            key: ValueKey(granted),
            color: granted ? AppTheme.success : theme.colorScheme.outline,
            size: 28,
          ),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
        trailing: !granted && required
            ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline)
            : null,
      ),
    );
  }
}
