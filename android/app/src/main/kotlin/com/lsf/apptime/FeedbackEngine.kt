package com.lsf.apptime

import android.content.SharedPreferences
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.TextView

/**
 * Evaluates usage thresholds and drives personalized message (PM) display.
 * No animations — messages appear and disappear instantly.
 * Called every ~2.5 s by OverlayService (5 poll ticks × 500 ms).
 */
class FeedbackEngine(
    private val view: TextView,
    private val getViewAdded: () -> Boolean,
    private val setWindowWidth: (Int) -> Unit,
    private val getMaxWidthPx: () -> Int,
    private val getPrefs: () -> SharedPreferences,
    private val getAppLabel: (String) -> String,
) {
    var pmActive = false
        private set

    // ── Periodic schedules (wall-clock ms of next allowed show) ──────────────
    // 0 = not yet scheduled (first interval starts from the triggering event).
    private var nextPhoneShow   = 0L   // resets on each unlock
    private var nextAppShow     = 0L   // resets when current app changes
    private var nextSessionShow = 0L   // resets when current app changes
    private var nextSleepShow   = 0L   // resets when current app changes

    // ── One-shot per unlock ───────────────────────────────────────────────────
    private var nextWakeupShow        = 0L   // unlockTime + 10 s; 0 = not pending
    private var wakeupShownThisUnlock = false

    // ── Internal state ────────────────────────────────────────────────────────
    // -1 = uninitialized: the first evaluate() call seeds it without firing any
    // unlock-triggered events (avoids false positives on service start).
    private var lastUnlockCount = -1
    private var lastPkg         : String? = null
    private var pmEndTimeMs     = 0L
    // Enforces a 10 s quiet gap after a PM ends when the queue was empty.
    private var pauseUntilMs    = 0L
    private val pmQueue         = ArrayDeque<String>()

    companion object {
        private const val TAG      = "AppTimePM"
        const val PM_SHOW_MS       = 11_000L
        const val POST_PM_PAUSE_MS = 10_000L
        const val PHONE_INTERVAL   = 50_000L
        const val APP_INTERVAL     = 40_000L
        const val SESSION_INTERVAL = 30_000L
        const val SLEEP_INTERVAL   = 120_000L
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Public entry point — called every ~2.5 s by OverlayService
    // ─────────────────────────────────────────────────────────────────────────

    fun evaluate() {
        val prefs     = getPrefs()
        val goalLevel = prefs.safeGetCount("flutter.goal_level").toInt()

        if (goalLevel == 0) {
            Log.d(TAG, "evaluate: goalLevel=0, skipping")
            clearAll(); return
        }

        val pkg        = prefs.getString("flutter.current_pkg", null)
        val isLauncher = pkg != null && AppConstants.LAUNCHERS.contains(pkg)

        if (pkg != null && !isLauncher &&
            AppConstants.parseDisabledApps(prefs).contains(pkg)) {
            Log.d(TAG, "evaluate: pkg disabled, skipping")
            clearAll(); return
        }

        val thresholds = GoalThresholds.forLevel(goalLevel)
        val lang       = prefs.getString("flutter.language_code", "pt") ?: "pt"
        val date       = DateUtils.today()
        val hour       = DateUtils.currentHour()
        val now        = System.currentTimeMillis()

        val sessionStartMs = prefs.getLong("flutter.current_session_start_ms", now)
        // Live session time for the current foreground app (0 for launchers / no pkg).
        val sessionMs = if (pkg != null && !isLauncher) (now - sessionStartMs).coerceAtLeast(0L) else 0L

        // Add the in-flight session to stored totals so threshold checks are real-time.
        // MonitoringService only flushes to prefs on app switch or screen-off.
        val storedDeviceMs = prefs.getLong("flutter.device_daily_ms_$date", 0L)
        val storedAppMs    = if (pkg != null && !isLauncher)
                                 prefs.getLong("flutter.daily_ms_${pkg}_$date", 0L) else 0L
        val deviceMs = storedDeviceMs + sessionMs
        val appMs    = storedAppMs + sessionMs

        val appGoalLevel  = if (pkg != null && !isLauncher)
            prefs.safeGetCount("flutter.app_goal_$pkg").toInt()
                .let { if (it == 0) goalLevel else it }
        else goalLevel
        val appThresholds = GoalThresholds.forLevel(appGoalLevel)

        Log.d(TAG, "evaluate: pkg=$pkg goalLevel=$goalLevel " +
              "device=${deviceMs/60000}m app=${appMs/60000}m session=${sessionMs/60000}m")

        // ── App change → reset app-based schedules ─────────────────────────
        if (pkg != lastPkg) {
            Log.d(TAG, "app changed: $lastPkg → $pkg")
            lastPkg         = pkg
            nextAppShow     = now + APP_INTERVAL
            nextSessionShow = now + SESSION_INTERVAL
            nextSleepShow   = now + SLEEP_INTERVAL
        }

        // ── Unlock detection ───────────────────────────────────────────────
        val currentUnlocks = prefs.safeGetCount("flutter.unlock_count_$date").toInt()
        if (lastUnlockCount < 0) {
            Log.d(TAG, "first eval: seeding unlockCount=$currentUnlocks")
            lastUnlockCount = currentUnlocks
            nextPhoneShow   = now + PHONE_INTERVAL
        } else if (currentUnlocks > lastUnlockCount) {
            Log.d(TAG, "unlock: $lastUnlockCount→$currentUnlocks limit=${thresholds.unlockLimit}")
            lastUnlockCount       = currentUnlocks
            nextPhoneShow         = now + PHONE_INTERVAL
            wakeupShownThisUnlock = false

            if (currentUnlocks > thresholds.unlockLimit) {
                Log.d(TAG, "trigger: unlockExceeded")
                enqueue(PmMessages.unlockExceeded(lang))
            }

            val inWakeup = thresholds.wakeupHour > 0 && hour < thresholds.wakeupHour
            val isSocial = pkg != null && AppConstants.SOCIAL_PATTERNS.any { pkg.contains(it) }
            nextWakeupShow = if (inWakeup && isSocial) now + 10_000L else 0L
            Log.d(TAG, "wakeup: inWakeup=$inWakeup isSocial=$isSocial scheduled=$nextWakeupShow")
        }

        // ── Threshold flags ────────────────────────────────────────────────
        val phoneLimitHit = thresholds.phoneLimitMs > 0 && deviceMs >= thresholds.phoneLimitMs
        val appLimitHit   = appThresholds.appLimitMs > 0 && pkg != null && !isLauncher &&
                            appMs >= appThresholds.appLimitMs
        val sessionHit    = thresholds.maxSessionMs > 0 && pkg != null && !isLauncher &&
                            sessionMs >= thresholds.maxSessionMs
        val inSleepWindow = thresholds.sleepCutoffHour > 0 && pkg != null && !isLauncher && when {
            thresholds.sleepCutoffHour >= 18 -> hour >= thresholds.sleepCutoffHour || hour < 6
            else                             -> hour >= thresholds.sleepCutoffHour && hour < 6
        }
        val inWakeup      = thresholds.wakeupHour > 0 && hour < thresholds.wakeupHour
        val isSocial      = pkg != null && AppConstants.SOCIAL_PATTERNS.any { pkg.contains(it) }
        val wakeupPending = nextWakeupShow > 0 && !wakeupShownThisUnlock

        Log.d(TAG, "flags: phone=$phoneLimitHit app=$appLimitHit " +
              "session=$sessionHit sleep=$inSleepWindow " +
              "wakeup=${inWakeup && isSocial && wakeupPending} " +
              "unlock=${currentUnlocks > thresholds.unlockLimit}")
        Log.d(TAG, "next: phone=${(nextPhoneShow-now)/1000}s app=${(nextAppShow-now)/1000}s " +
              "session=${(nextSessionShow-now)/1000}s sleep=${(nextSleepShow-now)/1000}s " +
              "queue=${pmQueue.size} pmActive=$pmActive pauseLeft=${(pauseUntilMs-now).coerceAtLeast(0)/1000}s")

        // ── Enqueue periodic messages ──────────────────────────────────────
        if (phoneLimitHit && nextPhoneShow > 0 && now >= nextPhoneShow) {
            Log.d(TAG, "enqueue: phoneTimeExceeded")
            enqueue(PmMessages.phoneTimeExceeded(lang))
            nextPhoneShow = now + PHONE_INTERVAL
        }
        if (appLimitHit && nextAppShow > 0 && now >= nextAppShow) {
            Log.d(TAG, "enqueue: appLimitExceeded")
            enqueue(PmMessages.appLimitExceeded(lang, getAppLabel(pkg!!)))
            nextAppShow = now + APP_INTERVAL
        }
        if (sessionHit && nextSessionShow > 0 && now >= nextSessionShow) {
            Log.d(TAG, "enqueue: sessionExceeded")
            enqueue(PmMessages.sessionExceeded(lang))
            nextSessionShow = now + SESSION_INTERVAL
        }
        if (inSleepWindow && nextSleepShow > 0 && now >= nextSleepShow) {
            Log.d(TAG, "enqueue: sleepingHours")
            enqueue(PmMessages.sleepingHours(lang))
            nextSleepShow = now + SLEEP_INTERVAL
        }

        // ── Enqueue wakeup one-shot ────────────────────────────────────────
        if (wakeupPending && now >= nextWakeupShow && inWakeup && isSocial) {
            Log.d(TAG, "enqueue: wakeupSocial")
            enqueue(PmMessages.wakeupSocial(lang))
            wakeupShownThisUnlock = true
            nextWakeupShow = 0L
        }

        driveQueue(now)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Queue
    // ─────────────────────────────────────────────────────────────────────────

    private fun enqueue(message: String) {
        if (!pmQueue.contains(message)) {
            pmQueue.addLast(message)
            Log.d(TAG, "queued (size=${pmQueue.size}): \"${message.take(30)}\"")
        } else {
            Log.d(TAG, "enqueue: duplicate skipped")
        }
    }

    private fun driveQueue(now: Long) {
        if (pmActive) {
            if (now < pmEndTimeMs) return   // still showing, nothing to do
            // PM expired — hide it and immediately fall through to show next if queued.
            hidePm(now)
        }
        // pmActive is now false (either it was already false, or we just hid it).
        if (pmQueue.isEmpty()) return
        if (!getViewAdded()) {
            Log.d(TAG, "driveQueue: view not added")
            return
        }
        if (now < pauseUntilMs) {
            Log.d(TAG, "driveQueue: quiet gap ${(pauseUntilMs-now)/1000}s left")
            return
        }
        if (!getPrefs().getBoolean("flutter.overlay_enabled", true)) {
            Log.d(TAG, "driveQueue: overlay disabled")
            return
        }
        val msg = pmQueue.removeFirst()
        Log.d(TAG, "showPm (${pmQueue.size} remaining): \"${msg.take(40)}\"")
        showPm(msg)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Display — no animations, instant show/hide
    // ─────────────────────────────────────────────────────────────────────────

    private fun showPm(message: String) {
        pmActive    = true
        pmEndTimeMs = System.currentTimeMillis() + PM_SHOW_MS
        // Width is expanded here; it is restored by OverlayService.updateOverlay()
        // AFTER it writes the timer text, so the short text is in place before the
        // window shrinks — preventing any visible reflow of the long PM content.
        setWindowWidth(getMaxWidthPx())
        view.text       = message
        view.visibility = View.VISIBLE
        view.alpha      = 1f
    }

    private fun hidePm(now: Long) {
        pmActive = false
        // Do NOT call setWindowWidth here. The width is still at maxWidthPx with
        // PM text in it. OverlayService.updateOverlay() will write the short timer
        // text first, then shrink the window — no reflow artifact.
        if (pmQueue.isEmpty()) {
            pauseUntilMs = now + POST_PM_PAUSE_MS
            Log.d(TAG, "hidePm: queue empty → quiet gap ${POST_PM_PAUSE_MS/1000}s")
        } else {
            Log.d(TAG, "hidePm: ${pmQueue.size} queued → show next immediately")
        }
    }

    private fun clearAll() {
        pmQueue.clear()
        if (pmActive) hidePm(System.currentTimeMillis())
        nextPhoneShow   = 0L
        nextAppShow     = 0L
        nextSessionShow = 0L
        nextSleepShow   = 0L
        nextWakeupShow  = 0L
        pauseUntilMs    = 0L
    }
}
