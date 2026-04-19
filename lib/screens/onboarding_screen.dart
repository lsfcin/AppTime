import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/service_channel.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.storage,
    required this.onLocaleChange,
  });
  final StorageService storage;
  final void Function(String?) onLocaleChange;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  int _step = 0; // 0 = welcome, 1 = overlay perm, 2 = usage perm
  bool _overlayGranted = false;
  bool _usageGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final results = await Future.wait([
      ServiceChannel.hasOverlayPermission(),
      ServiceChannel.hasUsagePermission(),
    ]);
    if (!mounted) return;
    setState(() {
      _overlayGranted = results[0];
      _usageGranted = results[1];
    });
    if (_step == 1 && _overlayGranted) {
      setState(() => _step = 2);
    } else if (_step == 2 && _usageGranted) {
      _finish();
    }
    if (_overlayGranted && _usageGranted) _finish();
  }

  void _finish() {
    widget.storage.onboardingDone = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainScreen(
          storage: widget.storage,
          onLocaleChange: widget.onLocaleChange,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, AppLocalizations l10n) {
    return switch (_step) {
      0 => _WelcomeStep(
          onNext: () => setState(() => _step = 1),
          title: l10n.onboardWelcomeTitle,
          body: l10n.onboardWelcomeBody,
          startLabel: l10n.onboardStart,
        ),
      1 => _PermissionStep(
          key: const ValueKey(1),
          icon: Icons.picture_in_picture_outlined,
          title: l10n.onboardPermOverlayTitle,
          description: l10n.onboardPermOverlayDesc,
          granted: _overlayGranted,
          grantedLabel: l10n.permGrantedLabel,
          settingsHint: l10n.permSettingsHint,
          openSettingsLabel: l10n.openSettings,
          continueLabel: l10n.continueAction,
          onGrant: ServiceChannel.requestOverlayPermission,
          onNext: _overlayGranted ? () => setState(() => _step = 2) : null,
        ),
      _ => _PermissionStep(
          key: const ValueKey(2),
          icon: Icons.bar_chart_outlined,
          title: l10n.onboardPermUsageTitle,
          description: l10n.onboardPermUsageDesc,
          granted: _usageGranted,
          grantedLabel: l10n.permGrantedLabel,
          settingsHint: l10n.permSettingsHint,
          openSettingsLabel: l10n.openSettings,
          continueLabel: l10n.continueAction,
          onGrant: ServiceChannel.requestUsagePermission,
          onNext: _usageGranted ? _finish : null,
        ),
    };
  }
}

// ─── Step widgets ─────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.onNext,
    required this.title,
    required this.body,
    required this.startLabel,
  });
  final VoidCallback onNext;
  final String title;
  final String body;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Icon(Icons.timer_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNext,
            child: Text(startLabel),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.grantedLabel,
    required this.settingsHint,
    required this.openSettingsLabel,
    required this.continueLabel,
    required this.onGrant,
    required this.onNext,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final String grantedLabel;
  final String settingsHint;
  final String openSettingsLabel;
  final String continueLabel;
  final Future<void> Function() onGrant;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Row(children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        if (granted)
          Row(children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text(grantedLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.success)),
          ])
        else
          Text(
            settingsHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        const Spacer(),
        if (!granted)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGrant,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(openSettingsLabel),
            ),
          ),
        if (granted && onNext != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(continueLabel),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
