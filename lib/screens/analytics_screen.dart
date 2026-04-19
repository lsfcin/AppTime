import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart' show labelForApp;

// ─── Passive app heuristic ────────────────────────────────────────────────────
const _passivePatterns = [
  'instagram', 'tiktok', 'youtube', 'netflix', 'twitter', 'facebook',
  'reddit', 'pinterest', 'snapchat', 'twitch', 'hulu', 'disneyplus',
  'kwai', 'likee', 'reels', 'shorts',
];

bool _isPassive(String pkg) {
  final lower = pkg.toLowerCase();
  return _passivePatterns.any(lower.contains);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.storage});
  final StorageService storage;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnalyticsService _analytics;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _analytics = AnalyticsService(widget.storage);
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.tab1d),
            Tab(text: l10n.tab7d),
            Tab(text: l10n.tab30d),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _Tab1d(storage: widget.storage, analytics: _analytics),
          _Tab7d(storage: widget.storage, analytics: _analytics),
          _Tab30d(storage: widget.storage, analytics: _analytics),
        ],
      ),
    );
  }
}

// ─── Tab helpers ─────────────────────────────────────────────────────────────

String _fmtDuration(int ms) {
  final totalMin = ms ~/ 60000;
  if (totalMin < 60) return '${totalMin}min';
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  return '${h}h${m.toString().padLeft(2, '0')}';
}

/// Day starts at 04:00 — mirrors the 4 AM boundary in MonitoringService.kt.
DateTime _dayAnchor(DateTime dt) =>
    dt.hour < 4 ? dt.subtract(const Duration(days: 1)) : dt;

String _todayStr() {
  final d = _dayAnchor(DateTime.now());
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _yesterdayStr() {
  final d = _dayAnchor(DateTime.now()).subtract(const Duration(days: 1));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Widget _analysisCard({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Widget chart,
  required String text,
  double? chartHeight = 140, // null = let chart size itself
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
          ]),
          const SizedBox(height: AppSpacing.sm),
          chartHeight != null
              ? SizedBox(height: chartHeight, child: chart)
              : chart,
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

Widget _noData(BuildContext context, String msg) => Center(
      child: Text(msg,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline)),
    );

// ─── TAB 1 dia ───────────────────────────────────────────────────────────────

class _Tab1d extends StatelessWidget {
  const _Tab1d({required this.storage, required this.analytics});
  final StorageService storage;
  final AnalyticsService analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = _todayStr();
    final yesterday = _yesterdayStr();
    final summaries = analytics.getSummaries(1);
    final summary = summaries.isEmpty ? null : summaries.first;
    final totalMs = summary?.totalMs ?? 0;
    final unlocks = summary?.unlockCount ?? 0;

    final hourlyMs = storage.getDeviceHourlyBreakdown(today);
    final hourlyUnlocks = storage.getHourlyUnlockBreakdown(today);
    final sessionBuckets = storage.getSessionBuckets();
    final hasHourly = hourlyMs.any((v) => v > 0);

    final avgMinDay1d = totalMs ~/ 60000;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _analysisCard(
          context: context,
          icon: Icons.analytics_outlined,
          title: l10n.block30dSummaryTitle,
          chartHeight: null,
          chart: _Summary30dWidget(
            avgMinDay: avgMinDay1d,
            avgUnlocksDay: unlocks,
            totalMs: totalMs,
            totalUnlocks: unlocks,
            nDays: 1,
            l10n: l10n,
          ),
          text: _classificationMessage(l10n, avgMinDay1d, unlocks),
        ),

        _analysisCard(
          context: context,
          icon: Icons.bedtime_outlined,
          title: l10n.blockSleepTitle,
          chartHeight: 150,
          chart: hasHourly
              ? _HourlyBarChart(
                  values: hourlyMs,
                  highlightHours:  {21, 22, 23},       // late evening — deep orange
                  highlightColor:  const Color(0xFFE65100),
                  highlightHours2: {0, 1, 2, 3, 4, 5, 6, 7, 8}, // before 9 AM — indigo
                  highlightColor2: const Color(0xFF4527A0),
                )
              : _noData(context, l10n.collectingData),
          text: _sleepText(l10n, hourlyMs, totalMs),
        ),

        _analysisCard(
          context: context,
          icon: Icons.view_timeline_outlined,
          title: l10n.blockYesterdayPatternTitle,
          chartHeight: null,
          chart: _YesterdayPatternChart(
            appHourly: storage.getAppHourlyBreakdown(yesterday),
            l10n: l10n,
            disabledApps: storage.disabledApps,
          ),
          text: l10n.blockYesterdayPatternText,
        ),

        _analysisCard(
          context: context,
          icon: Icons.bolt_outlined,
          title: l10n.blockImpulsivityTitle,
          chart: hasHourly
              ? _HourlyBarChart(values: hourlyUnlocks, color: AppColors.error)
              : _noData(context, l10n.collectingData),
          text: l10n.blockImpulsivityText(unlocks),
        ),

        _analysisCard(
          context: context,
          icon: Icons.grid_view_outlined,
          title: l10n.blockFocusTitle,
          chart: sessionBuckets.any((v) => v > 0)
              ? _SessionHistogram(buckets: sessionBuckets)
              : _noData(context, l10n.collectingData),
          text: _focusText(l10n, sessionBuckets),
        ),

        _analysisCard(
          context: context,
          icon: Icons.hourglass_empty_outlined,
          title: l10n.blockOpportunityTitle,
          chartHeight: 80,
          chart: _OpportunityCostWidget(totalMs: totalMs, l10n: l10n),
          text: l10n.blockOpportunityText,
        ),

        _analysisCard(
          context: context,
          icon: Icons.group_outlined,
          title: l10n.blockPhubbingTitle,
          chart: hasHourly
              ? _HourlyBarChart(
                  values: hourlyUnlocks,
                  highlightHours: {12, 13, 14, 19, 20, 21},
                  color: AppColors.primary,
                )
              : _noData(context, l10n.collectingData),
          text: _phubbingText(l10n, hourlyUnlocks),
        ),

        // Day-boundary note
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 12,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.dayBoundaryNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _sleepText(AppLocalizations l10n, List<int> hourly, int totalMs) {
    final lateMs = [22, 23, 0, 1, 2, 3, 4, 5]
        .fold<int>(0, (sum, h) => sum + hourly[h]);
    final pct = totalMs > 0 ? (lateMs / totalMs * 100).round() : 0;
    return l10n.blockSleepText(pct);
  }

  String _focusText(AppLocalizations l10n, List<int> buckets) {
    final total = buckets.fold(0, (a, b) => a + b);
    if (total == 0) return l10n.noSessions;
    final pct = (buckets[0] / total * 100).round();
    return l10n.blockFocusText(pct);
  }

  String _phubbingText(AppLocalizations l10n, List<int> hourlyUnlocks) {
    final mealUnlocks = [12, 13, 14, 19, 20, 21]
        .fold<int>(0, (sum, h) => sum + hourlyUnlocks[h]);
    return l10n.blockPhubbingText(mealUnlocks);
  }
}

// ─── TAB 7 dias ───────────────────────────────────────────────────────────────

class _Tab7d extends StatelessWidget {
  const _Tab7d({required this.storage, required this.analytics});
  final StorageService storage;
  final AnalyticsService analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summaries = analytics.getSummaries(7);
    final totalMs = summaries.fold<int>(0, (acc, s) => acc + s.totalMs);
    final totalUnlocks = summaries.fold<int>(0, (acc, s) => acc + s.unlockCount);

    final aggApps = <String, _AppAgg>{};
    for (final s in summaries) {
      for (final a in s.apps) {
        final agg = aggApps.putIfAbsent(a.packageName, () => _AppAgg(a.packageName));
        agg.ms += a.dailyMs;
        agg.opens += a.openCount;
      }
    }
    // Exclude launchers and pseudoapps from dopamine drain — not real user triggers.
    final sorted = aggApps.values
        .where((a) => !_isLauncher(a.packageName) && !_isPseudoApp(a.packageName))
        .toList()
      ..sort((a, b) => b.opens.compareTo(a.opens));
    final topFive = sorted.take(5).toList();

    final passiveMs = aggApps.values
        .where((a) => _isPassive(a.packageName))
        .fold<int>(0, (s, a) => s + a.ms);
    final activeMs = totalMs - passiveMs;

    final dailyBars = summaries.reversed.toList();

    final prevSummaries = _prevWeekSummaries();
    final prevAvgMs = prevSummaries.isEmpty
        ? 0
        : prevSummaries.fold<int>(0, (s, d) => s + d) ~/ prevSummaries.length;
    final thisAvgMs = summaries.isEmpty ? 0 : totalMs ~/ summaries.length;
    final trendPct = prevAvgMs > 0
        ? ((thisAvgMs - prevAvgMs) / prevAvgMs * 100).round()
        : 0;

    // Data for 7-day hourly pattern chart (oldest first)
    final sevenDates = List.generate(7, (i) =>
        _dateStr(_dayAnchor(DateTime.now()).subtract(Duration(days: 6 - i))));
    final sevenDayHourly = [
      for (final d in sevenDates)
        (d, storage.getAppHourlyBreakdown(d)), // full dateStr; chart converts to weekday label
    ];

    final avgMinDay7d = summaries.isEmpty ? 0 : totalMs ~/ (summaries.length * 60000);
    final avgUnlocksDay7d = summaries.isEmpty ? 0 : totalUnlocks ~/ summaries.length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _analysisCard(
          context: context,
          icon: Icons.analytics_outlined,
          title: l10n.block30dSummaryTitle,
          chartHeight: null,
          chart: _Summary30dWidget(
            avgMinDay: avgMinDay7d,
            avgUnlocksDay: avgUnlocksDay7d,
            totalMs: totalMs,
            totalUnlocks: totalUnlocks,
            nDays: summaries.length.clamp(1, 7),
            l10n: l10n,
          ),
          text: _classificationMessage(l10n, avgMinDay7d, avgUnlocksDay7d),
        ),

        _analysisCard(
          context: context,
          icon: Icons.calendar_view_week_outlined,
          title: l10n.blockLastDaysPatternTitle,
          chartHeight: null,
          chart: _LastDaysPatternChart(
            daysData: sevenDayHourly,
            l10n: l10n,
            disabledApps: storage.disabledApps,
          ),
          text: l10n.blockLastDaysPatternText,
        ),

        if (dailyBars.isNotEmpty) ...[
          Text(l10n.dailyUsageLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 130,
            child: BarChart(BarChartData(
              barGroups: dailyBars.asMap().entries.map((e) {
                final hours = e.value.totalMs / 3_600_000;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: hours,
                    color: AppColors.primary,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      if (v == 0 || v % 1 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text('${v.toInt()}h',
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.right),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: Color(0x22FFFFFF),
                  strokeWidth: 0.5,
                ),
              ),
            )),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        _analysisCard(
          context: context,
          icon: Icons.psychology_outlined,
          title: l10n.blockDopamineTitle,
          chartHeight: topFive.isEmpty ? 60 : (topFive.length * 44.0),
          chart: topFive.isEmpty
              ? _noData(context, l10n.noData)
              : _HorizontalAppBars(apps: topFive, maxOpens: topFive.first.opens),
          text: topFive.isEmpty
              ? l10n.blockDopamineNoData
              : l10n.blockDopamineText(
                  _labelForApp(topFive.first.packageName),
                  topFive.first.opens,
                ),
        ),

        _analysisCard(
          context: context,
          icon: Icons.balance_outlined,
          title: l10n.blockEngagementTitle,
          chartHeight: 160,
          chart: (passiveMs + activeMs) > 0
              ? _DonutChart(passiveMs: passiveMs, activeMs: activeMs, l10n: l10n)
              : _noData(context, l10n.noData),
          text: _engagementText(l10n, passiveMs, totalMs),
        ),

        _analysisCard(
          context: context,
          icon: Icons.trending_down_outlined,
          title: l10n.blockTrendTitle,
          chartHeight: 175,
          chart: _TrendBars(
            thisWeek: dailyBars.map((s) => s.totalMs).toList(),
            dates: sevenDates,
            prevAvgMs: prevAvgMs,
            prevWeekLabel: l10n.prevWeekLabel,
          ),
          text: trendPct <= 0
              ? l10n.blockTrendReduced(trendPct.abs())
              : l10n.blockTrendIncreased(trendPct),
        ),
      ],
    );
  }

  String _engagementText(AppLocalizations l10n, int passiveMs, int totalMs) {
    if (totalMs == 0) return l10n.blockEngagementNoData;
    final pct = (passiveMs / totalMs * 100).round();
    return l10n.blockEngagementText(pct);
  }

  List<int> _prevWeekSummaries() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final date = _dateStr(today.subtract(Duration(days: i + 7)));
      return storage.getDeviceDailyMs(date: date);
    });
  }
}

// ─── TAB 30 dias ─────────────────────────────────────────────────────────────

class _Tab30d extends StatelessWidget {
  const _Tab30d({required this.storage, required this.analytics});
  final StorageService storage;
  final AnalyticsService analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summaries = analytics.getSummaries(30);
    final nDays = summaries.length.clamp(1, 30);
    final totalMs = summaries.fold<int>(0, (acc, s) => acc + s.totalMs);
    final totalUnlocks = summaries.fold<int>(0, (acc, s) => acc + s.unlockCount);
    final avgMinDay = totalMs ~/ (nDays * 60000);
    final avgUnlocksDay = totalUnlocks ~/ nDays;

    // Engagement
    final aggApps = <String, _AppAgg>{};
    for (final s in summaries) {
      for (final a in s.apps) {
        if (_isLauncher(a.packageName) || _isPseudoApp(a.packageName)) continue;
        final agg = aggApps.putIfAbsent(a.packageName, () => _AppAgg(a.packageName));
        agg.ms += a.dailyMs;
        agg.opens += a.openCount;
      }
    }
    final passiveMs = aggApps.values
        .where((a) => _isPassive(a.packageName))
        .fold<int>(0, (s, a) => s + a.ms);
    final activeMs = totalMs - passiveMs;

    // Top 3 apps for trend chart
    final sorted = (aggApps.values.toList()..sort((a, b) => b.ms.compareTo(a.ms)));
    final top3 = sorted.take(3).map((a) => a.packageName).toList();
    final dailyChron = summaries.reversed.toList();
    final appDailyMs = <String, List<int>>{
      for (final pkg in top3)
        pkg: dailyChron.map((s) {
          final match = s.apps.where((a) => a.packageName == pkg);
          return match.isEmpty ? 0 : match.first.dailyMs;
        }).toList(),
    };
    final dailyMs = dailyChron.map((s) => s.totalMs).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Summary classification card ──────────────────────────────────────
        _analysisCard(
          context: context,
          icon: Icons.analytics_outlined,
          title: l10n.block30dSummaryTitle,
          chartHeight: null,
          chart: _Summary30dWidget(
            avgMinDay: avgMinDay,
            avgUnlocksDay: avgUnlocksDay,
            totalMs: totalMs,
            totalUnlocks: totalUnlocks,
            nDays: nDays,
            l10n: l10n,
          ),
          text: _classificationMessage(l10n, avgMinDay, avgUnlocksDay),
        ),

        // ── 30-day trend chart ───────────────────────────────────────────────
        _analysisCard(
          context: context,
          icon: Icons.show_chart_outlined,
          title: l10n.block30dChartTitle,
          chartHeight: null,
          chart: dailyMs.isNotEmpty
              ? _UsageTrend30dWithLegend(
                  dailyMs: dailyMs,
                  appDailyMs: appDailyMs,
                  top3: top3,
                )
              : _noData(context, l10n.noData),
          text: l10n.block30dChartText,
        ),

        // ── Engagement balance (30d) ─────────────────────────────────────────
        _analysisCard(
          context: context,
          icon: Icons.balance_outlined,
          title: '${l10n.blockEngagementTitle} (30d)',
          chartHeight: 160,
          chart: (passiveMs + activeMs) > 0
              ? _DonutChart(passiveMs: passiveMs, activeMs: activeMs, l10n: l10n)
              : _noData(context, l10n.noData),
          text: _engagementText30d(l10n, passiveMs, totalMs),
        ),

      ],
    );
  }

  String _engagementText30d(AppLocalizations l10n, int passiveMs, int totalMs) {
    if (totalMs == 0) return l10n.blockEngagementNoData;
    final pct = (passiveMs / totalMs * 100).round();
    return l10n.blockEngagementText(pct);
  }
}

// ─── Chart widgets ────────────────────────────────────────────────────────────

class _HourlyBarChart extends StatelessWidget {
  const _HourlyBarChart({
    required this.values,
    this.highlightHours = const {},
    this.highlightColor,
    this.highlightHours2 = const {},
    this.highlightColor2,
    this.color,
  });
  final List<int> values;
  final Set<int> highlightHours;
  final Color? highlightColor;
  final Set<int> highlightHours2;
  final Color? highlightColor2;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Day starts at 04:00 — position i maps to actual hour (i + 4) % 24.
    // Labels at positions 0, 6, 12, 18 → "4h", "10h", "16h", "22h".
    final maxVal = values.fold(0, (a, b) => a > b ? a : b).toDouble();
    return BarChart(BarChartData(
      maxY: maxVal > 0 ? maxVal * 1.2 : 1,
      barGroups: List.generate(24, (i) {
        final h = (i + 4) % 24;
        final isHighlight  = highlightHours.contains(h);
        final isHighlight2 = highlightHours2.contains(h);
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: values[h].toDouble(),
            color: color ??
                (isHighlight  ? (highlightColor  ?? const Color(0xFFE65100)) // evening
                : isHighlight2 ? (highlightColor2 ?? const Color(0xFF4527A0)) // night
                : AppColors.primary.withAlpha(180)),
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ]);
      }),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18,
            getTitlesWidget: (v, _) {
              final pos = v.toInt();
              if (pos % 2 != 0) return const SizedBox.shrink();
              final h = (pos + 4) % 24;
              return Text(h.toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 8));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
    ));
  }
}

// ─── Yesterday pattern chart ──────────────────────────────────────────────────

// Static brand colors keyed by package name.
// Source: official brand guidelines / seekcolors.com / brandcolorcode.com
// Color uniqueness: pairs with CIE76 ΔE < 15 were adjusted — see _debugCheckColorConflicts().
// Adjustment axis order when resolving conflicts: H first, then S, then L.
// Run the app in debug mode to verify — conflicts are printed to the console.
const _kAppColors = <String, Color>{
  'com.whatsapp':                            Color(0xFF25D366), // WhatsApp green (no bg)
  'com.instagram.android':                   Color(0xFFFF80AB), // Instagram light-pink (brightened for white bg)
  'com.instagram.barcelona':                 Color(0xFF000000), // Threads — black icon
  'com.tinder':                              Color(0xFFFE3C72), // Tinder flame-pink (actual brand; white bg lightens slightly)
  'org.telegram.messenger':                  Color(0xFF2AABEE), // Telegram blue (no bg)
  'com.spotify.music':                       Color(0xFF168D3F), // Spotify darkened-green (black bg deepens perception)
  'com.google.android.apps.maps':            Color(0xFF009688), // Maps teal (shifted H: was #34A853 green, too close to WhatsApp/Spotify)
  'com.android.chrome':                      Color(0xFF4285F4), // Chrome blue
  'com.google.android.youtube':              Color(0xFFFF0000), // YouTube red
  'com.supercell.clashroyale':               Color(0xFF2B59C3), // Clash Royale blue
  'com.supercell.clashofclans':              Color(0xFFFBBC04), // Clash of Clans gold
  'com.bumble.app':                          Color(0xFFFFC629), // Bumble yellow
  'com.openai.chatgpt':                      Color(0xFF000000), // ChatGPT — black icon
  'com.nu.production':                       Color(0xFF8A05BE), // Nubank purple
  'com.studiosol.cifraclub':                 Color(0xFFFF6600), // CifraClub orange
  'com.google.android.keep':                 Color(0xFFFF7043), // Keep deep-orange (was #FBBC04, exact dup of Clash of Clans)
  'com.lucasf.apptime':                      Color(0xFF6366F1), // AppTime indigo
  'com.google.android.gm':                   Color(0xFFD44638), // Gmail red-orange
  'com.facebook.katana':                     Color(0xFF1877F2), // Facebook blue
  'com.miui.home':                           Color(0xFF78909C), // Launcher grey-blue
  'com.google.android.apps.messaging':       Color(0xFF1A73E8), // Messages blue
  'br.com.brainweb.ifood':                   Color(0xFFEA1D2C), // iFood red
  'com.android.deskclock':                   Color(0xFF607D8B), // Clock blue-grey
  'com.google.android.googlequicksearchbox': Color(0xFFDB4437), // Google red (was #4285F4, exact dup of Chrome)
  'com.google.android.apps.bard':            Color(0xFFF48FB1), // Gemini pink (shifted H: was #8E77FA violet, too close to AppTime/Stremio)
  'com.google.android.apps.docs':            Color(0xFF1565C0), // Docs dark-blue (was #1A73E8, exact dup of Messages)
  'com.ovelin.guitartuna':                   Color(0xFFAA00FF), // GuitarTuna deep-purple (shifted H: was #E91E63 pink, too close to Instagram)
  'com.stremio.one':                         Color(0xFF26C6DA), // Stremio cyan (shifted H: was #7B4FFF purple, too close to Nubank/AppTime)
  'br.com.bradseg.segurobradescosaude':      Color(0xFFCC092F), // Bradesco red
  'org.mozilla.firefox':                     Color(0xFFFF9500), // Firefox orange
};

Color _colorForApp(String pkg) =>
    _kAppColors[pkg] ?? const Color(0xFFB0BEC5);

String _labelForApp(String pkg) => labelForApp(pkg);

bool _isLauncher(String pkg) =>
    pkg == 'com.miui.home' ||
    pkg.contains('.launcher') ||
    pkg.endsWith('.home') ||
    pkg == 'com.android.systemui';

/// System / infrastructure packages that should be hidden from charts
/// and grouped into "outros". These are not real user-facing apps.
bool _isPseudoApp(String pkg) {
  const exact = {
    'com.google.android.gms',
    'com.android.vending',
    'com.google.android.providers.media.module',
    'com.android.settings',
    'com.miui.securitycenter',
    'com.android.permissioncontroller',
    'com.google.android.documentsui',
    'com.android.systemui',
    'com.miui.systemAdSolution',
    'com.android.packageinstaller',
    'com.google.android.packageinstaller',
  };
  if (exact.contains(pkg)) return true;
  return pkg.contains('photopicker') ||
      pkg.contains('permissioncontroller') ||
      pkg.contains('.provision') ||
      pkg.contains('.setup');
}

/// Returns a short label for a day string: weekday abbreviation + "DD/M".
/// E.g. "2026-04-14" → "ter 14/4"
String _sevenDayLabel(String dateStr) {
  const weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  try {
    final parts = dateStr.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final wd = weekdays[dt.weekday - 1]; // weekday: 1=Mon, 7=Sun
    return '$wd ${dt.day}/${dt.month}';
  } catch (_) {
    return dateStr.substring(5); // fallback: MM-DD
  }
}

// ── Color uniqueness helpers ─────────────────────────────────────────────────

/// CIE76 Delta E between two colors. 0 = identical, ~100 = maximum distance.
/// Pairs with ΔE < 15 are considered "too similar" for a stacked bar chart.
double _deltaE(Color a, Color b) {
  double lin(int c) {
    final f = c / 255.0;
    return f <= 0.04045 ? f / 12.92 : math.pow((f + 0.055) / 1.055, 2.4).toDouble();
  }

  List<double> toLab(Color c) {
    final r = lin((c.r * 255).round()), g = lin((c.g * 255).round()), bl = lin((c.b * 255).round());
    final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * bl) / 0.95047;
    final y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * bl) / 1.00000;
    final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * bl) / 1.08883;
    double f(double t) =>
        t > 0.008856 ? math.pow(t, 1 / 3.0).toDouble() : 7.787 * t + 16 / 116;
    final fx = f(x), fy = f(y), fz = f(z);
    return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
  }

  final la = toLab(a), lb = toLab(b);
  return math.sqrt(
    math.pow(la[0] - lb[0], 2) +
    math.pow(la[1] - lb[1], 2) +
    math.pow(la[2] - lb[2], 2),
  );
}

/// In debug builds, prints any pairs in _kAppColors with ΔE < 15.
/// Call this whenever _kAppColors is modified.
void _debugCheckColorConflicts() {
  assert(() {
    const minDeltaE = 15.0;
    final entries = _kAppColors.entries.toList();
    var found = false;
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final de = _deltaE(entries[i].value, entries[j].value);
        if (de < minDeltaE) {
          debugPrint(
            'AppColors conflict: ${labelForApp(entries[i].key)}'
            ' ↔ ${labelForApp(entries[j].key)}'
            ' ΔE=${de.toStringAsFixed(1)} (< $minDeltaE)',
          );
          found = true;
        }
      }
    }
    if (!found) debugPrint('AppColors: all pairs ΔE ≥ $minDeltaE ✓');
    return true;
  }());
}

class _YesterdayPatternChart extends StatelessWidget {
  const _YesterdayPatternChart({
    required this.appHourly,
    required this.l10n,
    this.disabledApps = const {},
  });

  final Map<String, List<int>> appHourly;
  final AppLocalizations l10n;
  final Set<String> disabledApps;

  static const double _rowHeight = 15.0; // 18 × 0.85 ≈ 15
  static const double _labelWidth = 30.0;
  static const double _barHeight = 9.0;  // 10 × 0.85 ≈ 9
  static const int _hourMs = 60 * 60 * 1000;
  static const int _topN = 7;
  static bool _colorConflictsChecked = false;

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (!_colorConflictsChecked) {
        _colorConflictsChecked = true;
        _debugCheckColorConflicts();
      }
      return true;
    }());

    if (appHourly.isEmpty) {
      return Center(
        child: Text(l10n.collectingData,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
      );
    }

    int toFlex(int ms) => (ms ~/ 1000).clamp(1, 3600);

    // Thin separator between adjacent colored segments.
    final sep = Container(width: 1.5, color: const Color(0x99000000));

    // Top-7 apps by DAILY total (not per-hour), excluding launchers, pseudoapps,
    // and unmonitored apps. Unmonitored apps remain in `total` so their time
    // still appears in the "outros" bucket.
    final dailyTotals = <String, int>{
      for (final e in appHourly.entries)
        if (!_isLauncher(e.key) && !_isPseudoApp(e.key) &&
            !disabledApps.contains(e.key))
          e.key: e.value.fold(0, (s, v) => s + v),
    };
    final topApps = (dailyTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(_topN)
        .map((e) => e.key)
        .toList();

    // Legend = daily top-7 apps
    final legendApps = topApps;

    // Build one row per hour, all 24, in 4am-first order
    final rows = <Widget>[];
    for (int i = 0; i < 24; i++) {
      final h = (i + 4) % 24;
      final total = appHourly.values.fold(0, (s, e) => s + e[h]);
      final topNMs = topApps.fold<int>(0, (s, p) => s + (appHourly[p]?[h] ?? 0));
      final outrosMs = total - topNMs; // launchers + pseudoapps + non-top apps

      // Build segments with separators between each adjacent pair
      final segments = <Widget>[];
      for (final pkg in topApps) {
        final ms = appHourly[pkg]![h];
        if (ms > 0) {
          if (segments.isNotEmpty) segments.add(sep);
          segments.add(Flexible(
            flex: toFlex(ms),
            child: Container(color: _colorForApp(pkg)),
          ));
        }
      }
      if (outrosMs > 0) {
        if (segments.isNotEmpty) segments.add(sep);
        segments.add(Flexible(
          flex: toFlex(outrosMs),
          child: Container(color: const Color(0xFFB0BEC5)),
        ));
      }
      // Unused fraction of the hour (no separator — transparent)
      if (total < _hourMs) {
        segments.add(Flexible(
          flex: toFlex(_hourMs - total),
          child: const SizedBox.shrink(),
        ));
      }

      rows.add(SizedBox(
        height: _rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _labelWidth,
              child: Text('${h}h',
                  style: TextStyle(
                      fontSize: 9,
                      color: total > 0
                          ? const Color(0xFF757575)
                          : const Color(0xFFBDBDBD))),
            ),
            Expanded(
              child: total == 0
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: _barHeight,
                        child: Row(children: segments),
                      ),
                    ),
            ),
          ],
        ),
      ));
    }

    // Legend: all apps that appeared in any hour's top N + always show "outros"
    final legendItems = [
      for (final pkg in legendApps)
        _LegendDot(color: _colorForApp(pkg), label: _labelForApp(pkg)),
      _LegendDot(color: const Color(0xFFB0BEC5), label: l10n.yesterdayPatternOther),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(spacing: 10, runSpacing: 4, children: legendItems),
        const SizedBox(height: 8),
        ...rows,
        const SizedBox(height: 2),
        Row(
          children: [
            const SizedBox(width: _labelWidth),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['0', '15m', '30m', '45m', '1h']
                    .map((t) => Text(t,
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF757575))))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10)),
        ],
      );
}

// ─── Last 7 days hourly pattern chart (horizontal bars, same style as yesterday) ─

class _LastDaysPatternChart extends StatefulWidget {
  const _LastDaysPatternChart({
    required this.daysData,
    required this.l10n,
    this.disabledApps = const {},
  });
  // daysData: list of (dateStr "YYYY-MM-DD", appHourly) oldest→newest
  final List<(String, Map<String, List<int>>)> daysData;
  final AppLocalizations l10n;
  final Set<String> disabledApps;

  @override
  State<_LastDaysPatternChart> createState() => _LastDaysPatternChartState();
}

class _LastDaysPatternChartState extends State<_LastDaysPatternChart> {
  bool _zoomedOut = false;
  late final ScrollController _scroll;

  // Same dimensions as _YesterdayPatternChart
  static const double _rowH    = 15.0;
  static const double _barH    =  9.0;
  static const double _labelW  = 44.0; // wider to fit "ter 14/4"
  static const int    _topN    =  4;
  static const int    _hourMs  = 60 * 60 * 1000;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    // Jump to rightmost (most recent) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Top [_topN] apps by DAILY total for a day, launchers + pseudoapps +
  /// unmonitored apps excluded. Their time stays in `total` → "outros".
  List<String> _dayTopN(Map<String, List<int>> hourly) {
    final totals = <String, int>{
      for (final e in hourly.entries)
        if (!_isLauncher(e.key) && !_isPseudoApp(e.key) &&
            !widget.disabledApps.contains(e.key))
          e.key: e.value.fold(0, (s, v) => s + v),
    };
    return (totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(_topN)
        .map((e) => e.key)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.daysData.any((d) => d.$2.isNotEmpty);
    if (!hasData) {
      return Center(
        child: Text(widget.l10n.collectingData,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
      );
    }

    // Visible days: zoomed-in = 2.5 days, zoomed-out = all 7
    final nDays   = widget.daysData.length;
    final screenW = MediaQuery.of(context).size.width - 2 * AppSpacing.md - 32;
    // Each day column width (the bar area, excluding the fixed hour-label column)
    final dayW = _zoomedOut
        ? ((screenW - _labelW) / nDays).clamp(40.0, 120.0)
        : ((screenW - _labelW) / 2.5).clamp(60.0, 140.0);
    final totalW = nDays * dayW + (nDays - 1); // +1px per day separator

    // Thin separator
    final sep = Container(width: 1.5, color: const Color(0x99000000));

    // Pre-compute top-N apps per day
    final dayTopApps = [
      for (final (_, hourly) in widget.daysData) _dayTopN(hourly),
    ];

    // Legend = union of all top-N apps across all days
    final legendApps = <String>{
      for (final list in dayTopApps) ...list,
    }.toList();

    int toFlex(int ms) => (ms ~/ 1000).clamp(1, 3600);

    // Build 24 rows (hours), 4am-first
    final rows = <Widget>[];
    for (int i = 0; i < 24; i++) {
      final h = (i + 4) % 24;

      // One segment row per day for this hour
      final dayCells = <Widget>[];
      for (int di = 0; di < nDays; di++) {
        final hourly = widget.daysData[di].$2;
        final topApps = dayTopApps[di];
        final total   = hourly.values.fold(0, (s, e) => s + e[h]);
        final topNMs  = topApps.fold<int>(0, (s, p) => s + (hourly[p]?[h] ?? 0));
        final outrosMs = total - topNMs;

        if (di > 0) {
          // Thin day-separator — use a different opacity so it reads as a break
          dayCells.add(Container(width: 1, color: const Color(0x44FFFFFF)));
        }

        if (total == 0) {
          dayCells.add(SizedBox(width: dayW));
          continue;
        }

        final segments = <Widget>[];
        for (final pkg in topApps) {
          final ms = hourly[pkg]?[h] ?? 0;
          if (ms > 0) {
            if (segments.isNotEmpty) segments.add(sep);
            segments.add(Flexible(
              flex: toFlex(ms),
              child: Container(color: _colorForApp(pkg)),
            ));
          }
        }
        if (outrosMs > 0) {
          if (segments.isNotEmpty) segments.add(sep);
          segments.add(Flexible(
            flex: toFlex(outrosMs),
            child: Container(color: const Color(0xFFB0BEC5)),
          ));
        }
        if (total < _hourMs) {
          segments.add(Flexible(
            flex: toFlex(_hourMs - total),
            child: const SizedBox.shrink(),
          ));
        }

        dayCells.add(SizedBox(
          width: dayW,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: _barH,
              child: Row(children: segments),
            ),
          ),
        ));
      }

      rows.add(SizedBox(
        height: _rowH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: dayCells,
        ),
      ));
    }

    // Hour axis labels (fixed left column)
    final hourLabels = <Widget>[
      for (int i = 0; i < 24; i++)
        SizedBox(
          height: _rowH,
          width: _labelW,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${(i + 4) % 24}h',
                style: const TextStyle(fontSize: 9, color: Color(0xFF757575))),
          ),
        ),
    ];

    // Day labels (scrollable, same width as day columns)
    final dayLabels = [
      for (final (dateStr, _) in widget.daysData)
        SizedBox(
          width: dayW,
          child: Text(
            _sevenDayLabel(dateStr),
            style: const TextStyle(fontSize: 8, color: Color(0xFF9E9E9E)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zoom toggle
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _zoomedOut = !_zoomedOut),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_zoomedOut ? Icons.zoom_in : Icons.zoom_out_map, size: 20,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text(_zoomedOut ? '2.5d' : '7d',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.outline)),
              ]),
            ),
          ),
        ),
        // Chart: fixed hour labels + scrollable day columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed left: hour labels
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: hourLabels),
            // Scrollable right: stacked bar columns
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...rows,
                      const SizedBox(height: 2),
                      // Time axis (0 → 1h) per day column
                      Row(
                        children: [
                          for (int di = 0; di < nDays; di++) ...[
                            if (di > 0) const SizedBox(width: 1),
                            SizedBox(
                              width: dayW,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: ['0', '30m', '1h']
                                    .map((t) => Text(t,
                                        style: const TextStyle(
                                            fontSize: 7,
                                            color: Color(0xFF9E9E9E))))
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Day labels below bars
                      Row(children: dayLabels),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final pkg in legendApps)
            _LegendDot(color: _colorForApp(pkg), label: _labelForApp(pkg)),
          _LegendDot(
              color: const Color(0xFFB0BEC5),
              label: widget.l10n.yesterdayPatternOther),
        ]),
      ],
    );
  }
}

// ─── Session histogram ────────────────────────────────────────────────────────

class _SessionHistogram extends StatelessWidget {
  const _SessionHistogram({required this.buckets});
  final List<int> buckets;

  static const _labels = ['<1min', '1-5m', '5-15m', '>15m'];

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.fold(0, (a, b) => a > b ? a : b).toDouble();
    return BarChart(BarChartData(
      maxY: maxVal > 0 ? maxVal * 1.2 : 1,
      barGroups: List.generate(4, (i) {
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: buckets[i].toDouble(),
            color: i == 0 ? AppColors.error : AppColors.primary,
            width: 36,
            borderRadius: BorderRadius.circular(4),
          ),
        ]);
      }),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18,
            getTitlesWidget: (v, _) => Text(
              _labels[v.toInt()],
              style: const TextStyle(fontSize: 9),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
    ));
  }
}

class _OpportunityCostWidget extends StatelessWidget {
  const _OpportunityCostWidget({required this.totalMs, required this.l10n});
  final int totalMs;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hours = totalMs / 3_600_000;
    final pages = (hours * 30).round();
    final km = (hours * 5).round();
    final sleepCycles = (hours / 1.5).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CostItem(icon: Icons.menu_book_outlined, label: l10n.pagesLabel(pages)),
        _CostItem(icon: Icons.directions_walk_outlined, label: l10n.kmLabel(km)),
        _CostItem(icon: Icons.airline_seat_flat_outlined, label: l10n.sleepCyclesLabel(sleepCycles)),
      ],
    );
  }
}

class _CostItem extends StatelessWidget {
  const _CostItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.success),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _HorizontalAppBars extends StatelessWidget {
  const _HorizontalAppBars({required this.apps, required this.maxOpens});
  final List<_AppAgg> apps;
  final int maxOpens;

  // Research-based thresholds (opens per 7-day period).
  // Rosen et al. (2013): frequent checkers average 40-60 phone checks/day.
  // Greenfield (2020, Center for Internet & Technology Addiction):
  //   >20 opens/day of a single app = compulsive checking pattern.
  // Warning  ~5 opens/day x7 = 35  (noticeable habitual use)
  // Alert   ~10 opens/day x7 = 70  (compulsive threshold, Greenfield 2020)
  static const int _warnOpens = 35;
  static const int _alertOpens = 70;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: apps.map((a) {
        final fraction = maxOpens > 0 ? a.opens / maxOpens : 0.0;
        final warnF  = maxOpens > 0 ? _warnOpens  / maxOpens : 2.0;
        final alertF = maxOpens > 0 ? _alertOpens / maxOpens : 2.0;
        final barColor = a.opens >= _alertOpens
            ? AppColors.error
            : a.opens >= _warnOpens
                ? Colors.orange
                : AppColors.primary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(
              width: 80,
              child: Text(_labelForApp(a.packageName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LayoutBuilder(builder: (ctx, constraints) {
                final maxW = constraints.maxWidth;
                return SizedBox(
                  height: 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      if (warnF <= 1.0)
                        Positioned(
                          left: (warnF * maxW - 0.75).clamp(0.0, maxW - 1.5),
                          top: -3, bottom: -3,
                          child: Container(width: 1.5,
                              color: Colors.orange.withValues(alpha: 0.85)),
                        ),
                      if (alertF <= 1.0)
                        Positioned(
                          left: (alertF * maxW - 0.75).clamp(0.0, maxW - 1.5),
                          top: -3, bottom: -3,
                          child: Container(width: 1.5,
                              color: AppColors.error.withValues(alpha: 0.85)),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            Text('${a.opens}x', style: Theme.of(context).textTheme.bodySmall),
          ]),
        );
      }).toList()
        ..add(
          // Threshold legend + scientific note
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 12, height: 2,
                      color: Colors.orange.withValues(alpha: 0.85)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    '35×/semana — uso habitual · Rosen et al. (2013), "iDisorder", Computers in Human Behavior',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic),
                  )),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Container(width: 12, height: 2,
                      color: AppColors.error.withValues(alpha: 0.85)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    '70×/semana — padrão compulsivo · Greenfield (2020), Center for Internet & Technology Addiction, "Compulsive Technology Use"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: AppColors.error,
                        fontStyle: FontStyle.italic),
                  )),
                ]),
              ],
            ),
          ),
        ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.passiveMs,
    required this.activeMs,
    required this.l10n,
  });
  final int passiveMs;
  final int activeMs;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 110,
        child: PieChart(PieChartData(
          centerSpaceRadius: 28,
          sectionsSpace: 2,
          sections: [
            PieChartSectionData(
              value: passiveMs.toDouble(),
              color: AppColors.error,
              title: '',
              radius: 38,
            ),
            PieChartSectionData(
              value: activeMs.toDouble(),
              color: AppColors.success,
              title: '',
              radius: 38,
            ),
          ],
        )),
      ),
      const SizedBox(width: AppSpacing.lg),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Legend(color: AppColors.error, label: '${l10n.passive} (${_fmtDuration(passiveMs)})'),
            const SizedBox(height: 10),
            _Legend(color: AppColors.success, label: '${l10n.active} (${_fmtDuration(activeMs)})'),
            const SizedBox(height: 12),
            Text(
              l10n.blockEngagementClassification,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({
    required this.thisWeek,
    required this.dates,
    required this.prevAvgMs,
    required this.prevWeekLabel,
  });
  final List<int> thisWeek;
  final List<String> dates; // "YYYY-MM-DD", oldest first, same order as thisWeek
  final int prevAvgMs;
  final String prevWeekLabel;

  @override
  Widget build(BuildContext context) {
    // Convert to hours — toY values are in hours, maxY must match.
    final maxValH =
        [...thisWeek, prevAvgMs].fold(0, (a, b) => a > b ? a : b) / 3_600_000;
    // Y-axis interval: round up to nearest 0.5h, minimum 0.5
    final interval = maxValH <= 0 ? 1.0
        : maxValH <= 2 ? 0.5
        : maxValH <= 6 ? 1.0
        : 2.0;

    return BarChart(BarChartData(
      maxY: maxValH > 0 ? maxValH * 1.2 : 1,
      barGroups: thisWeek.asMap().entries.map((e) {
        final hours = e.value / 3_600_000;
        return BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(
            toY: hours,
            color: e.value > prevAvgMs ? AppColors.error : AppColors.success,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ]);
      }).toList(),
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: prevAvgMs / 3_600_000,
          color: AppColors.primary.withAlpha(180),
          strokeWidth: 1.5,
          dashArray: [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            labelResolver: (_) => prevWeekLabel,
            style: TextStyle(
                fontSize: 9,
                color: AppColors.primary.withAlpha(180)),
          ),
        ),
      ]),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: interval,
            getTitlesWidget: (v, _) {
              if (v == 0) return const SizedBox.shrink();
              final label = v == v.truncateToDouble()
                  ? '${v.toInt()}h'
                  : '${(v * 60).round()}m';
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(label,
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.right),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= dates.length) return const SizedBox.shrink();
              // Show "seg", "ter", etc. from the full weekday label
              final full = _sevenDayLabel(dates[i]); // e.g. "ter 14/4"
              final parts = full.split(' ');
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(parts[0], // weekday abbrev
                        style: const TextStyle(fontSize: 8)),
                    if (parts.length > 1)
                      Text(parts[1], // "14/4"
                          style: const TextStyle(fontSize: 7,
                              color: Color(0xFF9E9E9E))),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: Color(0x22FFFFFF),
          strokeWidth: 0.5,
        ),
      ),
    ));
  }
}

// ─── 30-day summary widget ────────────────────────────────────────────────────

class _Summary30dWidget extends StatelessWidget {
  const _Summary30dWidget({
    required this.avgMinDay,
    required this.avgUnlocksDay,
    required this.totalMs,
    required this.totalUnlocks,
    required this.nDays,
    required this.l10n,
  });
  final int avgMinDay, avgUnlocksDay, totalMs, totalUnlocks, nDays;
  final AppLocalizations l10n;

  static const _timeLabels = ['< 1h/dia', '1–2h/dia', '2–4h/dia', '4–6h/dia', '> 6h/dia'];
  static const _timeColors = [
    Color(0xFF43A047), Color(0xFF7CB342), Color(0xFFFB8C00),
    Color(0xFFE53935), Color(0xFFB71C1C),
  ];
  static const _unlockLabels = ['< 30/dia', '30–60/dia', '60–100/dia', '> 100/dia'];
  static const _unlockColors = [
    Color(0xFF43A047), Color(0xFFFB8C00), Color(0xFFE53935), Color(0xFFB71C1C),
  ];

  int get _tI => avgMinDay < 60 ? 0 : avgMinDay < 120 ? 1 : avgMinDay < 240 ? 2 : avgMinDay < 360 ? 3 : 4;
  int get _uI => avgUnlocksDay < 30 ? 0 : avgUnlocksDay < 60 ? 1 : avgUnlocksDay < 100 ? 2 : 3;

  @override
  Widget build(BuildContext context) {
    final tColor = _timeColors[_tI];
    final uColor = _unlockColors[_uI];
    final ts = Theme.of(context).textTheme;
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_fmtDuration(totalMs ~/ nDays),
            style: ts.titleMedium?.copyWith(color: tColor, fontWeight: FontWeight.w700)),
        Text('${l10n.statTotalUsage} /${l10n.locale.languageCode == 'pt' ? 'dia' : 'day'}', style: ts.bodySmall),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: tColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4)),
          child: Text(_timeLabels[_tI],
              style: ts.bodySmall?.copyWith(color: tColor, fontSize: 9)),
        ),
      ])),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${(totalUnlocks / nDays).round()}',
            style: ts.titleMedium?.copyWith(color: uColor, fontWeight: FontWeight.w700)),
        Text('${l10n.statUnlocks} /${l10n.locale.languageCode == 'pt' ? 'dia' : 'day'}', style: ts.bodySmall),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: uColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4)),
          child: Text(_unlockLabels[_uI],
              style: ts.bodySmall?.copyWith(color: uColor, fontSize: 9)),
        ),
      ])),
    ]);
  }
}

// ─── Classification message (5 time tiers × 4 unlock tiers) ──────────────────
// Time tiers:    T0 <60min  T1 60–120  T2 120–240  T3 240–360  T4 >360
// Unlock tiers:  U0 <30/d   U1 30–60   U2 60–100   U3 >100
// Research: Twenge et al. (2018), Rosen et al. (2013), Billieux et al. (2015),
//           Mark et al. (2008), Przybylski & Weinstein (2017).

String _classificationMessage(AppLocalizations l10n, int avgMinDay, int avgUnlocksDay) {
  final tI = avgMinDay < 60 ? 0 : avgMinDay < 120 ? 1 : avgMinDay < 240 ? 2 : avgMinDay < 360 ? 3 : 4;
  final uI = avgUnlocksDay < 30 ? 0 : avgUnlocksDay < 60 ? 1 : avgUnlocksDay < 100 ? 2 : 3;
  final pt = l10n.locale.languageCode == 'pt';
  final m = avgMinDay, u = avgUnlocksDay;
  final hh = (m / 60).toStringAsFixed(1);

  final msgs = <List<String Function(int m, int u, String h)>>[
    // T0 — < 60 min/day
    [
      (m, u, h) => pt
          ? 'Uso muito baixo ($m min/dia) e poucos desbloqueios ($u/dia). Você está bem abaixo dos limites saudáveis. Mantenha esse padrão.'
          : 'Very low usage ($m min/day) with few unlocks ($u/day). Well below healthy limits. Keep it up.',
      (m, u, h) => pt
          ? 'Tempo de tela baixo ($m min/dia), mas $u desbloqueios diários indicam checagem frequente. A frequência de checagem prediz ansiedade mesmo com tempo total baixo (Rosen et al., 2013). Agrupe suas verificações em blocos de tempo.'
          : 'Low screen time ($m min/day), but $u daily unlocks signal frequent checking. Check frequency predicts anxiety even at low total time (Rosen et al., 2013). Try batching checks.',
      (m, u, h) => pt
          ? 'Pouco tempo de tela ($m min/dia), mas $u desbloqueios é acima do esperado. Cada desbloqueio fragmenta o foco. Desative notificações não essenciais.'
          : 'Low screen time ($m min/day) but $u unlocks is above expected. Each unlock fragments focus. Disable non-essential notifications.',
      (m, u, h) => pt
          ? 'Você abre o celular $u vezes/dia usando-o pouco. Checagem compulsiva sem uso prolongado está associada a ciclos de ansiedade (Billieux et al., 2015). Pratique adiamento de impulso: espere 5 minutos antes de pegar o celular.'
          : 'You unlock $u times/day despite low total usage. Compulsive checking without prolonged use is linked to anxiety cycles (Billieux et al., 2015). Practice impulse delay — wait 5 minutes before reaching for your phone.',
    ],
    // T1 — 60–120 min/day
    [
      (m, u, h) => pt
          ? 'Uso equilibrado ($m min/dia) dentro da faixa recomendada por especialistas (até 120 min) e apenas $u desbloqueios. Continue assim.'
          : 'Balanced usage ($m min/day) within the expert-recommended range (up to 120 min) and just $u unlocks. Well done.',
      (m, u, h) => pt
          ? 'Uso moderado ($m min/dia) com frequência de desbloqueio normal ($u/dia). Você está na zona de equilíbrio. Monitore para que não aumente.'
          : 'Moderate usage ($m min/day) with normal unlock frequency ($u/day). You are in the balance zone. Keep monitoring.',
      (m, u, h) => pt
          ? 'Tempo de tela aceitável ($m min/dia), mas $u desbloqueios fragmentam a atenção. Recuperar o foco após uma interrupção leva em média 23 min (Mark et al., 2008). Agrupe verificações no começo e fim do dia.'
          : 'Acceptable screen time ($m min/day), but $u unlocks fragment attention. Recovering focus after an interruption takes ~23 min on average (Mark et al., 2008). Batch checks to morning and evening.',
      (m, u, h) => pt
          ? 'Tempo total razoável ($m min/dia), mas $u desbloqueios/dia é um padrão compulsivo. Isso prediz baixa qualidade de sono (Levenson et al., 2016). Estabeleça horários sem celular e desative notificações à noite.'
          : 'Reasonable total time ($m min/day), but $u unlocks/day is a compulsive pattern. This predicts poor sleep quality (Levenson et al., 2016). Set phone-free hours and silence notifications at night.',
    ],
    // T2 — 120–240 min/day
    [
      (m, u, h) => pt
          ? 'Acima do recomendado ($m min/dia; referência: 120 min para adultos). Os poucos desbloqueios ($u/dia) sugerem sessões longas. Defina um limite diário e use o modo foco.'
          : 'Above recommended ($m min/day; reference: 120 min for adults). Low unlock count ($u/day) suggests long sessions. Set a daily limit and use focus mode.',
      (m, u, h) => pt
          ? 'Com $m min/dia e $u desbloqueios, você está acima dos limites associados a bem-estar digital (Przybylski & Weinstein, 2017). Reduza as notificações para diminuir interrupções passivas.'
          : 'At $m min/day and $u unlocks, you exceed limits linked to digital wellbeing (Przybylski & Weinstein, 2017). Reduce notifications to lower passive interruptions.',
      (m, u, h) => pt
          ? 'Uso preocupante: $m min/dia ($hh h) com $u desbloqueios. Acima de 2h/dia há redução mensurável no bem-estar subjetivo de adultos (Twenge et al., 2018). Comece desativando notificações de redes sociais.'
          : 'Concerning usage: $m min/day ($hh h) with $u unlocks. Above 2h/day there is measurable decline in adult subjective wellbeing (Twenge et al., 2018). Start by turning off social media notifications.',
      (m, u, h) => pt
          ? 'Alto tempo ($m min/dia) e uso compulsivo ($u desbloqueios). Esse perfil é consistente com dependência de smartphone (Billieux et al., 2015). Aplique regras de distância física — especialmente no quarto à noite.'
          : 'High time ($m min/day) and compulsive use ($u unlocks). This profile is consistent with smartphone dependency (Billieux et al., 2015). Apply physical distance rules — especially in the bedroom at night.',
    ],
    // T3 — 240–360 min/day
    [
      (m, u, h) => pt
          ? 'Uso elevado ($m min/dia ≈ $hh h), concentrado em sessões longas ($u desbloqueios). Sessões prolongadas de consumo passivo estão ligadas a ruminação e humor deprimido (Verduyn et al., 2015). Faça pausas ativas a cada 30 minutos.'
          : 'High usage ($m min/day ≈ $hh h) in long sessions ($u unlocks). Prolonged passive consumption is linked to rumination and depressed mood (Verduyn et al., 2015). Take active breaks every 30 minutes.',
      (m, u, h) => pt
          ? 'Quase $hh h de tela por dia ($u desbloqueios). Esse nível está associado a redução na qualidade de sono e atenção sustentada. Reserve a primeira e a última hora do dia sem celular.'
          : 'Nearly $hh h of screen time per day ($u unlocks). This level is linked to reduced sleep quality and sustained attention. Reserve the first and last hour of your day phone-free.',
      (m, u, h) => pt
          ? 'Alto tempo ($m min/dia) combinado com $u desbloqueios: padrão fragmentado e excessivo. Cada interrupção cria um pico de dopamina que reforça o hábito (Schultz, 2015). Tente uma semana sem redes sociais para quebrar o ciclo.'
          : 'High time ($m min/day) combined with $u unlocks: a fragmented and excessive pattern. Each interrupt creates a dopamine spike that reinforces the habit (Schultz, 2015). Try a week without social media to break the cycle.',
      (m, u, h) => pt
          ? 'Uso muito alto: $m min/dia ($hh h) com $u desbloqueios. Esse perfil está fortemente associado a ansiedade, isolamento social e baixo desempenho. Considere ferramentas de bloqueio de apps e apoio especializado.'
          : 'Very high usage: $m min/day ($hh h) with $u unlocks. This profile is strongly linked to anxiety, social isolation, and poor performance. Consider app-blocking tools and professional support.',
    ],
    // T4 — > 360 min/day
    [
      (m, u, h) => pt
          ? 'Acima de 6h/dia ($m min). Mesmo em sessões longas, esse nível supera amplamente os limites saudáveis. Há evidências de redução de massa cinzenta no córtex pré-frontal com uso crônico excessivo (He et al., 2017). Consulte um especialista em saúde digital.'
          : 'Above 6h/day ($m min). Even in long sessions, this far exceeds healthy limits. There is evidence of grey matter reduction in the prefrontal cortex with chronic excessive use (He et al., 2017). Seek a digital health specialist.',
      (m, u, h) => pt
          ? 'Uso severo: $m min/dia ($hh h). Twenge et al. (2018) identificaram declínios claros de bem-estar acima de 5h diárias. Reduza imediatamente pelo menos 30 min/dia e estabeleça zonas livres de celular em casa.'
          : 'Severe usage: $m min/day ($hh h). Twenge et al. (2018) found clear wellbeing declines above 5h/day. Immediately cut at least 30 min/day and establish phone-free zones at home.',
      (m, u, h) => pt
          ? 'Uso severo ($m min/dia, $hh h) com alta frequência ($u desbloqueios). A combinação de alto tempo e alta frequência é o perfil de maior risco para saúde mental em estudos longitudinais. Priorize uma estratégia de redução estruturada.'
          : 'Severe usage ($m min/day, $hh h) with high frequency ($u unlocks). The combination of high time and high frequency is the highest-risk mental health profile in longitudinal studies. Prioritize a structured reduction strategy.',
      (m, u, h) => pt
          ? 'Uso extremo: $m min/dia ($hh h) com $u desbloqueios. Esse padrão compromete sono, foco, relacionamentos e saúde mental. Busque apoio profissional — a mudança de hábito nesse nível raramente ocorre sem estrutura externa.'
          : 'Extreme usage: $m min/day ($hh h) with $u unlocks. This pattern impairs sleep, focus, relationships, and mental health. Seek professional support — habit change at this level rarely happens without external structure.',
    ],
  ];

  return msgs[tI][uI](m, u, hh);
}

// ─── 30-day usage trend chart ──────────────────────────────────────────────────

class _UsageTrend30d extends StatelessWidget {
  const _UsageTrend30d({
    required this.dailyMs,
    required this.appDailyMs,
    required this.top3,
  });
  final List<int> dailyMs;
  final Map<String, List<int>> appDailyMs;
  final List<String> top3;

  static const double _idealH = 2.0;   // APA/Common Sense Media: ≤2h for adults
  static const double _criticalH = 4.0; // Twenge et al. (2018): wellbeing decline >4h

  List<FlSpot> _spots(List<int> ms) => ms.asMap().entries
      .map((e) => FlSpot(e.key.toDouble(), e.value / 3_600_000))
      .toList();

  List<FlSpot> _trendSpots(List<int> ms) {
    final ys = ms.map((v) => v / 3_600_000).toList();
    final n = ys.length;
    if (n < 2) return [];
    final xMean = (n - 1) / 2.0;
    final yMean = ys.fold(0.0, (s, v) => s + v) / n;
    double num = 0, den = 0;
    for (int i = 0; i < n; i++) {
      num += (i - xMean) * (ys[i] - yMean);
      den += (i - xMean) * (i - xMean);
    }
    final slope = den != 0 ? num / den : 0;
    final intercept = yMean - slope * xMean;
    return [
      FlSpot(0, (intercept).clamp(0.0, 24.0)),
      FlSpot((n - 1).toDouble(), (intercept + slope * (n - 1)).clamp(0.0, 24.0)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final n = dailyMs.length;
    final maxH = dailyMs.fold(0, (a, b) => a > b ? a : b) / 3_600_000;
    final maxY = math.max(maxH * 1.15, _criticalH + 0.5);
    final trendSpots = _trendSpots(dailyMs);
    final outline = Theme.of(context).colorScheme.outline;

    return LineChart(LineChartData(
      minX: 0,
      maxX: (n - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),
      lineBarsData: [
        // App lines (thin, colored)
        for (final pkg in top3)
          LineChartBarData(
            spots: _spots(appDailyMs[pkg] ?? []),
            isCurved: true,
            curveSmoothness: 0.35,
            color: _colorForApp(pkg),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        // Total line (thick, white/primary)
        LineChartBarData(
          spots: _spots(dailyMs),
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.white,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        // Trend line (thin dashed, grey)
        if (trendSpots.length == 2)
          LineChartBarData(
            spots: trendSpots,
            isCurved: false,
            color: outline.withValues(alpha: 0.7),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [6, 4],
            belowBarData: BarAreaData(show: false),
          ),
      ],
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: _idealH,
          color: const Color(0xFF43A047).withValues(alpha: 0.7),
          strokeWidth: 1,
          dashArray: [5, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            labelResolver: (_) => '2h ideal',
            style: const TextStyle(fontSize: 8, color: Color(0xFF43A047)),
          ),
        ),
        HorizontalLine(
          y: _criticalH,
          color: const Color(0xFFE53935).withValues(alpha: 0.7),
          strokeWidth: 1,
          dashArray: [5, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            labelResolver: (_) => '4h crítico',
            style: const TextStyle(fontSize: 8, color: Color(0xFFE53935)),
          ),
        ),
      ]),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (v, _) {
              if (v == 0 || v != v.roundToDouble()) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text('${v.toInt()}h',
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.right),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18,
            interval: 7,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i % 7 != 0) return const SizedBox.shrink();
              final dt = _dayAnchor(DateTime.now())
                  .subtract(Duration(days: (n - 1 - i)));
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${dt.day}/${dt.month}',
                    style: const TextStyle(fontSize: 8, color: Color(0xFF9E9E9E))),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: Color(0x18FFFFFF),
          strokeWidth: 0.5,
        ),
      ),
    ));
  }
}


// ─── 30-day trend chart + legend ─────────────────────────────────────────────

class _UsageTrend30dWithLegend extends StatelessWidget {
  const _UsageTrend30dWithLegend({
    required this.dailyMs,
    required this.appDailyMs,
    required this.top3,
  });
  final List<int> dailyMs;
  final Map<String, List<int>> appDailyMs;
  final List<String> top3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: _UsageTrend30d(
            dailyMs: dailyMs,
            appDailyMs: appDailyMs,
            top3: top3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: [
          _LegendDot(color: Colors.white, label: 'Total'),
          for (final pkg in top3)
            _LegendDot(color: _colorForApp(pkg), label: _labelForApp(pkg)),
        ]),
      ],
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _AppAgg {
  _AppAgg(this.packageName);
  final String packageName;
  int ms = 0;
  int opens = 0;
}
