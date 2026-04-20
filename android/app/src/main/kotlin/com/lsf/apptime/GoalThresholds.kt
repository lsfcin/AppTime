package com.lsf.apptime

/**
 * Mirror of lib/models/goal_config.dart — must stay in sync.
 * goal_level pref: 0=none  1=minimal  2=normal  3=extensive
 */
data class GoalThresholds(
    val phoneLimitMinutes: Int,
    val appLimitMinutes: Int,
    val unlockLimit: Int,
    val maxSessionMinutes: Int,
    /** Hour after which night use triggers the sleep metric (21, 23, or 1). */
    val sleepCutoffHour: Int,
    /** Hour before which social apps on wakeup trigger the wakeup metric. */
    val wakeupHour: Int
) {
    val phoneLimitMs: Long get() = phoneLimitMinutes * 60_000L
    val appLimitMs: Long get() = appLimitMinutes * 60_000L
    val maxSessionMs: Long get() = maxSessionMinutes * 60_000L

    companion object {
        val NONE = GoalThresholds(
            phoneLimitMinutes = Int.MAX_VALUE,
            appLimitMinutes   = Int.MAX_VALUE,
            unlockLimit       = Int.MAX_VALUE,
            maxSessionMinutes = Int.MAX_VALUE,
            sleepCutoffHour   = 0,
            wakeupHour        = 0
        )

        fun forLevel(level: Int): GoalThresholds = when (level) {
            1 -> GoalThresholds(90,  15, 25,  5, 21, 9)
            2 -> GoalThresholds(150, 30, 40, 10, 23, 8)
            3 -> GoalThresholds(240, 60, 60, 20,  1, 7)
            else -> NONE
        }
    }
}
