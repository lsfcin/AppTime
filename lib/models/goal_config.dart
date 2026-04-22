/// Goal level chosen by the user.
/// Index matches the `goal_level` SharedPreferences Int (0–3).
enum GoalLevel {
  none,       // 0 — counter only, no messages
  minimal,    // 1 — Occasional: relaxed thresholds
  normal,     // 2 — Regular: moderate thresholds
  extensive,  // 3 — Frequent: strict thresholds
}

/// Thresholds for a single goal level, covering every usage metric.
class GoalThresholds {
  const GoalThresholds({
    required this.phoneLimitMinutes,
    required this.appLimitMinutes,
    required this.unlockLimit,
    required this.maxSessionMinutes,
    required this.sleepCutoffHour,
    required this.wakeupHour,
  });

  /// Max total daily phone usage (minutes).
  final int phoneLimitMinutes;

  /// Max per-app daily usage (minutes).
  final int appLimitMinutes;

  /// Max unlocks per 24h.
  final int unlockLimit;

  /// Max continuous session (minutes).
  final int maxSessionMinutes;

  /// Hour after which phone use in the night counts as "sleeping hours".
  /// 1 means midnight+1h, i.e. use after 01:00 triggers the sleep metric.
  final int sleepCutoffHour;

  /// Hour before which opening social apps triggers the "wakeup" metric.
  final int wakeupHour;

  // ── Tier table (mirrors GoalThresholds.kt on the Kotlin side) ────────────

  // minimal=Light (relaxed), normal=Moderate, extensive=Intense (strict)
  static const Map<GoalLevel, GoalThresholds> byLevel = {
    GoalLevel.minimal: GoalThresholds(
      phoneLimitMinutes: 240,
      appLimitMinutes: 60,
      unlockLimit: 60,
      maxSessionMinutes: 20,
      sleepCutoffHour: 1,
      wakeupHour: 7,
    ),
    GoalLevel.normal: GoalThresholds(
      phoneLimitMinutes: 150,
      appLimitMinutes: 30,
      unlockLimit: 40,
      maxSessionMinutes: 10,
      sleepCutoffHour: 23,
      wakeupHour: 8,
    ),
    GoalLevel.extensive: GoalThresholds(
      phoneLimitMinutes: 90,
      appLimitMinutes: 15,
      unlockLimit: 25,
      maxSessionMinutes: 5,
      sleepCutoffHour: 21,
      wakeupHour: 9,
    ),
  };

  static GoalThresholds? forLevel(GoalLevel level) => byLevel[level];
}

/// Maps a raw int (0–3) from SharedPreferences to a [GoalLevel].
GoalLevel goalLevelFromInt(int v) => switch (v) {
      1 => GoalLevel.minimal,
      2 => GoalLevel.normal,
      3 => GoalLevel.extensive,
      _ => GoalLevel.none,
    };
