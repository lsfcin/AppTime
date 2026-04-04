import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() must be called first');
    return _prefs!;
  }

  // Overlay
  static bool get showBorder => _p.getBool('overlay_show_border') ?? true;
  static set showBorder(bool v) => _p.setBool('overlay_show_border', v);

  static bool get showBackground => _p.getBool('overlay_show_background') ?? true;
  static set showBackground(bool v) => _p.setBool('overlay_show_background', v);

  static int get rotationIntervalSeconds => _p.getInt('overlay_rotation_interval') ?? 4;
  static set rotationIntervalSeconds(int v) => _p.setInt('overlay_rotation_interval', v);

  static double get overlayLeftOffsetPct => _p.getDouble('overlay_left_offset_pct') ?? 0.53;
  static set overlayLeftOffsetPct(double v) => _p.setDouble('overlay_left_offset_pct', v);

  // 'right' = à direita da câmera | 'left' = à esquerda | 'below' = abaixo
  static String get overlayAnchor => _p.getString('overlay_anchor') ?? 'right';
  static set overlayAnchor(String v) => _p.setString('overlay_anchor', v);

  static double get overlayTopOffsetDp => _p.getDouble('overlay_top_offset_dp') ?? 8.0;
  static set overlayTopOffsetDp(double v) => _p.setDouble('overlay_top_offset_dp', v);

  static double get overlayFontSize => _p.getDouble('overlay_font_size') ?? 13.0;
  static set overlayFontSize(double v) => _p.setDouble('overlay_font_size', v);

  // Comportamento
  static bool get showOnLauncher => _p.getBool('show_on_launcher') ?? true;
  static set showOnLauncher(bool v) => _p.setBool('show_on_launcher', v);

  static bool get showOnAppOpen => _p.getBool('show_on_app_open') ?? true;
  static set showOnAppOpen(bool v) => _p.setBool('show_on_app_open', v);
}
