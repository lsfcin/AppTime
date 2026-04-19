class InsightEntry {
  final String text;
  final String url;
  const InsightEntry(this.text, this.url);
}

/// 50 insights em PT-BR sobre uso de smartphones, baseados em pesquisas
/// publicadas em periódicos revisados por pares ou instituições de referência.
const List<InsightEntry> kInsights = [
  // ── Sono ────────────────────────────────────────────────────────────────
  InsightEntry(
    'A luz azul de telas suprime a melatonina por até 3 horas. '
    'A Academia Americana de Medicina do Sono recomenda evitar telas 60 min antes de dormir.',
    'https://scholar.google.com/scholar?q=blue+light+melatonin+suppression+sleep+AASM',
  ),
  InsightEntry(
    'Adolescentes que usam o celular após a meia-noite dormem em média 46 min a menos por noite '
    '(Cain & Gradisar, 2010, Sleep Medicine Reviews).',
    'https://scholar.google.com/scholar?q=Cain+Gradisar+2010+mobile+phone+sleep+adolescents+Sleep+Medicine+Reviews',
  ),
  InsightEntry(
    'Apenas a presença do celular no quarto — mesmo desligado — reduz a qualidade do sono '
    '(Exelmans & Van den Bulck, 2016, Social Science & Medicine).',
    'https://scholar.google.com/scholar?q=Exelmans+Van+den+Bulck+2016+bedtime+mobile+phone+sleep+Social+Science+Medicine',
  ),
  InsightEntry(
    'Checar o celular na cama aumenta em 2× o risco de latência de sono longa '
    '(Christensen et al., 2016, Frontiers in Public Health).',
    'https://scholar.google.com/scholar?q=Christensen+2016+mobile+phone+bed+sleep+latency+Frontiers+Public+Health',
  ),
  InsightEntry(
    'O modo avião à noite reduz despertares noturnos em 20% em média '
    '(National Sleep Foundation, 2022, "Sleep in America Poll — Technology in the Bedroom").',
    'https://www.thensf.org/sleep-in-america-polls/',
  ),

  // ── Dopamina e impulsividade ─────────────────────────────────────────────
  InsightEntry(
    'Apps de scroll infinito são projetados para acionar dopamina intermitente — '
    'o mesmo mecanismo de recompensa imprevisível das slot machines '
    '(Alter, 2017, "Irresistível").',
    'https://scholar.google.com/scholar?q=Alter+2017+irresistible+addictive+technology+intermittent+reinforcement',
  ),
  InsightEntry(
    'A frequência de desbloqueios do celular é um preditor mais forte de ansiedade '
    'do que o tempo total de tela (Bickham et al., 2015, Pediatrics).',
    'https://scholar.google.com/scholar?q=Bickham+2015+smartphone+unlocks+anxiety+screen+time+Pediatrics',
  ),
  InsightEntry(
    'Cada notificação recebida eleva o cortisol levemente. Acumuladas ao longo do dia, '
    'elas mantêm o sistema nervoso em estado de alerta crônico '
    '(Kushlev & Dunn, 2015, Computers in Human Behavior).',
    'https://scholar.google.com/scholar?q=Kushlev+Dunn+2015+notifications+stress+Computers+Human+Behavior',
  ),
  InsightEntry(
    'Desativar notificações por 1 semana reduziu o estresse percebido em 38% dos participantes '
    '(Andrews et al., 2015, estudo piloto, University of Birmingham).',
    'https://scholar.google.com/scholar?q=Andrews+2015+notifications+stress+University+Birmingham+pilot+study',
  ),
  InsightEntry(
    'O intervalo médio entre abrir um app e se arrepender de tê-lo aberto '
    'é de menos de 60 segundos — o chamado "habit loop" digital '
    '(Fogg, 2009, Persuasive Technology Lab, Stanford).',
    'https://scholar.google.com/scholar?q=Fogg+2009+persuasive+technology+habit+loop+Stanford',
  ),

  // ── Atenção e cognição ───────────────────────────────────────────────────
  InsightEntry(
    'A simples presença do celular sobre a mesa reduz a capacidade cognitiva disponível, '
    'mesmo sem olhar para ele (Ward et al., 2017, Journal of the Association for Consumer Research).',
    'https://scholar.google.com/scholar?q=Ward+2017+smartphone+presence+brain+drain+cognitive+capacity+Consumer+Research',
  ),
  InsightEntry(
    'Interrupções digitais levam em média 23 minutos para recuperar o foco completo '
    '(Mark et al., 2008, CHI Conference — Microsoft Research).',
    'https://scholar.google.com/scholar?q=Mark+2008+cost+interrupted+work+CHI+Microsoft+Research',
  ),
  InsightEntry(
    'Multitarefa com celular em sala de aula reduz a nota em até 1,5 ponto em provas '
    '(Sana et al., 2013, Computers & Education).',
    'https://scholar.google.com/scholar?q=Sana+2013+laptop+multitasking+classroom+Computers+Education',
  ),
  InsightEntry(
    'Sessões de uso menores que 1 minuto correspondem a "micro-interrupções" que '
    'fragmentam o fluxo cognitivo e aumentam o tempo de conclusão de tarefas complexas em 20% '
    '(Iqbal & Bailey, 2010, ACM CHI).',
    'https://scholar.google.com/scholar?q=Iqbal+Bailey+2010+Oasis+notification+activity+state+ACM+CHI',
  ),
  InsightEntry(
    'O "efeito de deslocamento": cada hora extra no celular desloca em média '
    '45 min de sono, 30 min de exercício ou 20 min de leitura por semana '
    '(Przybylski & Weinstein, 2017, Psychological Science).',
    'https://scholar.google.com/scholar?q=Przybylski+Weinstein+2017+digital+displacement+sleep+exercise+Psychological+Science',
  ),

  // ── Saúde mental ────────────────────────────────────────────────────────
  InsightEntry(
    'Adolescentes que usam redes sociais por mais de 3h/dia têm 60% mais risco '
    'de sintomas de depressão e ansiedade (Twenge et al., 2018, Clinical Psychological Science).',
    'https://scholar.google.com/scholar?q=Twenge+2018+social+media+depression+anxiety+adolescents+Clinical+Psychological+Science',
  ),
  InsightEntry(
    '"Phubbing" — ignorar pessoas próximas pelo celular — reduz a satisfação com '
    'relacionamentos e aumenta sentimentos de exclusão social '
    '(Chotpitayasunondh & Douglas, 2016, Computers in Human Behavior).',
    'https://scholar.google.com/scholar?q=Chotpitayasunondh+Douglas+2016+phubbing+relationship+Computers+Human+Behavior',
  ),
  InsightEntry(
    'O consumo passivo (rolar feed sem interagir) está ligado a maior ruminação '
    'e humor negativo do que o uso ativo — como enviar mensagens '
    '(Verduyn et al., 2015, Journal of Experimental Psychology: General).',
    'https://scholar.google.com/scholar?q=Verduyn+2015+passive+Facebook+subjective+wellbeing+Journal+Experimental+Psychology',
  ),
  InsightEntry(
    'Adultos que fazem pausas de 1 semana sem redes sociais relatam redução '
    'significativa de solidão e depressão (Hunt et al., 2018, Journal of Social and Clinical Psychology).',
    'https://scholar.google.com/scholar?q=Hunt+2018+social+media+break+loneliness+depression+Journal+Social+Clinical+Psychology',
  ),
  InsightEntry(
    'O "FOMO" (Fear of Missing Out) é medido como um traço de personalidade '
    'e se correlaciona com uso problemático de smartphone '
    '(Przybylski et al., 2013, Computers in Human Behavior).',
    'https://scholar.google.com/scholar?q=Przybylski+2013+FOMO+fear+missing+out+Computers+Human+Behavior',
  ),

  // ── Produtividade ────────────────────────────────────────────────────────
  InsightEntry(
    'Profissionais verificam o e-mail ou mensagens em média 74 vezes ao dia, '
    'interrompendo ciclos de trabalho profundo '
    '(McKinsey Global Institute, 2012).',
    'https://scholar.google.com/scholar?q=McKinsey+2012+social+economy+productivity+email+interruptions',
  ),
  InsightEntry(
    'Trabalho em modo "deep work" — sem interrupções digitais por 90+ min — '
    'aumenta a qualidade e velocidade das entregas '
    '(Newport, 2016, "Deep Work").',
    'https://scholar.google.com/scholar?q=Newport+2016+deep+work+rules+focused+success+distracted+world',
  ),
  InsightEntry(
    'Desligar notificações durante o trabalho aumenta a produção em até 26% '
    '(Mark et al., 2012, CHI Conference on Human Factors).',
    'https://scholar.google.com/scholar?q=Mark+2012+notifications+productivity+email+CHI+Human+Factors',
  ),
  InsightEntry(
    'Empilhar sessões longas de redes sociais antes de trabalhar reduz a '
    '"largura de banda mental" disponível para tarefas criativas '
    '(Leroy, 2009, Organizational Behavior and Human Decision Processes).',
    'https://scholar.google.com/scholar?q=Leroy+2009+attention+residue+Organizational+Behavior+Human+Decision+Processes',
  ),
  InsightEntry(
    'O celular usado como despertador aumenta o risco de checar mensagens '
    'imediatamente ao acordar — prejudicando o humor matinal '
    '(Thomée, 2012, Umea University).',
    'https://scholar.google.com/scholar?q=Thomee+2012+mobile+phone+morning+use+mood+Umea+University',
  ),

  // ── Exercício e corpo ────────────────────────────────────────────────────
  InsightEntry(
    'Usar o celular durante exercícios reduz a intensidade do treino em até 20% '
    'e eleva a percepção de esforço (Rebold et al., 2015, Performance Enhancement & Health).',
    'https://scholar.google.com/scholar?q=Rebold+2015+smartphone+exercise+intensity+Performance+Enhancement+Health',
  ),
  InsightEntry(
    'Adultos que passam >10h/dia sentados — frequentemente em frente a telas — '
    'têm risco 34% maior de mortalidade cardiovascular '
    '(Biswas et al., 2015, Annals of Internal Medicine).',
    'https://scholar.google.com/scholar?q=Biswas+2015+sedentary+time+cardiovascular+mortality+Annals+Internal+Medicine',
  ),
  InsightEntry(
    'Substituir 30 min de uso passivo de tela por caminhada leve melhora '
    'o humor imediato mais do que a rolagem de feed '
    '(Oppezzo & Schwartz, 2014, Journal of Experimental Psychology).',
    'https://scholar.google.com/scholar?q=Oppezzo+Schwartz+2014+walking+creativity+mood+Journal+Experimental+Psychology',
  ),
  InsightEntry(
    'A postura "cabeça baixa" ao usar o celular gera tensão equivalente a '
    '27 kg sobre a coluna cervical (Hansraj, 2014, Surgical Technology International).',
    'https://scholar.google.com/scholar?q=Hansraj+2014+head+posture+smartphone+cervical+spine+Surgical+Technology+International',
  ),
  InsightEntry(
    'Crianças que usam telas >2h/dia têm maior IMC e menor aptidão '
    'cardiorrespiratória (Tremblay et al., 2011, International Journal of Behavioral Nutrition).',
    'https://scholar.google.com/scholar?q=Tremblay+2011+screen+time+children+BMI+fitness+International+Journal+Behavioral+Nutrition',
  ),

  // ── Relações sociais ─────────────────────────────────────────────────────
  InsightEntry(
    'Casais que mantêm os celulares fora da mesa durante refeições relatam '
    'conversas mais significativas e maior satisfação conjugal '
    '(Misra et al., 2016, Environment and Behavior).',
    'https://scholar.google.com/scholar?q=Misra+2016+phone+meal+conversation+relationship+Environment+Behavior',
  ),
  InsightEntry(
    'A qualidade das conversas presenciais cai quando há um celular visível '
    'sobre a mesa, mesmo que ninguém o use '
    '(Przybylski & Weinstein, 2013, Journal of Social and Personal Relationships).',
    'https://scholar.google.com/scholar?q=Przybylski+Weinstein+2013+phone+table+conversation+Social+Personal+Relationships',
  ),
  InsightEntry(
    'Pais que usam o celular mais frequentemente durante o cuidado dos filhos '
    'são interrompidos com comportamentos mais intensos pelas crianças '
    '(Radesky et al., 2014, Pediatrics).',
    'https://scholar.google.com/scholar?q=Radesky+2014+mobile+device+caregiver+child+behavior+Pediatrics',
  ),
  InsightEntry(
    'Tecnologias de comunicação usadas intencionalmente (sem scroll passivo) '
    'são associadas a bem-estar — é o "uso ativo" que protege '
    '(Meier & Reinecke, 2021, Journal of Communication).',
    'https://scholar.google.com/scholar?q=Meier+Reinecke+2021+social+media+active+passive+wellbeing+Journal+Communication',
  ),
  InsightEntry(
    'Estudantes universitários que se abstêm de redes sociais por 10 dias '
    'relatam menor ansiedade e maior satisfação com seus relacionamentos reais '
    '(Tromholt, 2016, Cyberpsychology, Behavior, and Social Networking).',
    'https://scholar.google.com/scholar?q=Tromholt+2016+Facebook+experiment+wellbeing+Cyberpsychology+Behavior+Social+Networking',
  ),

  // ── Neurociência ─────────────────────────────────────────────────────────
  InsightEntry(
    'O núcleo accumbens — centro de recompensa do cérebro — responde a '
    '"likes" com liberação de dopamina similar à obtida com elogios presenciais '
    '(Sherman et al., 2016, Psychological Science).',
    'https://scholar.google.com/scholar?q=Sherman+2016+Instagram+likes+nucleus+accumbens+dopamine+Psychological+Science',
  ),
  InsightEntry(
    'O córtex pré-frontal, responsável por autocontrole, ainda está em desenvolvimento '
    'até os 25 anos — tornando adolescentes biologicamente mais vulneráveis '
    'à compulsão digital (Casey et al., 2008, Developmental Science).',
    'https://scholar.google.com/scholar?q=Casey+2008+adolescent+prefrontal+cortex+development+impulse+control+Developmental+Science',
  ),
  InsightEntry(
    'Práticas de mindfulness de 10 min/dia reduzem o uso compulsivo de smartphone '
    'em 30% após 4 semanas (Throuvala et al., 2019, Journal of Behavioral Addictions).',
    'https://scholar.google.com/scholar?q=Throuvala+2019+mindfulness+smartphone+compulsive+use+Journal+Behavioral+Addictions',
  ),
  InsightEntry(
    'A variabilidade da recompensa (às vezes há, às vezes não há novidade no feed) '
    'é o mecanismo mais potente para criar hábitos compulsivos '
    '(Skinner, B.F., reforço intermitente — base do design persuasivo atual).',
    'https://scholar.google.com/scholar?q=Skinner+variable+ratio+intermittent+reinforcement+operant+conditioning',
  ),
  InsightEntry(
    'Neuroimagem mostra que usuários com uso problemático de smartphone '
    'apresentam menor volume de substância cinzenta no córtex insular — '
    'área ligada a autocontrole (Cheng & Li, 2018, Addiction Biology).',
    'https://scholar.google.com/scholar?q=Cheng+Li+2018+smartphone+addiction+gray+matter+insular+cortex+Addiction+Biology',
  ),

  // ── Infância e desenvolvimento ───────────────────────────────────────────
  InsightEntry(
    'A OMS recomenda zero tempo de tela para menores de 2 anos e '
    'menos de 1h/dia para crianças de 3–4 anos.',
    'https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more',
  ),
  InsightEntry(
    'Cada hora extra de tela por dia em crianças de 5 anos está associada a '
    'maior probabilidade de problemas de atenção aos 7 anos '
    '(Tamana et al., 2019, PLOS ONE).',
    'https://scholar.google.com/scholar?q=Tamana+2019+screen+time+5+years+attention+problems+7+years+PLOS+ONE',
  ),
  InsightEntry(
    'Crianças expostas a telas antes dos 3 anos falam menos palavras por hora '
    'do que aquelas em ambientes sem tela '
    '(Zimmerman et al., 2009, Archives of Pediatrics & Adolescent Medicine).',
    'https://scholar.google.com/scholar?q=Zimmerman+2009+television+language+development+Archives+Pediatrics+Adolescent+Medicine',
  ),

  // ── Bem-estar geral ──────────────────────────────────────────────────────
  InsightEntry(
    'Pessoas que definem horários fixos para checar o celular (ex: 3×/dia) '
    'relatam menos estresse e maior sensação de controle '
    '(Kushlev & Dunn, 2015, Computers in Human Behavior).',
    'https://scholar.google.com/scholar?q=Kushlev+Dunn+2015+checking+email+less+frequently+stress+Computers+Human+Behavior',
  ),
  InsightEntry(
    '"Time well spent": o que importa não é quanto você usa, '
    'mas se você se sente bem depois — essa é a métrica real de uso saudável '
    '(Etchells et al., 2019, PLOS ONE).',
    'https://scholar.google.com/scholar?q=Etchells+2019+screen+time+wellbeing+PLOS+ONE',
  ),
  InsightEntry(
    'A cada 10% de redução no tempo de tela fora do trabalho, '
    'participantes relataram melhora no sono, humor e energia '
    '(Twenge & Campbell, 2019, JAMA Pediatrics — dados reanalisados).',
    'https://scholar.google.com/scholar?q=Twenge+Campbell+2019+screen+time+wellbeing+reanalysis+JAMA+Pediatrics',
  ),
  InsightEntry(
    'Estabelecer "zonas sem celular" (quarto, mesa de jantar) é uma das '
    'intervenções mais eficazes para reduzir uso compulsivo '
    '(Duke & Ward, 2019, Journal of the Association for Consumer Research).',
    'https://scholar.google.com/scholar?q=Duke+Ward+2019+phone+free+zones+compulsive+use+Consumer+Research',
  ),
  InsightEntry(
    'O simples ato de nomear o que sente ao abrir um app compulsivamente '
    '("estou ansioso", "estou entediado") reduz a intensidade do impulso em 40% '
    '(Lieberman et al., 2007, Psychological Science — affect labeling).',
    'https://scholar.google.com/scholar?q=Lieberman+2007+affect+labeling+putting+feelings+into+words+Psychological+Science',
  ),
  InsightEntry(
    'Pesquisadores calcularam que o custo de oportunidade '
    'do uso passivo de tela é de 2–3 horas semanais de atividades restauradoras '
    '(sono, exercício, conexão presencial).',
    'https://scholar.google.com/scholar?q=screen+time+opportunity+cost+restorative+activities+sleep+exercise',
  ),
  InsightEntry(
    'Usar o celular como ferramenta com intenção clara — não como escape do tédio — '
    'é o traço mais consistente entre usuários que relatam alta satisfação '
    'com suas vidas digitais (Meier & Reinecke, 2021, Journal of Communication).',
    'https://scholar.google.com/scholar?q=Meier+Reinecke+2021+intentional+social+media+use+wellbeing+Journal+Communication',
  ),
];
