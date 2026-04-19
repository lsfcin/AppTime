import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn(super.locale);

  @override String get navHome => 'Home';
  @override String get navAnalysis => 'Analysis';
  @override String get navInsights => 'Insights';
  @override String get navMonitoring => 'Monitor';
  @override String get navSettings => 'Settings';

  @override String get cancel => 'Cancel';
  @override String get save => 'Save';
  @override String get noData => 'No data yet.';
  @override String get collectingData => 'Collecting data — check back later.';

  @override String get permFloatingWindow => 'Floating window';
  @override String get permUsageStats => 'Usage statistics';
  @override String get permGranted => 'Granted';
  @override String get permRequired => 'Required';
  @override String get permGrant => 'Grant';
  @override String get insightOfDay => 'Insight of the day';
  @override String get insightViewSource => 'View source';
  @override String get monitoringTitle => 'Counter';
  @override String get monitoringActive => 'Active — overlay showing real-time usage.';
  @override String get monitoringInactive => 'Inactive. Tap Start.';
  @override String get monitoringNoPerms => 'Grant the permissions above to start.';
  @override String get monitoringDesc =>
      'The overlay shows how many times you opened the app (5s) and cumulative time.';
  @override String get actionStart => 'Start';
  @override String get actionStop => 'Stop';

  @override String get onboardWelcomeTitle => 'Welcome to AppTime';
  @override String get onboardWelcomeBody =>
      'Awareness without blocking.\n\n'
      'AppTime shows, in real time, how many times you opened each app '
      'and how long you spent on it — right on your screen, like a '
      'discreet clock.\n\n'
      'We need 2 permissions to work.';
  @override String get onboardStart => 'Get started';
  @override String get onboardPermOverlayTitle => 'Floating window';
  @override String get onboardPermOverlayDesc =>
      'AppTime needs this permission to show the '
      'real-time usage counter over other apps, without '
      'interrupting what you are doing.';
  @override String get onboardPermUsageTitle => 'Usage statistics';
  @override String get onboardPermUsageDesc =>
      'This permission allows AppTime to access which apps '
      'are in the foreground to accurately track your usage time.';
  @override String get permGrantedLabel => 'Permission granted';
  @override String get permSettingsHint =>
      'You will be taken to the system settings. '
      'Grant the permission and return to the app.';
  @override String get openSettings => 'Open settings';
  @override String get continueAction => 'Continue';

  @override String get settingsTitle => 'Settings';
  @override String get sectionPermissions => 'Permissions';
  @override String get sectionMonitoring => 'Monitoring';
  @override String get sectionOverlay => 'Overlay';
  @override String get showOverlay => 'Show usage overlay';
  @override String get showOverlaySub => 'Display the floating counter while using apps. Monitoring (data collection) continues regardless.';
  @override String get showBorder => 'Show border';
  @override String get showBackground => 'Show background';
  @override String fontSize(int size) => 'Font size: ${size}sp';
  @override String get sectionBehavior => 'Behavior';
  @override String get dailyGoalTitle => 'Daily usage goal';
  @override String get noGoalSet => 'No goal set';
  @override String goalMinutesPerDay(int min) => '$min minutes / day';
  @override String get perAppControlTitle => 'Per-app control';
  @override String get perAppUsageCaption => 'Usage shown is the total for the last 7 days';
  @override String get levelChipOff => 'off';
  @override String get levelChipDefault => 'default';
  @override String get levelChipMin => 'min';
  @override String get levelChipMax => 'max';
  @override String get levelMenuNotMonitored => 'not monitored';
  @override String get levelMenuDefault => 'default (global goal)';
  @override String get levelMenuMinimal => 'light';
  @override String get levelMenuNormal => 'moderate';
  @override String get levelMenuExtensive => 'intense';
  @override String get perAppControlSub => 'Enable / disable overlay per app';
  @override String get monitorLauncherTitle => 'Monitor home screen';
  @override String get monitorLauncherSub => 'Show overlay on the launcher / home screen';
  @override String get dialogDailyGoalTitle => 'Daily goal';
  @override String get dialogNoGoal => 'No goal';
  @override String dialogGoalMinDay(int min) => '$min min / day';
  @override String get sectionLanguage => 'Language';
  @override String get languageSystem => 'System';
  @override String get languagePtBr => 'Português (Brasil)';
  @override String get languageEn => 'English';

  @override String get perAppTitle => 'Per-app control';
  @override String get noAppsMsg =>
      'No apps recorded in the last 7 days.\n'
      'Start monitoring and use your phone normally.';
  @override String get overlayDisabled => 'Overlay disabled';
  @override String get overlayActive => 'Overlay active';

  @override String get analysisTitle => 'Analysis';
  @override String get tab1d => '1 day';
  @override String get tab7d => '7 days';
  @override String get tab30d => '30 days';
  @override String get dayBoundaryNote =>
      'The "day" starts at 4 AM — usage between midnight and 4 AM counts toward the previous day.';
  @override String get statTotalUsage => 'Total usage';
  @override String get statUnlocks => 'Unlocks';
  @override String get statYesterday => 'yesterday';
  @override String get statTotalTime => 'Total time';
  @override String get noSessions => 'No sessions recorded yet.';
  @override String get dailyUsageLabel => 'Daily usage';
  @override String get passive => 'Passive';
  @override String get active => 'Active';
  @override String get prevWeekLabel => 'previous week';
  @override String pagesLabel(int n) => '$n pages';
  @override String kmLabel(int n) => '${n}km';
  @override String sleepCyclesLabel(int n) => '$n cycles';

  @override String get blockSleepTitle => 'Sleep hygiene';
  @override String blockSleepText(int pct) =>
      'Your usage between 10 PM and 6 AM accounts for $pct% of total time. '
      'Blue light during this period can delay melatonin release '
      'by up to 30 minutes, impairing REM sleep.';
  @override String get blockImpulsivityTitle => 'Impulsivity index';
  @override String blockImpulsivityText(int unlocks) =>
      'You unlocked your phone $unlocks times today. '
      'Unlock frequency is a stronger predictor of anxiety '
      'and poor sleep quality than total screen time.';
  @override String get blockFocusTitle => 'Focus fragmentation';
  @override String blockFocusText(int pct) =>
      '$pct% of your sessions lasted less than 60 seconds. '
      'This "checking habit" fragments attention and prevents the '
      'deep focus state (Flow). Users with high fragmentation take up to '
      '20% longer to complete complex tasks.';
  @override String get blockOpportunityTitle => 'Opportunity cost';
  @override String get blockOpportunityText =>
      'Every hour of passive use is an hour that could be spent '
      'on restorative sleep, exercise, or in-person connection.';
  @override String get blockPhubbingTitle => 'Phubbing alert';
  @override String blockPhubbingText(int unlocks) =>
      'You unlocked your phone $unlocks times during lunch and dinner hours. '
      'Phubbing — ignoring those present to check your phone — weakens '
      'social bonds and increases feelings of loneliness over time.';
  @override String get blockDopamineTitle => 'Dopamine drain';
  @override String blockDopamineText(String app, int opens) =>
      '"$app" was your biggest trigger: $opens opens in 7 days. '
      'Infinite-scroll apps are designed like slot machines — '
      'intermittent rewards that create compulsive cycles hard to break.';
  @override String get blockDopamineNoData => 'No data yet.';
  @override String get blockEngagementTitle => 'Engagement balance';
  @override String blockEngagementText(int pct) =>
      'Your usage was $pct% passive this week. '
      'Passive feed consumption (without interacting) is linked to '
      'rumination and depression symptoms, while active use (real messaging) '
      'may have a protective effect on mental health.';
  @override String get blockEngagementNoData => 'No data yet.';
  @override String get blockEngagementClassification =>
      'Passive: social, video, news apps.\nActive: all others.';
  @override String get blockTrendTitle => 'Weekly trend';
  @override String blockTrendReduced(int pct) =>
      'You reduced your usage by $pct% vs. last week. '
      'Maintaining this trend for 21 days is the scientific benchmark '
      'for neural habit rewiring.';
  @override String blockTrendIncreased(int pct) =>
      'Your usage increased $pct% vs. last week. '
      'Try to identify the triggers that led to the increase.';
  @override String get blockTrend30Title => '30-day trend';
  @override String get blockTrend30Text =>
      'Maintaining a downward trend for 21 consecutive days is '
      'the scientific benchmark for habit circuit rewiring '
      'and strengthening the prefrontal cortex.';
  @override String get blockWeekPatternTitle => 'Week pattern';
  @override String get blockWeekPatternText =>
      'Average usage per hour for each day of the week (last 4 weeks). '
      'Each horizontal bar represents 60 minutes; the filled portion '
      'shows time used, stacked by app.';
  @override String get weekdayOtherLabel => 'other';
  @override String get blockYesterdayPatternTitle => 'Yesterday pattern';
  @override String get blockYesterdayPatternText =>
      'Horizontal stacked bars by app — each row is one hour of yesterday.';
  @override String get yesterdayPatternOther => 'other';
  @override String get blockLastDaysPatternTitle => 'Last 7 days pattern';
  @override String get blockLastDaysPatternText =>
      'Horizontal stacked bars — each row is one hour, grouped by day. '
      'Tap the zoom icon to toggle between 2.5-day and full-week view.';
  @override String get statLast7Days => 'Relative to the last 7 days';

  @override String get insightsTitle => 'Insights';
  @override String get tabAlerts => 'Alerts';
  @override String get tabSolutions => 'Solutions';

  @override String get block30dSummaryTitle => '30-Day Overview';
  @override String get block30dChartTitle => 'Daily Usage Trend — 30 Days';
  @override String get block30dChartText =>
      'Total screen time per day (thick white line) with linear trend (dashed grey). '
      'Top 3 apps shown as thin colored lines. '
      'Dashed thresholds: 2 h recommended limit (APA/Common Sense Media) and '
      '4 h critical threshold — Twenge et al. (2018), "Increases in Depressive Symptoms", '
      'Clinical Psychological Science.';

  @override String get goalScreenTitle => 'Usage goals';
  @override String get goalLevelSectionTitle => 'Control level';
  @override String get goalLevelNone => 'Off';
  @override String get goalLevelMinimal => 'Light';
  @override String get goalLevelNormal => 'Moderate';
  @override String get goalLevelExtensive => 'Intense';
  @override String get goalRationaleNone =>
      'Awareness only — no active feedback. Great for understanding '
      'your patterns without pressure.';
  @override String get goalRationaleMinimal =>
      'Light control with gentle reminders. Good for users who want '
      'to stay aware without strong restrictions.';
  @override String get goalRationaleNormal =>
      'Moderate control — balance between productivity and digital leisure. '
      'Aligns with mental health expert recommendations for adults.';
  @override String get goalRationaleExtensive =>
      'Intense control with strict limits. Recommended for users aiming '
      'to significantly reduce screen time.';
  @override String get goalPerAppTitle => 'Per-app goals';
  @override String get goalPerAppSub =>
      'Override the global goal for specific apps.';
  @override String get goalOverrideGlobal => 'Global';
  @override String get goalSettingsTile => 'Usage goals';
  @override String get goalSettingsSub => 'Feedback levels and per-app limits';

  @override String get sectionData => 'Data & Privacy';
  @override String get deleteAllDataTitle => 'Delete all data';
  @override String get deleteAllDataSub => 'Permanently erase all recorded usage history from this device';
  @override String get deleteAllDataConfirm => 'Delete all usage history? This cannot be undone.';
  @override String get deleteAllDataDone => 'All data deleted.';
  @override String get privacyPolicyTitle => 'Privacy policy';
  @override String get privacyPolicySub => 'All data stays on your device — no network, no third parties';
}
