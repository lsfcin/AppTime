import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showBorder;
  late bool _showBackground;
  late bool _showOnLauncher;
  late bool _showOnAppOpen;
  late int _rotationInterval;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _showBorder = StorageService.showBorder;
    _showBackground = StorageService.showBackground;
    _showOnLauncher = StorageService.showOnLauncher;
    _showOnAppOpen = StorageService.showOnAppOpen;
    _rotationInterval = StorageService.rotationIntervalSeconds;
    _fontSize = StorageService.overlayFontSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        children: [
          // Seção: Overlay
          _SectionHeader(title: "Overlay", theme: theme),
          const SizedBox(height: AppTheme.spacingSM),

          Card(
            child: Column(
              children: [
                _ToggleTile(
                  title: "Mostrar contorno",
                  subtitle: "Exibe uma borda fina ao redor do chip de tempo",
                  value: _showBorder,
                  onChanged: (v) {
                    setState(() => _showBorder = v);
                    StorageService.showBorder = v;
                  },
                ),
                const Divider(),
                _ToggleTile(
                  title: "Mostrar fundo",
                  subtitle: "Exibe um fundo semitransparente atrás do texto",
                  value: _showBackground,
                  onChanged: (v) {
                    setState(() => _showBackground = v);
                    StorageService.showBackground = v;
                  },
                ),
                const Divider(),
                _SliderTile(
                  title: "Intervalo de rotação",
                  subtitle: "Tempo (em segundos) que cada informação fica visível",
                  value: _rotationInterval.toDouble(),
                  min: 2,
                  max: 15,
                  divisions: 13,
                  label: "${_rotationInterval}s",
                  onChanged: (v) {
                    setState(() => _rotationInterval = v.round());
                    StorageService.rotationIntervalSeconds = v.round();
                    FlutterOverlayWindow.shareData({
                      'type': 'SETTINGS_UPDATE',
                      'rotation_interval': v.round(),
                    });
                  },
                ),
                const Divider(),
                _SliderTile(
                  title: "Tamanho da fonte",
                  subtitle: "Tamanho do texto no overlay",
                  value: _fontSize,
                  min: 10,
                  max: 18,
                  divisions: 8,
                  label: "${_fontSize.round()}px",
                  onChanged: (v) {
                    setState(() => _fontSize = v);
                    StorageService.overlayFontSize = v;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // Seção: Comportamento
          _SectionHeader(title: "Comportamento", theme: theme),
          const SizedBox(height: AppTheme.spacingSM),

          Card(
            child: Column(
              children: [
                _ToggleTile(
                  title: "Mostrar ao abrir app",
                  subtitle: "Exibe a contagem de aberturas ao trocar de aplicativo",
                  value: _showOnAppOpen,
                  onChanged: (v) {
                    setState(() => _showOnAppOpen = v);
                    StorageService.showOnAppOpen = v;
                  },
                ),
                const Divider(),
                _ToggleTile(
                  title: "Mostrar na tela inicial",
                  subtitle: "Exibe desbloqueios e uso total ao pressionar home",
                  value: _showOnLauncher,
                  onChanged: (v) {
                    setState(() => _showOnLauncher = v);
                    StorageService.showOnLauncher = v;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // Seção: Posicionamento (placeholder — F8 vai expandir)
          _SectionHeader(title: "Posicionamento", theme: theme),
          const SizedBox(height: AppTheme.spacingSM),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Text(
                "Opções de posicionamento e âncora estarão disponíveis em breve.",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: AppTheme.primary,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingXS,
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              )),
            ],
          ),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingXS),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
