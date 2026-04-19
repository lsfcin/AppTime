import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/service_channel.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.storage,
    required this.onLocaleChange,
  });

  final StorageService storage;
  final void Function(String?) onLocaleChange;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  StorageService get _s => widget.storage;

  bool _isRunning = false;
  bool _hasOverlayPermission = false;
  bool _hasUsagePermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final results = await Future.wait([
      ServiceChannel.isRunning(),
      ServiceChannel.hasOverlayPermission(),
      ServiceChannel.hasUsagePermission(),
    ]);
    if (mounted) {
      setState(() {
        _isRunning = results[0];
        _hasOverlayPermission = results[1];
        _hasUsagePermission = results[2];
      });
    }
  }

  bool get _allGranted => _hasOverlayPermission && _hasUsagePermission;

  Future<void> _toggleMonitoring() async {
    if (!_allGranted) return;
    if (_isRunning) {
      await ServiceChannel.stopMonitoring();
    } else {
      await ServiceChannel.startMonitoring();
    }
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentCode = _s.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Permissions ────────────────────────────────────────────────
          _SectionHeader(l10n.sectionPermissions),
          Card(
            child: Column(
              children: [
                _PermissionTile(
                  label: l10n.permFloatingWindow,
                  granted: _hasOverlayPermission,
                  grantLabel: l10n.permGrant,
                  grantedLabel: l10n.permGranted,
                  requiredLabel: l10n.permRequired,
                  onRequest: () async {
                    await ServiceChannel.requestOverlayPermission();
                    await _refreshStatus();
                  },
                ),
                const Divider(height: 1, indent: 16),
                _PermissionTile(
                  label: l10n.permUsageStats,
                  granted: _hasUsagePermission,
                  grantLabel: l10n.permGrant,
                  grantedLabel: l10n.permGranted,
                  requiredLabel: l10n.permRequired,
                  onRequest: () async {
                    await ServiceChannel.requestUsagePermission();
                    await _refreshStatus();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Monitoring start/stop ──────────────────────────────────────
          _SectionHeader(l10n.sectionMonitoring),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRunning
                        ? l10n.monitoringActive
                        : _allGranted
                            ? l10n.monitoringInactive
                            : l10n.monitoringNoPerms,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.monitoringDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _allGranted ? _toggleMonitoring : null,
                    icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
                    label:
                        Text(_isRunning ? l10n.actionStop : l10n.actionStart),
                    style: _isRunning
                        ? FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Overlay ────────────────────────────────────────────────────
          _SectionHeader(l10n.sectionOverlay),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.showOverlay),
                  subtitle: Text(l10n.showOverlaySub),
                  value: _s.overlayEnabled,
                  onChanged: (v) => setState(() => _s.overlayEnabled = v),
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  title: Text(l10n.showBorder),
                  value: _s.overlayShowBorder,
                  onChanged: _s.overlayEnabled
                      ? (v) => setState(() => _s.overlayShowBorder = v)
                      : null,
                ),
                SwitchListTile(
                  title: Text(l10n.showBackground),
                  value: _s.overlayShowBackground,
                  onChanged: _s.overlayEnabled
                      ? (v) => setState(() => _s.overlayShowBackground = v)
                      : null,
                ),
                ListTile(
                  enabled: _s.overlayEnabled,
                  title: Text(l10n.fontSize(_s.overlayFontSize.round())),
                  subtitle: Slider(
                    min: 10,
                    max: 30,
                    divisions: 20,
                    value: _s.overlayFontSize,
                    onChanged: _s.overlayEnabled
                        ? (v) => setState(() => _s.overlayFontSize = v)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Behavior ──────────────────────────────────────────────────
          _SectionHeader(l10n.sectionBehavior),
          Card(
            child: SwitchListTile(
              title: Text(l10n.monitorLauncherTitle),
              subtitle: Text(l10n.monitorLauncherSub),
              value: _s.monitorLauncher,
              onChanged: (v) => setState(() => _s.monitorLauncher = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Data & Privacy ────────────────────────────────────────────
          _SectionHeader(l10n.sectionData),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: Text(l10n.privacyPolicyTitle),
                  subtitle: Text(l10n.privacyPolicySub),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => launchUrl(
                    Uri.parse('https://lsfcin.github.io/apptime/privacy_policy.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.disclaimerTitle),
                  subtitle: Text(l10n.disclaimerBody),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(l10n.deleteAllDataTitle,
                      style: const TextStyle(color: Colors.redAccent)),
                  subtitle: Text(l10n.deleteAllDataSub),
                  onTap: () => _confirmDeleteAll(l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Language ──────────────────────────────────────────────────
          _SectionHeader(l10n.sectionLanguage),
          Card(
            child: RadioGroup<String?>(
              groupValue: currentCode,
              onChanged: (code) => _changeLocale(code, l10n),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    title: Text(l10n.languageSystem),
                    value: null,
                  ),
                  RadioListTile<String?>(
                    title: Text(l10n.languagePtBr),
                    value: 'pt',
                  ),
                  RadioListTile<String?>(
                    title: Text(l10n.languageEn),
                    value: 'en',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeLocale(String? code, AppLocalizations l10n) {
    setState(() => _s.languageCode = code);
    widget.onLocaleChange(code);
  }

  Future<void> _confirmDeleteAll(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.deleteAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAllDataTitle,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _s.deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteAllDataDone)),
        );
      }
    }
  }
}

// ── Permission tile ────────────────────────────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.granted,
    required this.grantLabel,
    required this.grantedLabel,
    required this.requiredLabel,
    required this.onRequest,
  });

  final String label;
  final bool granted;
  final String grantLabel;
  final String grantedLabel;
  final String requiredLabel;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.warning_amber_rounded,
        color: granted
            ? AppColors.success
            : Theme.of(context).colorScheme.error,
      ),
      title: Text(label),
      subtitle: Text(granted ? grantedLabel : requiredLabel),
      trailing: granted
          ? null
          : TextButton(onPressed: onRequest, child: Text(grantLabel)),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
