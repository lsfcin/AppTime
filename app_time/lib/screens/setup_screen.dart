import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/background_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  bool _monitoringStarted = false;
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
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      bool overlay = await FlutterOverlayWindow.isPermissionGranted();
      bool usage = await UsageStats.checkUsagePermission() ?? false;
      
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
    if (isOverlayGranted && isUsageStatsGranted) {
      try {
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }

        final double statusBarHeight = MediaQuery.of(context).padding.top;
        await FlutterOverlayWindow.shareData({
          "type": "SET_OFFSET",
          "offset": statusBarHeight,
        });

        await initializeBackgroundService();
        
        final service = FlutterBackgroundService();
        bool isRunning = await service.isRunning();
        
        if (!isRunning) {
          await service.startService(); 
        }
        
        setState(() => _monitoringStarted = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Monitoramento persistente ativo!")),
          );
        }
      } catch (e) {
        debugPrint("Erro crítico ao iniciar serviço: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao iniciar serviço: $e")),
          );
        }
      }
    }
  }

  Future<void> _showInstructionDialog({
    required String title,
    required String instruction,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(instruction),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              onConfirm(); 
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("ENTENDI"),
          ),
        ],
      ),
    );
  }

  // Neste código o retângulo aperece onde deveria
  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     debugShowCheckedModeBanner: false,
  //     home: Scaffold(
  //       body: SafeArea(
  //         child: Container(
  //           color: Colors.amberAccent,
  //           height: 300,
  //           width: 200,
  //           margin: const EdgeInsets.all(20),
  //           child: const Text('Flutter'),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuração AppTime")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Precisamos de algumas permissões para que o AppTime funcione perfeitamente.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            
            _permissionTile("Janela Flutuante", isOverlayGranted, () {
              _showInstructionDialog(
                title: "Sobreposição de Tela",
                instruction: "Na próxima tela, procure pelo 'AppTime' na lista e ative a chave. Isso permite que o nosso contador apareça por cima dos outros aplicativos.",
                onConfirm: () async {
                  try {
                    await Permission.systemAlertWindow.request();
                  } catch (_) {}
                  _checkPermissions();
                },
              );
            }),
            const SizedBox(height: 12),
            
            _permissionTile("Estatísticas de Uso", isUsageStatsGranted, () {
              _showInstructionDialog(
                title: "Acesso aos Dados de Uso",
                instruction: "Precisamos saber qual aplicativo está aberto para contar o seu tempo. Na lista a seguir, clique no 'AppTime' e permita o acesso.",
                onConfirm: () async {
                  try {
                    await UsageStats.grantUsagePermission();
                  } catch (_) {}
                  _checkPermissions();
                },
              );
            }),
            const SizedBox(height: 12),
            
            _permissionTile("Manter Ativo (Bateria)", isBatteryOptIgnored, () {
              _showInstructionDialog(
                title: "Funcionamento em Segundo Plano",
                instruction: "Para o app não parar de funcionar sozinho, permita que ele ignore a otimização de bateria do sistema no próximo aviso.",
                onConfirm: () async {
                  try {
                    await Permission.ignoreBatteryOptimizations.request();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Por favor, configure manualmente nas configurações de bateria do celular.")),
                      );
                    }
                  }
                  _checkPermissions();
                },
              );
            }),
            
            const Spacer(),
            ElevatedButton(
              onPressed: (isOverlayGranted && isUsageStatsGranted) ? _startMonitoring : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(255),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("INICIAR MONITORAMENTO (GRANDE)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionTile(String title, bool granted, VoidCallback onPress) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(granted ? Icons.check_circle : Icons.error, color: granted ? Colors.green : Colors.red),
      onTap: granted ? null : onPress,
      tileColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: granted ? Colors.green.withOpacity(0.5) : Colors.transparent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}