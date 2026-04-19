import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';

// ─── App goal level ───────────────────────────────────────────────────────────
// -1 = not monitored   0 = default   1 = minimal   2 = normal   3 = extensive

const _kNotMonitored = -1;
const _kDefault = 0;

// ─── Sort mode ────────────────────────────────────────────────────────────────

enum _Sort { usage, alpha }

// ─── Screen ───────────────────────────────────────────────────────────────────

class PerAppScreen extends StatefulWidget {
  const PerAppScreen({super.key, required this.storage});
  final StorageService storage;

  @override
  State<PerAppScreen> createState() => _PerAppScreenState();
}

class _PerAppScreenState extends State<PerAppScreen> {
  StorageService get _s => widget.storage;
  _Sort _sort = _Sort.usage;

  // 4am day boundary — mirrors MonitoringService.kt
  DateTime _anchor(DateTime dt) =>
      dt.hour < 4 ? dt.subtract(const Duration(days: 1)) : dt;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Returns (packageName, totalMs last 7 days) sorted by current mode.
  List<(String, int)> _sortedPackages() {
    final today = _anchor(DateTime.now());
    final packages = <String>{};
    for (int i = 0; i < 7; i++) {
      final dateStr = _fmt(today.subtract(Duration(days: i)));
      packages.addAll(_s.packagesDailyMs(dateStr));
    }

    final entries = packages
        .where(isUserFacingApp)
        .map((pkg) {
      int ms = 0;
      for (int i = 0; i < 7; i++) {
        final dateStr = _fmt(today.subtract(Duration(days: i)));
        ms += _s.getDailyMs(pkg, date: dateStr);
      }
      return (pkg, ms);
    }).toList();

    if (_sort == _Sort.usage) {
      entries.sort((a, b) => b.$2.compareTo(a.$2));
    } else {
      entries.sort((a, b) => a.$1.compareTo(b.$1));
    }
    return entries;
  }

  // Effective level: -1 if disabled, else app_goal (0 = default).
  int _effectiveLevel(String pkg) {
    if (_s.disabledApps.contains(pkg)) return _kNotMonitored;
    return _s.getAppGoalLevel(pkg);
  }

  void _setLevel(String pkg, int level) {
    setState(() {
      if (level == _kNotMonitored) {
        final apps = _s.disabledApps..add(pkg);
        _s.disabledApps = apps;
        _s.setAppGoalLevel(pkg, 0); // reset specific goal
      } else {
        final apps = _s.disabledApps..remove(pkg);
        _s.disabledApps = apps;
        _s.setAppGoalLevel(pkg, level);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final packages = _sortedPackages();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.perAppTitle),
        actions: [
          IconButton(
            tooltip: _sort == _Sort.usage ? 'Sort A–Z' : 'Sort by usage',
            icon: Icon(
              _sort == _Sort.usage ? Icons.sort_by_alpha : Icons.bar_chart,
            ),
            onPressed: () => setState(() {
              _sort = _sort == _Sort.usage ? _Sort.alpha : _Sort.usage;
            }),
          ),
        ],
      ),
      body: packages.isEmpty
          ? Center(child: Text(l10n.noAppsMsg))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: packages.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final (pkg, ms) = packages[i];
                final level = _effectiveLevel(pkg);
                final label = labelForApp(pkg);
                final usageStr = _fmtMs(ms);
                final appColor = colorForApp(pkg);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 4),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: appColor.withAlpha(200),
                    child: Text(
                      label.isNotEmpty ? label[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  title: Text(
                    label,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    pkg,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(usageStr,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.outline)),
                      const SizedBox(width: 8),
                      _LevelChip(
                        level: level,
                        onSelected: (v) => _setLevel(pkg, v),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _fmtMs(int ms) {
    final min = ms ~/ 60000;
    if (min < 60) return '${min}m';
    return '${min ~/ 60}h${(min % 60).toString().padLeft(2, '0')}';
  }
}

// ─── Level chip / popup ───────────────────────────────────────────────────────

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.onSelected});
  final int level;
  final ValueChanged<int> onSelected;

  static const _labels = {
    _kNotMonitored: ('off', Icons.visibility_off_outlined),
    _kDefault: ('default', Icons.tune_outlined),
    1: ('min', Icons.signal_cellular_alt_1_bar),
    2: ('normal', Icons.signal_cellular_alt_2_bar),
    3: ('max', Icons.signal_cellular_alt),
  };

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _labels[level] ?? ('default', Icons.tune_outlined);
    final isOff = level == _kNotMonitored;

    return PopupMenuButton<int>(
      onSelected: onSelected,
      itemBuilder: (_) => [
        _item(context, _kNotMonitored, 'not monitored', Icons.visibility_off_outlined),
        _item(context, _kDefault, 'default (global goal)', Icons.tune_outlined),
        const PopupMenuDivider(),
        _item(context, 1, 'minimal', Icons.signal_cellular_alt_1_bar),
        _item(context, 2, 'normal', Icons.signal_cellular_alt_2_bar),
        _item(context, 3, 'extensive', Icons.signal_cellular_alt),
      ],
      child: Chip(
        avatar: Icon(icon, size: 14,
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

  PopupMenuItem<int> _item(
      BuildContext context, int value, String text, IconData icon) {
    final selected = value == level;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon,
            size: 16,
            color: selected ? AppColors.primary : null),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ]),
    );
  }
}
