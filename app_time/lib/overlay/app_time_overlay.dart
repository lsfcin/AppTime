import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AppTimeOverlay extends StatefulWidget {
  const AppTimeOverlay({super.key});

  @override
  State<AppTimeOverlay> createState() => _AppTimeOverlayState();
}

class _AppTimeOverlayState extends State<AppTimeOverlay> {
  static const Duration _fadeDuration = Duration(seconds: 4);

  double _opacity = 0.0;
  String _currentText = '';
  //double _topOffset = 40.0;
  Timer? _sequenceTimer;
  StreamSubscription<dynamic>? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    _currentText = '...';
    _opacity = 1.0;
    _sequenceTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _currentText != '...') return;
      setState(() => _opacity = 0.0);
    });

    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((raw) {
      final data = _normalizePayload(raw);
      final type = data['type'] as String?;

      // if (type == 'SET_OFFSET') {
      //   setState(() {
      //     _topOffset = (data['offset'] as num?)?.toDouble() ?? 40.0;
      //   });
      // }
      if (type == 'APP_OPEN') {
        final count = (data['count'] as num?)?.toInt() ?? 0;
        _handleAppOpen(count);
      } else if (type == 'APP_TICK') {
        final seconds = (data['seconds'] as num?)?.toInt() ?? 0;
        final daily = data['daily_stats'] as String? ?? '0 min';
        _handleAppTick(seconds, daily);
      } else if (type == 'LAUNCHER_WAKE') {
        final unlockCount = (data['unlock_count'] as num?)?.toInt() ?? 0;
        final deviceUsage24h = data['device_usage_24h'] as String? ?? '0 min';
        _handleLauncherWake(unlockCount, deviceUsage24h);
      } else if (type == 'LAUNCHER_TICK') {
        final deviceUsage24h = data['device_usage_24h'] as String? ?? '0 min';
        _handleLauncherTick(deviceUsage24h);
      }
    });
  }

  Map<String, dynamic> _normalizePayload(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((key, value) => MapEntry(key.toString(), value));
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return decoded.map((key, value) => MapEntry(key.toString(), value));
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _overlaySubscription?.cancel();
    super.dispose();
  }

  void _handleAppOpen(int count) {
    _sequenceTimer?.cancel();
    setState(() {
      _currentText = '$count x';
      _opacity = 1.0;
    });

    _sequenceTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _opacity = 0.0);
    });
  }

  void _handleAppTick(int seconds, String daily) {
    if (seconds == 60) {
      setState(() {
        _currentText = '${_formatSessionTime(seconds)} | $daily';
        _opacity = 1.0;
      });
    } else if (seconds > 60) {
      setState(() {
        _currentText = '${_formatSessionTime(seconds)} | $daily';
      });
    }
  }

  void _handleLauncherWake(int unlockCount, String deviceUsage24h) {
    _sequenceTimer?.cancel();
    setState(() {
      _currentText = '$unlockCount x';
      _opacity = 1.0;
    });

    _sequenceTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _opacity = 0.0);

      _sequenceTimer = Timer(_fadeDuration, () {
        if (!mounted) return;
        setState(() {
          _currentText = deviceUsage24h;
          _opacity = 1.0;
        });
      });
    });
  }

  void _handleLauncherTick(String deviceUsage24h) {
    if (_currentText.contains(':') || _currentText.contains('min') || _currentText.contains('hrs')) {
      setState(() => _currentText = deviceUsage24h);
    }
  }

  String _formatSessionTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (hours > 0) return '$hours:$minutes:$secs';
    return '${duration.inMinutes}:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final clockColor = isDark ? Colors.white : Colors.black;
    final chipColor = clockColor.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: _fadeDuration,
          curve: Curves.easeInOut,
          child: Container(
            constraints: const BoxConstraints(minHeight: 26),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: clockColor.withValues(alpha: 0.30), width: 1),
            ),
            child: Text(
              _currentText,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: clockColor,
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                    color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.45),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
  //   final clockColor = isDark ? Colors.white : Colors.black;
  //   final chipColor = clockColor.withValues(alpha: 0.14);

  //   return Material(
  //     color: Colors.transparent, // Fundo 100% transparente para ver o WhatsApp
  //     child: Container(
  //       // DEBUG VISUAL: Essa borda vermelha agora deve aparecer contornando a tela TODA
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.redAccent, width: 2),
  //       ),
  //       child: SafeArea(
  //         // Agora o SafeArea tem a tela inteira para calcular onde a câmera/relógio estão!
  //         child: Align(
  //           alignment: Alignment.topCenter,
  //           child: AnimatedOpacity(
  //             opacity: _opacity,
  //             duration: _fadeDuration,
  //             curve: Curves.easeInOut,
  //             child: Container(
  //               constraints: const BoxConstraints(minHeight: 26),
  //               // Uma margem leve só para não ficar colado no texto do relógio
  //               margin: const EdgeInsets.only(top: 8), 
  //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: chipColor,
  //                 borderRadius: BorderRadius.circular(14),
  //                 border: Border.all(color: clockColor.withValues(alpha: 0.30), width: 1),
  //               ),
  //               child: Text(
  //                 _currentText,
  //                 maxLines: 1,
  //                 softWrap: false,
  //                 overflow: TextOverflow.visible,
  //                 style: TextStyle(
  //                   color: clockColor,
  //                   fontSize: 14,
  //                   height: 1.1,
  //                   fontWeight: FontWeight.w600,
  //                   decoration: TextDecoration.none,
  //                   letterSpacing: 0.2,
  //                   shadows: [
  //                     Shadow(
  //                       color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.45),
  //                       blurRadius: 3,
  //                       offset: const Offset(0, 1),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  // @override
  // Widget build(BuildContext context) {
  //   final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
  //   final clockColor = isDark ? Colors.white : Colors.black;
  //   final chipColor = clockColor.withValues(alpha: 0.14);

  //   return Material(
  //     color: Colors.transparent,
  //     child: Container(
  //       // DEBUG VISUAL: Borda vermelha marcando o tamanho real da janela invisível
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.redAccent, width: 2),
  //       ),
  //       child: SafeArea(
  //         // O SafeArea empurra o conteúdo para baixo da barra de status automaticamente
  //         child: Align(
  //           alignment: Alignment.topCenter,
  //           child: AnimatedOpacity(
  //             opacity: _opacity,
  //             duration: _fadeDuration,
  //             curve: Curves.easeInOut,
  //             child: Container(
  //               constraints: const BoxConstraints(minHeight: 26),
  //               margin: const EdgeInsets.only(top: 4), // Uma pequena margem extra do relógio
  //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: chipColor,
  //                 borderRadius: BorderRadius.circular(14),
  //                 border: Border.all(color: clockColor.withValues(alpha: 0.30), width: 1),
  //               ),
  //               child: Text(
  //                 _currentText,
  //                 maxLines: 1,
  //                 softWrap: false,
  //                 overflow: TextOverflow.visible,
  //                 style: TextStyle(
  //                   color: clockColor,
  //                   fontSize: 14, // Diminuí levemente para ficar mais elegante
  //                   height: 1.1,
  //                   fontWeight: FontWeight.w600,
  //                   decoration: TextDecoration.none,
  //                   letterSpacing: 0.2,
  //                   shadows: [
  //                     Shadow(
  //                       color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.45),
  //                       blurRadius: 3,
  //                       offset: const Offset(0, 1),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}