import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'overlay_main.dart';
import 'logic_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SetupScreen(),
  ));
}

// PONTO DE ENTRADA DO OVERLAY (Obrigatório)
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AppTimeOverlay(),
  ));
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  bool _monitoringStarted = false;
  bool isOverlayGranted = false;
  bool isUsageStatsGranted = false;

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
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  // Verifica o estado atual das permissões
  Future<void> _checkPermissions() async {
    bool overlay = await FlutterOverlayWindow.isPermissionGranted();
    bool usage = await UsageStats.checkUsagePermission() ?? false;

    setState(() {
      isOverlayGranted = overlay;
      isUsageStatsGranted = usage;
    });

    // Se ambas estiverem ok, já inicia o serviço automaticamente
    if (overlay && usage && !_monitoringStarted) {
      AppTracker.startSmartPolling();
      _monitoringStarted = true;
    }
  }

  Future<void> _startMonitoring() async {
    await _checkPermissions();
    if (!mounted) {
      return;
    }

    if (isOverlayGranted && isUsageStatsGranted) {
      AppTracker.startSmartPolling();
      setState(() => _monitoringStarted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Monitoramento ativo. Troque de app para ver o overlay.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Conceda as duas permissões para iniciar.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuração AppTime")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _permissionTile(
              "Permissão de Sobreposição",
              isOverlayGranted,
              () async {
                await FlutterOverlayWindow.requestPermission();
                _checkPermissions();
              },
            ),
            const SizedBox(height: 20),
            _permissionTile(
              "Acesso às Estatísticas de Uso",
              isUsageStatsGranted,
              () async {
                await UsageStats.grantUsagePermission();
                _checkPermissions();
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: (isOverlayGranted && isUsageStatsGranted) 
                ? _startMonitoring
                : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("INICIAR MONITORAMENTO"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionTile(String title, bool granted, VoidCallback onPress) {
    return ListTile(
      title: Text(title),
      trailing: Icon(
        granted ? Icons.check_circle : Icons.error,
        color: granted ? Colors.green : Colors.red,
      ),
      onTap: granted ? null : onPress,
      tileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}