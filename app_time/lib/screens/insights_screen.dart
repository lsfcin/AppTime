import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _categoryIndex = 0;

  static const List<_Category> _categories = [
    _Category(
      label: "Foco",
      icon: Icons.center_focus_strong_rounded,
      insights: [
        _Insight(
          title: "A regra dos 23 minutos",
          summary:
              "Após cada interrupção do celular, o cérebro leva em média 23 minutos para retornar ao nível de concentração anterior.",
          detail:
              "Pesquisadores da UC Irvine estudaram trabalhadores em seus ambientes naturais e descobriram que o custo cognitivo de cada distração é muito maior do que parece. Cada notificação não cria apenas uma pausa — ela reinicia o ciclo de atenção profunda do zero.\n\nFonte: Gloria Mark, UC Irvine (2008).",
          icon: Icons.timer_rounded,
        ),
        _Insight(
          title: "Modo multitarefa é um mito",
          summary:
              "O cérebro humano não executa tarefas em paralelo: ele alterna rapidamente entre elas, perdendo eficiência a cada troca.",
          detail:
              "Estudos da APA mostram que o \"switching cost\" — o tempo perdido ao trocar de tarefa — reduz a produtividade em até 40%. Usar o celular enquanto trabalha não é multitarefa; é fazer duas coisas mal feitas.\n\nFonte: American Psychological Association, 2006.",
          icon: Icons.swap_horiz_rounded,
        ),
        _Insight(
          title: "O efeito de apenas ter o celular por perto",
          summary:
              "Ter o smartphone sobre a mesa — mesmo virado para baixo e silenciado — já reduz a capacidade cognitiva disponível.",
          detail:
              "Um experimento da UT Austin com 800 participantes mostrou que a mera presença do celular no campo visual drena recursos cognitivos, pois o cérebro gasta energia resistindo ao impulso de verificá-lo.\n\nFonte: Ward et al., Journal of the Association for Consumer Research, 2017.",
          icon: Icons.visibility_off_rounded,
        ),
      ],
    ),
    _Category(
      label: "Sono",
      icon: Icons.bedtime_rounded,
      insights: [
        _Insight(
          title: "Luz azul e o relógio biológico",
          summary:
              "A luz emitida por telas suprime a produção de melatonina, atrasando o sono em até 1,5 hora.",
          detail:
              "A melatonina é o hormônio que sinaliza ao corpo que é hora de dormir. Estudos do Brigham and Women's Hospital mostram que leitores de e-readers levam mais tempo para adormecer, têm menos sono REM e se sentem mais sonolentos na manhã seguinte em comparação a leitores de livros físicos.\n\nFonte: Chang et al., PNAS, 2015.",
          icon: Icons.brightness_4_rounded,
        ),
        _Insight(
          title: "Redes sociais e qualidade do sono",
          summary:
              "Jovens que usam redes sociais mais de 2 horas por dia têm 3x mais probabilidade de relatar sono perturbado.",
          detail:
              "O mecanismo é duplo: a estimulação emocional do conteúdo (ansiedade, comparação social) mantém o sistema nervoso ativado, enquanto a luz azul atrasa o ritmo circadiano. O resultado é sono mais superficial e menos restaurador.\n\nFonte: Twenge et al., Preventive Medicine Reports, 2017.",
          icon: Icons.nights_stay_rounded,
        ),
        _Insight(
          title: "A regra do bedroom",
          summary:
              "Manter o celular fora do quarto está associado a 30 minutos a mais de sono por noite em média.",
          detail:
              "Estudos longitudinais mostram que a simples retirada do smartphone do quarto de dormir — sem nenhuma outra mudança de comportamento — é uma das intervenções mais eficazes para melhorar a qualidade do sono. O carregador fica na sala.\n\nFonte: Hale et al., Sleep Medicine Reviews, 2018.",
          icon: Icons.king_bed_rounded,
        ),
      ],
    ),
    _Category(
      label: "Dopamina",
      icon: Icons.bolt_rounded,
      insights: [
        _Insight(
          title: "Design persuasivo e loops de recompensa",
          summary:
              "Apps de redes sociais são projetados para explorar o mesmo circuito de recompensa variável que mantém pessoas nas slot machines.",
          detail:
              "O sistema dopaminérgico do cérebro responde mais fortemente à antecipação de recompensas incertas do que a recompensas garantidas. O feed infinito, os likes e as notificações imprevisíveis são implementados deliberadamente para maximizar esse efeito.\n\nFonte: Tristan Harris, ex-design ethicist do Google; pesquisas de B.F. Skinner sobre reforço variável.",
          icon: Icons.casino_rounded,
        ),
        _Insight(
          title: "Nomofobia: o medo de ficar sem o celular",
          summary:
              "Cerca de 66% dos adultos relatam ansiedade quando ficam sem o smartphone por curtos períodos.",
          detail:
              "O termo nomofobia (no-mobile-phone phobia) descreve o desconforto causado pela separação do celular. Pesquisas mostram aumento do cortisol (hormônio do estresse) e frequência cardíaca em usuários que ficam sem o aparelho — respostas similares às observadas em dependências químicas leves.\n\nFonte: King et al., Journal of Clinical Practice, 2013.",
          icon: Icons.phone_locked_rounded,
        ),
        _Insight(
          title: "Dopamine detox funciona?",
          summary:
              "Pausas digitais de 1–2 semanas mostram redução mensurável nos níveis de ansiedade e melhora no humor.",
          detail:
              "Um estudo de 2018 mostrou que participantes que pararam de usar Facebook por 1 semana relataram aumento significativo no bem-estar subjetivo. O efeito é explicado pela recalibração da sensibilidade dopaminérgica — pequenas pausas permitem que o sistema se 'ressensibilize'.\n\nFonte: Tromholt, Cyberpsychology, Behavior, and Social Networking, 2016.",
          icon: Icons.spa_rounded,
        ),
      ],
    ),
    _Category(
      label: "Bem-estar",
      icon: Icons.favorite_rounded,
      insights: [
        _Insight(
          title: "Uso passivo vs. ativo",
          summary:
              "Rolar o feed passivamente está ligado à depressão; interações ativas (mensagens, criação) mostram efeito neutro ou positivo.",
          detail:
              "Pesquisadores de Oxford e da Universidade de Michigan distinguiram dois padrões de uso. O consumo passivo de conteúdo (scroll sem interação) está correlacionado com sentimentos de inadequação e FOMO. Já criar conteúdo, conversar e interagir com amigos mostra impacto emocional diferente.\n\nFonte: Verduyn et al., Journal of Experimental Psychology, 2015.",
          icon: Icons.sentiment_satisfied_rounded,
        ),
        _Insight(
          title: "A ilusão de conexão",
          summary:
              "Mais tempo em redes sociais não aumenta a sensação de conexão social — em alguns estudos, a reduz.",
          detail:
              "Paradoxalmente, o aumento do uso de redes sociais está correlacionado com maior solidão percebida. Interações mediadas por tela ativam menos os sistemas sociais do cérebro do que encontros presenciais, deixando a necessidade de conexão parcialmente insatisfeita.\n\nFonte: Twenge & Campbell, Social Psychological and Personality Science, 2019.",
          icon: Icons.people_outline_rounded,
        ),
        _Insight(
          title: "Atenção plena e o celular",
          summary:
              "Pessoas que verificam o celular com menos frequência reportam maior presença e satisfação nas interações sociais.",
          detail:
              "Estudos de mindfulness mostram que a compulsão de verificar o celular durante conversas reduz a qualidade percebida da interação por ambas as partes. A outra pessoa sente o desvio de atenção mesmo quando o celular está apenas parcialmente visível.\n\nFonte: Misra et al., Environment and Behavior, 2016.",
          icon: Icons.self_improvement_rounded,
        ),
      ],
    ),
    _Category(
      label: "Números",
      icon: Icons.bar_chart_rounded,
      insights: [
        _Insight(
          title: "Média global de tempo de tela",
          summary:
              "Em 2024, adultos gastam em média 6h58min por dia com telas — mais do que dormem.",
          detail:
              "O relatório Global Digital Report 2024 mostra crescimento constante desde 2012. No Brasil, a média de uso diário de internet mobile supera 5 horas, com picos entre 18h e 23h. Em comparação, o sono médio dos brasileiros é de cerca de 6h30.\n\nFonte: DataReportal, Global Digital Report 2024.",
          icon: Icons.access_time_rounded,
        ),
        _Insight(
          title: "Desbloqueios por dia",
          summary:
              "O usuário médio desbloqueia o celular 58 vezes por dia — uma a cada 16 minutos acordado.",
          detail:
              "Pesquisas de usage patterns mostram que a maioria dos desbloqueios dura menos de 30 segundos: uma verificação rápida de notificação, hora ou mensagem. Esse comportamento é em grande parte automático e inconsciente, similar a um tique nervoso condicionado.\n\nFonte: IDC Research, 2023; Dscout Mobile Moment Study.",
          icon: Icons.lock_open_rounded,
        ),
        _Insight(
          title: "Horas de vida",
          summary:
              "Com 7h de tela por dia durante 40 anos de vida adulta ativa, são ~102.000 horas — equivalente a 11,6 anos.",
          detail:
              "Colocar o tempo de tela em perspectiva temporal ajuda a calibrar escolhas. Estudos de economia comportamental mostram que visualizar o tempo em unidades maiores (anos de vida em vez de horas por dia) aumenta significativamente a intenção de mudança de comportamento.\n\nFonte: cálculo baseado em médias do Global Digital Report 2024.",
          icon: Icons.hourglass_top_rounded,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = _categories[_categoryIndex];

    return Scaffold(
      appBar: AppBar(title: const Text("Insights")),
      body: Column(
        children: [
          // Category tabs
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD, vertical: AppTheme.spacingSM),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (i) {
                  final cat = _categories[i];
                  final selected = i == _categoryIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingSM),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 16,
                          color: selected ? Colors.white : AppTheme.primary),
                      label: Text(cat.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _categoryIndex = i),
                      selectedColor: AppTheme.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }),
              ),
            ),
          ),

          // Insights list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMD, 0, AppTheme.spacingMD, AppTheme.spacingLG),
              itemCount: category.insights.length,
              itemBuilder: (context, i) => _InsightCard(
                insight: category.insights[i],
                theme: theme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatefulWidget {
  final _Insight insight;
  final ThemeData theme;

  const _InsightCard({required this.insight, required this.theme});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Text(
                          widget.insight.summary,
                          style: widget.theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
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
                  child: Text(
                    widget.insight.detail,
                    style: widget.theme.textTheme.bodySmall?.copyWith(height: 1.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String label;
  final IconData icon;
  final List<_Insight> insights;
  const _Category({required this.label, required this.icon, required this.insights});
}

class _Insight {
  final String title;
  final String summary;
  final String detail;
  final IconData icon;
  const _Insight({
    required this.title,
    required this.summary,
    required this.detail,
    required this.icon,
  });
}
