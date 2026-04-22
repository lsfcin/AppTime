import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/insights.dart';
import '../l10n/app_localizations.dart';
import '../models/goal_config.dart';
import '../services/app_info_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';

// ── Sort mode ─────────────────────────────────────────────────────────────────
enum _Sort { usage, alpha }

const _kNotMonitored = -1;
const _kDefault = 0;

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key, required this.storage, required this.appInfo});
  final StorageService storage;
  final AppInfoService appInfo;

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  StorageService get _s => widget.storage;

  // ── Insight of the day ────────────────────────────────────────────────────
  late int _insightIndex;
  Timer? _insightTimer;

  static int _currentInsightIndex() {
    final minutes = DateTime.now().millisecondsSinceEpoch ~/ (3 * 60 * 1000);
    return minutes % kInsights.length;
  }

  // ── Per-app list ──────────────────────────────────────────────────────────
  _Sort _sort = _Sort.usage;
  late List<(String, int)> _packages;

  Map<String, String> get _appLabels => widget.appInfo.labels;

  @override
  void initState() {
    super.initState();
    _insightIndex = _currentInsightIndex();
    _packages = _sortedPackages();
    _insightTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = _currentInsightIndex();
      setState(() {
        if (next != _insightIndex) _insightIndex = next;
        _packages = _sortedPackages();
      });
    });
  }

  @override
  void dispose() {
    _insightTimer?.cancel();
    super.dispose();
  }

  // 4am boundary
  DateTime _anchor(DateTime dt) =>
      dt.hour < 4 ? dt.subtract(const Duration(days: 1)) : dt;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<(String, int)> _sortedPackages() {
    final today = _anchor(DateTime.now());
    // Single pass: accumulate per-package ms while scanning each day's packages.
    // Eliminates the previous O(7n) double-iteration (collect set, then re-scan per pkg).
    final acc = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final dateStr = _fmt(today.subtract(Duration(days: i)));
      for (final pkg in _s.packagesDailyMs(dateStr)) {
        acc[pkg] = (acc[pkg] ?? 0) + _s.getDailyMs(pkg, date: dateStr);
      }
    }

    final visible = acc.entries
        .where((e) => _showInList(e.key))
        .map((e) => (e.key, e.value))
        .toList();

    if (_sort == _Sort.usage) {
      visible.sort((a, b) => b.$2.compareTo(a.$2));
    } else {
      visible.sort((a, b) => a.$1.compareTo(b.$1));
    }
    return visible;
  }

  bool _showInList(String pkg) {
    if (isLauncherPkg(pkg) || widget.appInfo.launchers.contains(pkg)) return false;
    if (!isUserFacingApp(pkg)) return false;
    if (_appLabels.isEmpty) return true;
    return _appLabels.containsKey(pkg) || kAppMeta.containsKey(pkg);
  }

  // R18: labelForApp() already checks kAppMeta first — no need for a duplicate lookup.
  String _labelFor(String pkg) => _appLabels[pkg] ?? labelForApp(pkg);

  int _effectiveLevel(String pkg) {
    if (_s.disabledApps.contains(pkg)) return _kNotMonitored;
    return _s.getAppGoalLevel(pkg);
  }

  void _setLevel(String pkg, int level) {
    setState(() {
      if (level == _kNotMonitored) {
        final apps = _s.disabledApps..add(pkg);
        _s.disabledApps = apps;
        _s.setAppGoalLevel(pkg, 0);
      } else {
        final apps = _s.disabledApps..remove(pkg);
        _s.disabledApps = apps;
        _s.setAppGoalLevel(pkg, level);
      }
    });
  }

  String _fmtMs(int ms) {
    final min = ms ~/ 60000;
    if (min < 60) return '${min}m';
    return '${min ~/ 60}h${(min % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final globalLevel = _s.goalLevel;
    final packages = _packages;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMonitoring),
        actions: [
          IconButton(
            tooltip: _sort == _Sort.usage ? 'Sort A–Z' : 'Sort by usage',
            icon: Icon(
              _sort == _Sort.usage ? Icons.sort_by_alpha : Icons.bar_chart,
            ),
            onPressed: () => setState(() {
              _sort = _sort == _Sort.usage ? _Sort.alpha : _Sort.usage;
              _packages = _sortedPackages();
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Insight of the day ──────────────────────────────────────────
          _InsightRotatorCard(
            headerLabel: l10n.insightOfDay,
            sourceLabel: l10n.insightViewSource,
            entry: kInsights[_insightIndex],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Usage awareness feedback ────────────────────────────────
          _SectionHeader(l10n.goalLevelSectionTitle),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              l10n.goalLevelSectionCaption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          _GoalLevelCard(
            level: 0,
            name: l10n.goalLevelNone,
            rationale: l10n.goalRationaleNone,
            thresholds: null,
            selected: globalLevel == 0,
            onTap: () => setState(() => _s.goalLevel = 0),
          ),
          const SizedBox(height: AppSpacing.sm),
          _GoalLevelCard(
            level: 1,
            name: l10n.goalLevelMinimal,
            rationale: l10n.goalRationaleMinimal,
            thresholds: GoalThresholds.byLevel[GoalLevel.minimal]!,
            selected: globalLevel == 1,
            onTap: () => setState(() => _s.goalLevel = 1),
          ),
          const SizedBox(height: AppSpacing.sm),
          _GoalLevelCard(
            level: 2,
            name: l10n.goalLevelNormal,
            rationale: l10n.goalRationaleNormal,
            thresholds: GoalThresholds.byLevel[GoalLevel.normal]!,
            selected: globalLevel == 2,
            onTap: () => setState(() => _s.goalLevel = 2),
          ),
          const SizedBox(height: AppSpacing.sm),
          _GoalLevelCard(
            level: 3,
            name: l10n.goalLevelExtensive,
            rationale: l10n.goalRationaleExtensive,
            thresholds: GoalThresholds.byLevel[GoalLevel.extensive]!,
            selected: globalLevel == 3,
            onTap: () => setState(() => _s.goalLevel = 3),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Per-app control (inline) ────────────────────────────────────
          _SectionHeader(l10n.perAppControlTitle),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
            child: Text(
              l10n.perAppUsageCaption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          if (packages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.noAppsMsg,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < packages.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16),
                    _buildAppRow(context, l10n, packages[i]),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildAppRow(
      BuildContext context, AppLocalizations l10n, (String, int) entry) {
    final (pkg, ms) = entry;
    final level = _effectiveLevel(pkg);
    final label = _labelFor(pkg);
    final appColor = colorForApp(pkg);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: appColor.withAlpha(200),
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _fmtMs(ms),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
      trailing: _LevelChip(
        level: level,
        onSelected: (v) => _setLevel(pkg, v),
      ),
    );
  }
}

// ── Insight card ───────────────────────────────────────────────────────────────

class _InsightRotatorCard extends StatelessWidget {
  const _InsightRotatorCard({
    required this.headerLabel,
    required this.sourceLabel,
    required this.entry,
  });
  final String headerLabel;
  final String sourceLabel;
  final InsightEntry entry;

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
            Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? entry.textEn
                  : entry.text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final uri = Uri.tryParse(entry.url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  sourceLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal level card ────────────────────────────────────────────────────────────

class _GoalLevelCard extends StatelessWidget {
  const _GoalLevelCard({
    required this.level,
    required this.name,
    required this.rationale,
    required this.thresholds,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final String name;
  final String rationale;
  final GoalThresholds? thresholds;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = selected
        ? BorderSide(color: AppColors.primary, width: 2)
        : BorderSide(color: scheme.outline.withValues(alpha: 0.3));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md, side: border),
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (selected)
                  const Icon(Icons.radio_button_checked,
                      color: AppColors.primary, size: 20)
                else
                  Icon(Icons.radio_button_unchecked,
                      color: scheme.onSurface.withValues(alpha: 0.4), size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primary : null,
                        )),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text(rationale,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      )),
              if (thresholds != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Chip('${thresholds!.phoneLimitMinutes}min total'),
                    _Chip('${thresholds!.appLimitMinutes}min/app'),
                    _Chip('${thresholds!.unlockLimit}× unlocks'),
                    _Chip('${thresholds!.maxSessionMinutes}min session'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Level chip / popup ────────────────────────────────────────────────────────

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.onSelected});
  final int level;
  final ValueChanged<int> onSelected;

  static const _icons = {
    _kNotMonitored: Icons.visibility_off_outlined,
    _kDefault: Icons.tune_outlined,
    1: Icons.signal_cellular_alt_1_bar,
    2: Icons.signal_cellular_alt_2_bar,
    3: Icons.signal_cellular_alt,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chipLabels = {
      _kNotMonitored: l10n.levelChipOff,
      _kDefault: l10n.levelChipDefault,
      1: l10n.levelMenuMinimal,
      2: l10n.levelMenuNormal,
      3: l10n.levelMenuExtensive,
    };
    final label = chipLabels[level] ?? l10n.levelChipDefault;
    final icon = _icons[level] ?? Icons.tune_outlined;
    final isOff = level == _kNotMonitored;

    return PopupMenuButton<int>(
      onSelected: onSelected,
      itemBuilder: (_) => [
        _item(context, l10n, _kNotMonitored, l10n.levelMenuNotMonitored,
            Icons.visibility_off_outlined),
        _item(context, l10n, _kDefault, l10n.levelMenuDefault,
            Icons.tune_outlined),
        const PopupMenuDivider(),
        _item(context, l10n, 1, l10n.levelMenuMinimal,
            Icons.signal_cellular_alt_1_bar),
        _item(context, l10n, 2, l10n.levelMenuNormal,
            Icons.signal_cellular_alt_2_bar),
        _item(context, l10n, 3, l10n.levelMenuExtensive,
            Icons.signal_cellular_alt),
      ],
      child: Chip(
        avatar: Icon(icon,
            size: 14,
            color: isOff
                ? Theme.of(context).colorScheme.outline
                : AppColors.primary),
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isOff
                    ? Theme.of(context).colorScheme.outline
                    : AppColors.primary)),
        side: BorderSide(
            color: isOff
                ? Theme.of(context).colorScheme.outlineVariant
                : AppColors.primary.withAlpha(120)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  PopupMenuItem<int> _item(BuildContext context, AppLocalizations l10n,
      int value, String text, IconData icon) {
    final selected = value == level;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 16, color: selected ? AppColors.primary : null),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ]),
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
              color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
