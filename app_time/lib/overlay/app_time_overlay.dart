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

  // Drag-to-reposition state
  bool _dragging = false;
  Offset _dragPosition = Offset.zero;

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
    if (_dragging) return;
    _openCount = count;
    _sessionSeconds = 0;
    _isLauncherMode = false;
    _showingTime = false;
    _show();
    _startRotation();
    _scheduleFade(const Duration(seconds: 5));
  }

  void _handleAppTick(int seconds, String daily) {
    if (_dragging) return;
    setState(() {
      _sessionSeconds = seconds;
      _usage24h = daily;
    });
    _scheduleFade(const Duration(seconds: 5));
  }

  void _handleLauncherWake(int unlockCount, String deviceUsage24h) {
    if (_dragging) return;
    _openCount = unlockCount;
    _usage24h = deviceUsage24h;
    _isLauncherMode = true;
    _showingTime = false;
    _show();
    _startRotation();
    _scheduleFade(const Duration(seconds: 8));
  }

  void _handleLauncherTick(String deviceUsage24h) {
    if (_dragging) return;
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

  // --- Drag to reposition ---

  void _enterDragMode(double screenWidth) {
    // Cancel any pending fade so chip stays visible while dragging
    _fadeTimer?.cancel();
    _rotationTimer?.cancel();

    // Compute chip's approximate top-left from current anchor settings
    final double chipWidth = _fontSize * 3.5; // rough estimate
    Offset initial;
    switch (_anchor) {
      case 'left':
        initial = Offset(screenWidth - screenWidth * _hOffsetPct - chipWidth, _topOffsetDp);
      case 'below':
        initial = Offset(screenWidth / 2 - chipWidth / 2, _topOffsetDp + 28);
      default: // 'right'
        initial = Offset(screenWidth * _hOffsetPct, _topOffsetDp);
    }

    setState(() {
      _dragging = true;
      _opacity = 1.0;
      _dragPosition = initial;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragPosition += details.delta);
  }

  void _onDragEnd(double screenWidth) {
    final double chipWidth = _fontSize * 3.5;
    final double centerX = _dragPosition.dx + chipWidth / 2;
    final double topY = _dragPosition.dy.clamp(0.0, 80.0);

    // Auto-detect anchor from final horizontal position
    String newAnchor;
    double newHOffsetPct;

    if (topY > 50) {
      // Dragged below status bar area → 'below' anchor
      newAnchor = 'below';
      newHOffsetPct = _hOffsetPct;
    } else if (centerX <= screenWidth / 2) {
      // Chip center in left half → chip is right of camera → anchor 'right'
      newAnchor = 'right';
      newHOffsetPct = (_dragPosition.dx / screenWidth).clamp(0.3, 0.8);
    } else {
      // Chip center in right half → chip is left of camera → anchor 'left'
      newAnchor = 'left';
      newHOffsetPct = ((screenWidth - _dragPosition.dx - chipWidth) / screenWidth).clamp(0.3, 0.8);
    }

    final double newTopOffsetDp = newAnchor == 'below'
        ? (_dragPosition.dy - 28).clamp(0.0, 40.0)
        : topY.clamp(0.0, 40.0);

    setState(() {
      _dragging = false;
      _anchor = newAnchor;
      _hOffsetPct = newHOffsetPct;
      _topOffsetDp = newTopOffsetDp;
    });

    // Persist and sync to main app
    StorageService.overlayAnchor = newAnchor;
    StorageService.overlayLeftOffsetPct = newHOffsetPct;
    StorageService.overlayTopOffsetDp = newTopOffsetDp;
    FlutterOverlayWindow.shareData({
      'type': 'SETTINGS_UPDATE',
      'anchor': newAnchor,
      'h_offset_pct': newHOffsetPct,
      'top_offset_dp': newTopOffsetDp,
    });

    // Resume normal fade after a brief pause
    _scheduleFade(const Duration(seconds: 2));
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

          final chipWidget = Container(
            constraints: const BoxConstraints(minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _showBackground
                  ? clockColor.withValues(alpha: _dragging ? 0.22 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: (_showBorder || _dragging)
                  ? Border.all(
                      color: _dragging
                          ? Colors.white.withValues(alpha: 0.8)
                          : clockColor.withValues(alpha: 0.28),
                      width: _dragging ? 1.5 : 1,
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
          );

          // --- Drag mode: full-screen Stack with draggable chip ---
          if (_dragging) {
            return Stack(
              children: [
                // Dim scrim so user knows they're in drag mode
                Container(color: Colors.black.withValues(alpha: 0.25)),
                // Hint text
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Solte para salvar a posição',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                // Draggable chip
                Positioned(
                  left: _dragPosition.dx.clamp(0, w - 80),
                  top: _dragPosition.dy.clamp(0, constraints.maxHeight - 60),
                  child: GestureDetector(
                    onPanUpdate: _onDragUpdate,
                    onPanEnd: (_) => _onDragEnd(w),
                    child: chipWidget,
                  ),
                ),
              ],
            );
          }

          // --- Normal mode: animated chip at anchor position ---
          final chip = AnimatedOpacity(
            opacity: _opacity,
            duration: _fadeDuration,
            curve: Curves.easeInOut,
            child: GestureDetector(
              onLongPress: () => _enterDragMode(w),
              child: chipWidget,
            ),
          );

          Widget positioned;
          switch (_anchor) {
            case 'left':
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
              positioned = Padding(
                padding: EdgeInsets.only(top: _topOffsetDp + 28),
                child: Align(alignment: Alignment.topCenter, child: chip),
              );
            default: // 'right'
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
