import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/background_service.dart';
import '../theme/app_theme.dart';

// Insights data embedded here for the home screen card
class _InsightEntry {
  final IconData icon;
  final String title;
  final String summary;
  final String detail;
  const _InsightEntry({required this.icon, required this.title, required this.summary, required this.detail});
}

const List<_InsightEntry> _allInsights = [
  _InsightEntry(
    icon: Icons.timer_rounded,
    title: "A regra dos 23 minutos",
    summary: "Após cada interrupção, o cérebro leva em média 23 minutos para retornar ao nível de concentração anterior.",
    detail: "Pesquisadores da UC Irvine estudaram trabalhadores em seus ambientes naturais e descobriram que cada notificação reinicia o ciclo de atenção profunda do zero.\n\nFonte: Gloria Mark, UC Irvine (2008).",
  ),
  _InsightEntry(
    icon: Icons.brightness_4_rounded,
    title: "Luz azul e o relógio biológico",
    summary: "A luz emitida por telas suprime a melatonina, atrasando o sono em até 1,5 hora.",
    detail: "Estudos do Brigham and Women's Hospital mostram que leitores de e-readers levam mais tempo para adormecer e têm menos sono REM do que leitores de livros físicos.\n\nFonte: Chang et al., PNAS, 2015.",
  ),
  _InsightEntry(
    icon: Icons.casino_rounded,
    title: "Loops de recompensa variável",
    summary: "Apps de redes sociais exploram o mesmo circuito cerebral que mantém pessoas em slot machines.",
    detail: "O sistema dopaminérgico responde mais fortemente à antecipação de recompensas incertas. O feed infinito e os likes imprevisíveis são projetados deliberadamente para maximizar esse efeito.\n\nFonte: Tristan Harris; pesquisas de B.F. Skinner sobre reforço variável.",
  ),
  _InsightEntry(
    icon: Icons.visibility_off_rounded,
    title: "O efeito de ter o celular por perto",
    summary: "Ter o smartphone sobre a mesa — mesmo silenciado — já reduz a capacidade cognitiva disponível.",
    detail: "Um experimento da UT Austin com 800 participantes mostrou que a mera presença do celular drena recursos cognitivos, pois o cérebro gasta energia resistindo ao impulso de verificá-lo.\n\nFonte: Ward et al., Journal of the Association for Consumer Research, 2017.",
  ),
  _InsightEntry(
    icon: Icons.access_time_rounded,
    title: "Média global de tempo de tela",
    summary: "Em 2024, adultos gastam em média 6h58min por dia com telas — mais do que dormem.",
    detail: "No Brasil, a média de uso diário de internet mobile supera 5 horas, com picos entre 18h e 23h. Em comparação, o sono médio dos brasileiros é de cerca de 6h30.\n\nFonte: DataReportal, Global Digital Report 2024.",
  ),
  _InsightEntry(
    icon: Icons.sentiment_satisfied_rounded,
    title: "Uso passivo vs. ativo",
    summary: "Rolar o feed passivamente está ligado à depressão; interações ativas mostram efeito neutro ou positivo.",
    detail: "O consumo passivo (scroll sem interação) está correlacionado com sentimentos de inadequação. Criar conteúdo e conversar com amigos tem impacto emocional diferente.\n\nFonte: Verduyn et al., Journal of Experimental Psychology, 2015.",
  ),
  _InsightEntry(
    icon: Icons.lock_open_rounded,
    title: "Desbloqueios por dia",
    summary: "O usuário médio desbloqueia o celular 58 vezes por dia — uma a cada 16 minutos acordado.",
    detail: "A maioria dos desbloqueios dura menos de 30 segundos: uma verificação rápida de notificação. Esse comportamento é em grande parte automático e inconsciente, similar a um tique nervoso condicionado.\n\nFonte: IDC Research, 2023.",
  ),
  _InsightEntry(
    icon: Icons.spa_rounded,
    title: "Dopamine detox funciona?",
    summary: "Pausas digitais de 1–2 semanas mostram redução mensurável nos níveis de ansiedade.",
    detail: "Um estudo de 2018 mostrou que participantes que pararam de usar Facebook por 1 semana relataram aumento significativo no bem-estar subjetivo. Pequenas pausas permitem que o sistema dopaminérgico se 'ressensibilize'.\n\nFonte: Tromholt, Cyberpsychology, Behavior, and Social Networking, 2016.",
  ),
  _InsightEntry(
    icon: Icons.nights_stay_rounded,
    title: "Redes sociais e qualidade do sono",
    summary: "Jovens que usam redes sociais mais de 2h/dia têm 3x mais probabilidade de relatar sono perturbado.",
    detail: "A estimulação emocional do conteúdo mantém o sistema nervoso ativado, enquanto a luz azul atrasa o ritmo circadiano. O resultado é sono mais superficial e menos restaurador.\n\nFonte: Twenge et al., Preventive Medicine Reports, 2017.",
  ),
  _InsightEntry(
    icon: Icons.hourglass_top_rounded,
    title: "Horas de vida",
    summary: "Com 7h de tela/dia durante 40 anos, são ~102.000 horas — equivalente a 11,6 anos de vida.",
    detail: "Visualizar o tempo em unidades maiores (anos de vida em vez de horas por dia) aumenta significativamente a intenção de mudança de comportamento.\n\nFonte: cálculo baseado em médias do Global Digital Report 2024.",
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isOverlayGranted = false;
  bool isUsageStatsGranted = false;
  bool isBatteryOptIgnored = false;
  bool isMonitoringActive = false;

  // Insight rotativo
  int _insightIndex = 0;
  Timer? _insightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _insightIndex = DateTime.now().day % _allInsights.length;
    _insightTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _insightIndex = (_insightIndex + 1) % _allInsights.length);
    });
    _refresh();
  }

  @override
  void dispose() {
    _insightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final overlay = await FlutterOverlayWindow.isPermissionGranted();
      final usage = await UsageStats.checkUsagePermission() ?? false;
      bool battery = false;
      try {
        battery = await Permission.ignoreBatteryOptimizations.isGranted;
      } catch (_) {}
      // Monitoring is only "truly active" if service runs AND core permissions are granted
      final serviceRunning = await FlutterBackgroundService().isRunning();
      final monitoringActive = serviceRunning && overlay && usage;

      if (mounted) {
        setState(() {
          isOverlayGranted = overlay;
          isUsageStatsGranted = usage;
          isBatteryOptIgnored = battery;
          isMonitoringActive = monitoringActive;
        });
      }
    } catch (e) {
      debugPrint("Erro em _refresh: $e");
    }
  }

  Future<void> _toggleMonitoring() async {
    if (!isOverlayGranted || !isUsageStatsGranted) return;

    if (isMonitoringActive) {
      FlutterBackgroundService().invoke("stopService");
      // Poll until stopped (max 3s)
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!await FlutterBackgroundService().isRunning()) break;
      }
    } else {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      await initializeBackgroundService();
      await FlutterBackgroundService().startService();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    await _refresh();
  }

  Future<void> _requestPermission(Future<void> Function() action) async {
    await action();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allGranted = isOverlayGranted && isUsageStatsGranted;
    final insight = _allInsights[_insightIndex];

    return Scaffold(
      appBar: AppBar(title: const Text("AppTime")),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        children: [

          // ── Insight do dia ──────────────────────────────────────────
          _InsightCard(insight: insight, theme: theme),

          const SizedBox(height: AppTheme.spacingLG),

          // ── Permissões ─────────────────────────────────────────────
          Text("Permissões", style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSM),

          _PermissionTile(
            title: "Janela flutuante",
            subtitle: "Exibir o overlay sobre outros apps",
            granted: isOverlayGranted,
            onTap: () => _requestPermission(() async {
              await Permission.systemAlertWindow.request();
            }),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _PermissionTile(
            title: "Estatísticas de uso",
            subtitle: "Detectar qual app está em uso",
            granted: isUsageStatsGranted,
            onTap: () => _requestPermission(() async {
              await UsageStats.grantUsagePermission();
            }),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _PermissionTile(
            title: "Segundo plano",
            subtitle: "Manter o monitoramento sem interrupções",
            granted: isBatteryOptIgnored,
            required: false,
            onTap: () => _requestPermission(() async {
              await Permission.ignoreBatteryOptimizations.request();
            }),
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // ── Contador ───────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Contador", style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppTheme.spacingMD),
                  Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isMonitoringActive
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          key: ValueKey(isMonitoringActive),
                          color: isMonitoringActive
                              ? AppTheme.success
                              : theme.colorScheme.outline,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMonitoringActive ? "Contador ativo" : "Contador inativo",
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              isMonitoringActive
                                  ? "A sobreposição com o contador está funcionando em segundo plano"
                                  : "Inicie o contador para ver o overlay",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  FilledButton(
                    onPressed: allGranted ? _toggleMonitoring : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor:
                          isMonitoringActive ? AppTheme.error : AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                    ),
                    child: Text(
                      isMonitoringActive
                          ? "Pausar monitoramento"
                          : "Iniciar monitoramento",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMD),
        ],
      ),
    );
  }
}

// ── Insight card expansível ──────────────────────────────────────────────────

class _InsightCard extends StatefulWidget {
  final _InsightEntry insight;
  final ThemeData theme;
  const _InsightCard({required this.insight, required this.theme});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_InsightCard old) {
    super.didUpdateWidget(old);
    if (old.insight != widget.insight) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "INSIGHT DO DIA",
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.insight.icon, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.insight.title,
                          style: widget.theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.insight.summary,
                            style: widget.theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: AppTheme.spacingMD),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Text(widget.insight.detail,
                      style: widget.theme.textTheme.bodySmall?.copyWith(height: 1.6)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Permission tile ──────────────────────────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;
  final bool required;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: granted ? null : onTap,
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            key: ValueKey(granted),
            color: granted ? AppTheme.success : theme.colorScheme.outline,
            size: 28,
          ),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
        trailing: !granted && required
            ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline)
            : null,
      ),
    );
  }
}
