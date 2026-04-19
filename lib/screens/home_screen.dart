import 'dart:async';
import 'package:flutter/material.dart';
import '../data/insights.dart';
import '../l10n/app_localizations.dart';
import '../services/service_channel.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _hasOverlayPermission = false;
  bool _hasUsagePermission = false;

  late int _insightIndex;
  Timer? _insightTimer;

  static int _currentInsightIndex() {
    final minutes = DateTime.now().millisecondsSinceEpoch ~/ (3 * 60 * 1000);
    return minutes % kInsights.length;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _insightIndex = _currentInsightIndex();
    _insightTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = _currentInsightIndex();
      if (next != _insightIndex) setState(() => _insightIndex = next);
    });
    _refreshStatus();
  }

  @override
  void dispose() {
    _insightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final results = await Future.wait([
      ServiceChannel.hasOverlayPermission(),
      ServiceChannel.hasUsagePermission(),
    ]);
    if (mounted) {
      setState(() {
        _hasOverlayPermission = results[0];
        _hasUsagePermission = results[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AppTime')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _PermissionCard(
            label: l10n.permFloatingWindow,
            granted: _hasOverlayPermission,
            grantLabel: l10n.permGrant,
            grantedLabel: l10n.permGranted,
            requiredLabel: l10n.permRequired,
            onRequest: ServiceChannel.requestOverlayPermission,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PermissionCard(
            label: l10n.permUsageStats,
            granted: _hasUsagePermission,
            grantLabel: l10n.permGrant,
            grantedLabel: l10n.permGranted,
            requiredLabel: l10n.permRequired,
            onRequest: ServiceChannel.requestUsagePermission,
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightCard(
            headerLabel: l10n.insightOfDay,
            insight: kInsights[_insightIndex],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.headerLabel, required this.insight});
  final String headerLabel;
  final String insight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  headerLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(insight, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
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
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
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
            : TextButton(
                onPressed: onRequest,
                child: Text(grantLabel),
              ),
      ),
    );
  }
}
