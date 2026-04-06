import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodDays = 1; // 1, 7, or 30
  bool _loading = true;

  List<_DailyUsage> _dailyData = [];
  List<_AppUsage> _topApps = [];
  double _totalHours = 0;

  static const List<String> _launchers = [
    "com.google.android.apps.nexuslauncher",
    "com.sec.android.app.launcher",
    "com.miui.home",
    "com.android.launcher",
    "com.android.launcher3",
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final end = DateTime.now();
      final start = DateTime(end.year, end.month, end.day - _periodDays + 1);

      final stats = await UsageStats.queryUsageStats(start, end);
      final appStats = stats.where((s) =>
          s.packageName != null &&
          s.totalTimeInForeground != null &&
          !_launchers.contains(s.packageName) &&
          (int.tryParse(s.totalTimeInForeground!) ?? 0) > 60000);

      // Top apps for the period
      final appList = appStats
          .map((s) => _AppUsage(
                packageName: s.packageName!,
                minutes: (int.parse(s.totalTimeInForeground!)) / 60000,
              ))
          .toList()
        ..sort((a, b) => b.minutes.compareTo(a.minutes));
      _topApps = appList.take(6).toList();

      // Total
      _totalHours = _topApps.fold(0.0, (sum, a) => sum + a.minutes) / 60;

      // Daily breakdown
      _dailyData = [];
      for (int d = _periodDays - 1; d >= 0; d--) {
        final dayStart = DateTime(end.year, end.month, end.day - d);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final dayStats = await UsageStats.queryUsageStats(dayStart, dayEnd);
        final dayMinutes = dayStats
            .where((s) =>
                s.packageName != null &&
                s.totalTimeInForeground != null &&
                !_launchers.contains(s.packageName))
            .fold(0.0, (sum, s) => sum + (int.tryParse(s.totalTimeInForeground!) ?? 0) / 60000);
        _dailyData.add(_DailyUsage(date: dayStart, minutes: dayMinutes));
      }

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Análise")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              children: [
                // Period selector
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text("Hoje")),
                    ButtonSegment(value: 7, label: Text("7 dias")),
                    ButtonSegment(value: 30, label: Text("30 dias")),
                  ],
                  selected: {_periodDays},
                  onSelectionChanged: (s) {
                    setState(() => _periodDays = s.first);
                    _load();
                  },
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // Summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    child: Row(
                      children: [
                        Icon(Icons.phone_android_rounded,
                            color: AppTheme.primary, size: 36),
                        const SizedBox(width: AppTheme.spacingMD),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _periodDays == 1 ? "Uso hoje" : "Uso em $_periodDays dias",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            Text(
                              _formatHours(_totalHours),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Daily bar chart (only for multi-day periods)
                if (_periodDays > 1 && _dailyData.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingMD),
                  _SectionLabel(title: "Uso diário"),
                  const SizedBox(height: AppTheme.spacingSM),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                      child: SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _dailyData.map((d) => d.minutes / 60).reduce((a, b) => a > b ? a : b) * 1.3,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final h = rod.toY;
                                  final label = h < 1
                                      ? '${(h * 60).round()} min'
                                      : '${h.toStringAsFixed(1)}h';
                                  return BarTooltipItem(label,
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600));
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= _dailyData.length) return const SizedBox();
                                    final d = _dailyData[idx].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${d.day}/${d.month}',
                                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const SizedBox();
                                    return Text(
                                      '${value.toStringAsFixed(1)}h',
                                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(_dailyData.length, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: _dailyData[i].minutes / 60,
                                    color: AppTheme.primary,
                                    width: _periodDays <= 7 ? 18 : 8,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Top apps horizontal bar chart
                if (_topApps.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingMD),
                  _SectionLabel(title: "Top apps"),
                  const SizedBox(height: AppTheme.spacingSM),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      child: Column(
                        children: _topApps.map((app) {
                          final fraction = _topApps.isEmpty ? 0.0 : app.minutes / _topApps.first.minutes;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _prettify(app.packageName),
                                        style: theme.textTheme.titleSmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatMinutes(app.minutes),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 6,
                                    backgroundColor:
                                        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],

                if (_topApps.isEmpty && !_loading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: Text(
                        "Nenhum dado disponível para este período.",
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  static String _prettify(String pkg) {
    const noise = {
      'com', 'org', 'net', 'io', 'co', 'android', 'app', 'apps',
      'google', 'phone', 'mobile', 'inc',
    };
    final parts = pkg.split('.');
    final meaningful = parts.where((p) => !noise.contains(p.toLowerCase()) && p.length > 2);
    final best = meaningful.isNotEmpty ? meaningful.last : parts.last;
    return best[0].toUpperCase() + best.substring(1);
  }

  static String _formatHours(double hours) {
    if (hours < 1) return '${(hours * 60).round()} min';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  static String _formatMinutes(double minutes) {
    if (minutes < 60) return '${minutes.round()} min';
    return '${(minutes / 60).toStringAsFixed(1)}h';
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

class _DailyUsage {
  final DateTime date;
  final double minutes;
  const _DailyUsage({required this.date, required this.minutes});
}

class _AppUsage {
  final String packageName;
  final double minutes;
  const _AppUsage({required this.packageName, required this.minutes});
}
