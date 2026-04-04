import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/background_service.dart';
import '../theme/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  bool isOverlayGranted = false;
  bool isUsageStatsGranted = false;
  bool isBatteryOptIgnored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final overlay = await FlutterOverlayWindow.isPermissionGranted();
      final usage = await UsageStats.checkUsagePermission() ?? false;
      bool battery = false;
      try {
        battery = await Permission.ignoreBatteryOptimizations.isGranted;
      } catch (_) {}

      if (mounted) {
        setState(() {
          isOverlayGranted = overlay;
          isUsageStatsGranted = usage;
          isBatteryOptIgnored = battery;
        });
      }
    } catch (e) {
      debugPrint("Erro em _checkPermissions: $e");
    }
  }

  Future<void> _startMonitoring() async {
    if (!isOverlayGranted || !isUsageStatsGranted) return;
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      await initializeBackgroundService();

      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Monitoramento ativo!")),
        );
      }
    } catch (e) {
      debugPrint("Erro crítico ao iniciar serviço: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao iniciar: $e")),
        );
      }
    }
  }

  Future<void> _requestOverlay() async {
    await _showDialog(
      title: "Janela flutuante",
      body: "Na próxima tela, encontre o AppTime na lista e ative a permissão.",
      onConfirm: () async {
        await Permission.systemAlertWindow.request();
        _checkPermissions();
      },
    );
  }

  Future<void> _requestUsage() async {
    await _showDialog(
      title: "Acesso ao uso",
      body: "Toque em AppTime na lista e permita o acesso às estatísticas de uso.",
      onConfirm: () async {
        await UsageStats.grantUsagePermission();
        _checkPermissions();
      },
    );
  }

  Future<void> _requestBattery() async {
    await _showDialog(
      title: "Funcionamento em segundo plano",
      body: "Permita que o AppTime ignore a otimização de bateria para continuar funcionando.",
      onConfirm: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await Permission.ignoreBatteryOptimizations.request();
        } catch (_) {
          messenger.showSnackBar(
            const SnackBar(content: Text("Configure manualmente nas configurações de bateria.")),
          );
        }
        _checkPermissions();
      },
    );
  }

  Future<void> _showDialog({
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text("Entendi"),
          ),
        ],
      ),
    );
  }

  bool get _allGranted => isOverlayGranted && isUsageStatsGranted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("AppTime")),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        children: [
          Text(
            "Permissões necessárias",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            "Conceda as permissões abaixo para o AppTime funcionar corretamente.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingLG),

          _PermissionTile(
            title: "Janela flutuante",
            subtitle: "Exibir o overlay sobre outros apps",
            granted: isOverlayGranted,
            onTap: _requestOverlay,
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _PermissionTile(
            title: "Estatísticas de uso",
            subtitle: "Detectar qual app está em uso",
            granted: isUsageStatsGranted,
            onTap: _requestUsage,
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _PermissionTile(
            title: "Segundo plano",
            subtitle: "Manter o monitoramento sem interrupções",
            granted: isBatteryOptIgnored,
            onTap: _requestBattery,
            required: false,
          ),

          const SizedBox(height: AppTheme.spacingXL),

          FilledButton(
            onPressed: _allGranted ? _startMonitoring : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: const Text(
              "Iniciar monitoramento",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: !granted && required
            ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline)
            : null,
      ),
    );
  }
}
