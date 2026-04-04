import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/storage_service.dart';

class AppTimeOverlay extends StatefulWidget {
  const AppTimeOverlay({super.key});

  @override
  State<AppTimeOverlay> createState() => _AppTimeOverlayState();
}

class _AppTimeOverlayState extends State<AppTimeOverlay> {
  static const Duration _fadeDuration = Duration(seconds: 2);
  Duration _rotationInterval = Duration(seconds: StorageService.rotationIntervalSeconds);

  double _opacity = 0.0;
  int _openCount = 0;
  int _sessionSeconds = 0;
  String _usage24h = '';
  bool _isLauncherMode = false;
  bool _showingTime = false;

  bool _showBorder = StorageService.showBorder;
  bool _showBackground = StorageService.showBackground;
  double _fontSize = StorageService.overlayFontSize;
  String _anchor = StorageService.overlayAnchor;
  double _hOffsetPct = StorageService.overlayLeftOffsetPct;
  double _topOffsetDp = StorageService.overlayTopOffsetDp;

  Timer? _fadeTimer;
  Timer? _rotationTimer;
  StreamSubscription<dynamic>? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen(_onData);
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _rotationTimer?.cancel();
    _overlaySubscription?.cancel();
    super.dispose();
  }

  void _onData(dynamic raw) {
    final data = _normalizePayload(raw);
    final type = data['type'] as String?;

    if (type == 'APP_OPEN') {
      _handleAppOpen((data['count'] as num?)?.toInt() ?? 0);
    } else if (type == 'APP_TICK') {
      _handleAppTick(
        (data['seconds'] as num?)?.toInt() ?? 0,
        data['daily_stats'] as String? ?? '0 min',
      );
    } else if (type == 'LAUNCHER_WAKE' || type == 'LAUNCHER_HOME') {
      _handleLauncherWake(
        (data['unlock_count'] as num?)?.toInt() ?? 0,
        data['device_usage_24h'] as String? ?? '0 min',
      );
    } else if (type == 'LAUNCHER_TICK') {
      _handleLauncherTick(data['device_usage_24h'] as String? ?? '0 min');
    } else if (type == 'SETTINGS_UPDATE') {
      _handleSettingsUpdate(data);
    }
  }

  void _handleAppOpen(int count) {
    _openCount = count;
    _sessionSeconds = 0;
    _isLauncherMode = false;
    _showingTime = false;
    _show();
    _startRotation();
    _scheduleFade(const Duration(seconds: 5));
  }

  void _handleAppTick(int seconds, String daily) {
    setState(() {
      _sessionSeconds = seconds;
      _usage24h = daily;
    });
    _scheduleFade(const Duration(seconds: 5));
  }

  void _handleLauncherWake(int unlockCount, String deviceUsage24h) {
    _openCount = unlockCount;
    _usage24h = deviceUsage24h;
    _isLauncherMode = true;
    _showingTime = false;
    _show();
    _startRotation();
    _scheduleFade(const Duration(seconds: 8));
  }

  void _handleLauncherTick(String deviceUsage24h) {
    setState(() => _usage24h = deviceUsage24h);
  }

  void _handleSettingsUpdate(Map<String, dynamic> data) {
    setState(() {
      final intervalSeconds = (data['rotation_interval'] as num?)?.toInt();
      if (intervalSeconds != null) {
        _rotationInterval = Duration(seconds: intervalSeconds);
        if (_rotationTimer?.isActive == true) _startRotation();
      }
      if (data.containsKey('show_border')) {
        _showBorder = data['show_border'] as bool;
      }
      if (data.containsKey('show_background')) {
        _showBackground = data['show_background'] as bool;
      }
      if (data.containsKey('font_size')) {
        _fontSize = (data['font_size'] as num).toDouble();
      }
      if (data.containsKey('anchor')) {
        _anchor = data['anchor'] as String;
      }
      if (data.containsKey('h_offset_pct')) {
        _hOffsetPct = (data['h_offset_pct'] as num).toDouble();
      }
      if (data.containsKey('top_offset_dp')) {
        _topOffsetDp = (data['top_offset_dp'] as num).toDouble();
      }
    });
  }

  void _show() {
    if (!mounted) return;
    setState(() => _opacity = 1.0);
  }

  void _startRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted) return;
      // Só alterna para tempo se houver dados de sessão
      if (!_showingTime && _sessionSeconds == 0 && !_isLauncherMode) return;
      setState(() => _showingTime = !_showingTime);
    });
  }

  void _scheduleFade(Duration delay) {
    _fadeTimer?.cancel();
    _fadeTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _opacity = 0.0);
      _rotationTimer?.cancel();
    });
  }

  String get _displayText {
    if (_showingTime) {
      return _isLauncherMode ? _usage24h : _formatSessionTime(_sessionSeconds);
    }
    return '${_openCount}x';
  }

  String _formatSessionTime(int seconds) {
    if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = (seconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> _normalizePayload(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final clockColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final chip = AnimatedOpacity(
                opacity: _opacity,
                duration: _fadeDuration,
                curve: Curves.easeInOut,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _showBackground
                        ? clockColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: _showBorder
                        ? Border.all(
                            color: clockColor.withValues(alpha: 0.28),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Text(
                    _displayText,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: clockColor,
                      fontSize: _fontSize,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.4),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
          );

          // Posicionamento baseado na âncora escolhida
          Widget positioned;
          switch (_anchor) {
            case 'left':
              // Chip ancorado à direita, terminando antes da câmera
              positioned = Padding(
                padding: EdgeInsets.only(top: _topOffsetDp),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: w * _hOffsetPct),
                    child: chip,
                  ),
                ),
              );
            case 'below':
              // Chip centralizado abaixo da câmera (saindo da status bar)
              positioned = Padding(
                padding: EdgeInsets.only(top: _topOffsetDp + 28),
                child: Align(alignment: Alignment.topCenter, child: chip),
              );
            default: // 'right'
              // Chip ancorado à esquerda, começando após a câmera
              positioned = Padding(
                padding: EdgeInsets.only(top: _topOffsetDp, left: w * _hOffsetPct),
                child: Align(alignment: Alignment.topLeft, child: chip),
              );
          }

          return positioned;
        },
      ),
    );
  }
}
