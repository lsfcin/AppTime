package com.lsf.apptime

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class MonitoringService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var prefs: SharedPreferences

    private var lastPackage: String? = null
    private var sessionStartMs: Long = 0L
    private var watchdogTick = 0
    private var lastDate: String = ""
    private var lastPruneDate: String = ""

    // Timestamp of the most recent ACTION_USER_PRESENT (unlock). Used to
    // determine whether a launcher session started via direct unlock or via
    // home/back button press.
    private var lastUnlockMs: Long = 0L

    // Key used to persist the last-alive timestamp so gap detection survives
    // process death (service killed, device reboot, crash, etc.)
    private val HEARTBEAT_KEY = "flutter.monitoring_heartbeat_ms"
    // Maximum gap before we consider the period unmonitored and attempt backfill.
    // 10s covers normal poll jitter; anything larger is a real gap.
    private val GAP_THRESHOLD_MS = 10_000L

    // Reopening tolerance: if the same app returns within this window, don't
    // count it as a new open (covers copy-paste flows, permission dialogs, etc.)
    // 120 s aligns with common session-gap thresholds in mobile UX research.
    private var lastClosedPkg: String? = null
    private var lastClosedMs: Long = 0L
    private val REOPEN_TOLERANCE_MS = 120_000L

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    // Immediately flush the active session when screen turns off
                    if (lastPackage != null) {
                        accumulateDailyMs(lastPackage!!, sessionStartMs, System.currentTimeMillis())
                        lastPackage = null
                    }
                    prefs.edit()
                        .putString("flutter.overlay_text", "")
                        .putBoolean("flutter.overlay_visible", false)
                        .remove("flutter.current_pkg")
                        .apply()
                }
                Intent.ACTION_USER_PRESENT -> {
                    lastUnlockMs = System.currentTimeMillis()
                    val date = today()
                    val hour = currentHour()
                    val key = "flutter.unlock_count_${date}"
                    prefs.edit().putLong(key, prefs.safeGetCount(key) + 1).apply()
                    val hourKey = "flutter.hourly_unlocks_${date}_${hour}"
                    prefs.edit().putLong(hourKey, prefs.safeGetCount(hourKey) + 1).apply()
                }
            }
        }
    }

    private val pollRunnable = object : Runnable {
        override fun run() {
            tick()
            handler.postDelayed(this, 1_000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())
        usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        lastDate = today()
        migrateCorruptedDeviceDaily()
        val screenFilter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, screenFilter)
        backfillGap()
        handler.post(pollRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(pollRunnable)
        try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        prefs.edit()
            .putBoolean("flutter.overlay_visible", false)
            .apply()
        super.onDestroy()
    }

    private fun tick() {
        // Heartbeat: record the current time so gap detection can measure how
        // long the service was inactive if it gets killed and restarted later.
        prefs.edit().putLong(HEARTBEAT_KEY, System.currentTimeMillis()).apply()

        // Watchdog: restart OverlayService every 30s in case it was killed
        if (++watchdogTick >= 30) {
            watchdogTick = 0
            startService(Intent(this, OverlayService::class.java))
        }

        // Day rollover: flush the active session so pre-4am usage isn't
        // attributed to the new day. The in-flight duration is discarded
        // (bounded loss: at most one session's worth of ms, typically seconds).
        val currentDate = today()
        if (currentDate != lastDate) {
            lastPackage = null
            lastDate = currentDate
            // Prune data older than 31 days once per new day
            if (currentDate != lastPruneDate) {
                lastPruneDate = currentDate
                pruneOldData()
            }
        }

        // Short-circuit when screen is off — screenReceiver handles the flush;
        // PowerManager check guards against edge cases (e.g. first tick after boot).
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) return

        // getCurrentApp() queries only the last 60s of UsageEvents. If the user has been
        // in the same app for >60s with no new fg event, it returns null — but the screen
        // IS on (guarded above), so fall back to the last known foreground package.
        // Session close only happens via ACTION_SCREEN_OFF (immediate flush) or an actual
        // app switch detected below.
        val current = getCurrentApp() ?: lastPackage

        if (current == null) {
            // Screen on but no app ever recorded yet — nothing to show.
            prefs.edit()
                .putString("flutter.overlay_text", "")
                .putBoolean("flutter.overlay_visible", false)
                .remove("flutter.current_pkg")
                .apply()
            return
        }

        val isLauncher = LAUNCHERS.contains(current)

        if (current != lastPackage) {
            // App switch — close previous session, open new one
            val now = System.currentTimeMillis()
            if (lastPackage != null) {
                accumulateDailyMs(lastPackage!!, sessionStartMs, now)
                lastClosedPkg = lastPackage
                lastClosedMs  = now
            }
            lastPackage = current
            sessionStartMs = now
            val isReturn = current == lastClosedPkg && (now - lastClosedMs) < REOPEN_TOLERANCE_MS
            if (!isLauncher && !isReturn) incrementOpenCount(current)
        }

        // ── Per-app overlay visibility ──────────────────────────────────────
        val disabledApps = parseDisabledApps(prefs)
        val monitorLauncher = prefs.getBoolean("flutter.monitor_launcher", true)
        val overlayHidden = disabledApps.contains(current) || (isLauncher && !monitorLauncher)

        if (overlayHidden) {
            // Still track time and session, but don't show overlay
            prefs.edit()
                .putString("flutter.overlay_text", "")
                .putBoolean("flutter.overlay_visible", false)
                .putString("flutter.current_pkg", current)
                .putLong("flutter.current_session_start_ms", sessionStartMs)
                .apply()
            return
        }

        val overlayText = when {
            isLauncher -> {
                val unlocks = getUnlockCount()
                // Add live launcher session so the counter updates every tick (not frozen)
                val storedMs = getDeviceDailyMs()
                val liveMs = storedMs + (System.currentTimeMillis() - sessionStartMs)
                val elapsed = System.currentTimeMillis() - sessionStartMs
                // Only show unlock count if user landed on launcher directly from an unlock
                // (ACTION_USER_PRESENT fired within 5s before this session started).
                // Home/back-button transitions skip the count and wait 5s before showing time.
                val directUnlockToLauncher = lastUnlockMs > 0L &&
                    (sessionStartMs - lastUnlockMs) < 5_000L
                when {
                    directUnlockToLauncher && elapsed < 5_000L -> "$unlocks×"
                    elapsed < 5_000L -> ""   // suppress during 5s delay for home/back transitions
                    else -> formatTime(liveMs)
                }
            }
            else -> {
                val ms = getDailyMs(current) + (System.currentTimeMillis() - sessionStartMs)
                formatTime(ms)
            }
        }

        prefs.edit()
            .putString("flutter.overlay_text", overlayText)
            .putBoolean("flutter.overlay_visible", true)
            // Expose raw values for OverlayService feedback evaluation
            .putString("flutter.current_pkg", current)
            .putLong("flutter.current_session_start_ms", sessionStartMs)
            .apply()
    }

    /**
     * Fills in any usage data for the period when the service was not running.
     *
     * On service start we compare [now] against the last heartbeat written by
     * [tick]. If the gap exceeds [GAP_THRESHOLD_MS] we replay the UsageEvents
     * for that window and accumulate daily/hourly ms for every foreground app
     * that appeared during the gap (launchers excluded from daily totals, same
     * as normal monitoring).
     */
    private fun backfillGap() {
        val lastHeartbeat = prefs.getLong(HEARTBEAT_KEY, 0L)
        val now = System.currentTimeMillis()
        if (lastHeartbeat == 0L || (now - lastHeartbeat) < GAP_THRESHOLD_MS) return

        val gapStart = lastHeartbeat
        val gapEnd   = now

        val events = usageStatsManager.queryEvents(gapStart, gapEnd)
        val event  = UsageEvents.Event()

        data class Seg(val pkg: String, val startMs: Long, val endMs: Long)
        val segments = mutableListOf<Seg>()
        var lastFgPkg: String? = null
        var lastFgTs:  Long   = gapStart

        while (events.getNextEvent(event)) {
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    // Close previous segment if any
                    if (lastFgPkg != null && event.timeStamp > lastFgTs) {
                        segments += Seg(lastFgPkg!!, lastFgTs, event.timeStamp)
                    }
                    lastFgPkg = event.packageName
                    lastFgTs  = event.timeStamp
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND,
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    if (lastFgPkg != null && event.timeStamp > lastFgTs) {
                        segments += Seg(lastFgPkg!!, lastFgTs, event.timeStamp)
                        lastFgPkg = null
                    }
                }
            }
        }
        // Close any still-open segment at gap end
        if (lastFgPkg != null && gapEnd > lastFgTs) {
            segments += Seg(lastFgPkg!!, lastFgTs, gapEnd)
        }

        for (seg in segments) {
            accumulateDailyMs(seg.pkg, seg.startMs, seg.endMs)
        }
    }

    private fun getCurrentApp(): String? {
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(now - 60_000, now)
        val event = UsageEvents.Event()
        var lastFg: String? = null
        var lastTs = 0L

        while (events.getNextEvent(event)) {
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (event.timeStamp > lastTs) {
                        lastFg = event.packageName
                        lastTs = event.timeStamp
                    }
                }
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    // Tela apagou — sem app em foco
                    if (event.timeStamp > lastTs) {
                        lastFg = null
                        lastTs = event.timeStamp
                    }
                }
            }
        }
        return lastFg
    }

    // ── Banco de sessões ──────────────────────────────────────────────────────

    private fun today(): String {
        // The "day" starts at 04:00 — hours 00–03 belong to the previous calendar day.
        val c = java.util.Calendar.getInstance()
        if (c.get(java.util.Calendar.HOUR_OF_DAY) < 4) c.add(java.util.Calendar.DATE, -1)
        return "%04d-%02d-%02d".format(c.get(java.util.Calendar.YEAR),
            c.get(java.util.Calendar.MONTH) + 1, c.get(java.util.Calendar.DAY_OF_MONTH))
    }

    private fun currentHour(): Int =
        java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)

    /** Returns the 4am-anchored date key (YYYY-MM-DD) for the given epoch ms. */
    private fun epochToDateKey(epochMs: Long): String {
        val c = java.util.Calendar.getInstance().apply { timeInMillis = epochMs }
        if (c.get(java.util.Calendar.HOUR_OF_DAY) < 4) c.add(java.util.Calendar.DATE, -1)
        return "%04d-%02d-%02d".format(
            c.get(java.util.Calendar.YEAR),
            c.get(java.util.Calendar.MONTH) + 1,
            c.get(java.util.Calendar.DAY_OF_MONTH)
        )
    }

    /**
     * Splits the session [startMs, endMs) across hour (and 4am-day) boundaries so that
     * each hourly_ms bucket only receives the milliseconds that actually fell within it.
     * Daily totals are attributed to the end-of-session date (same behaviour as before).
     */
    private fun accumulateDailyMs(pkg: String, startMs: Long, endMs: Long) {
        val duration = endMs - startMs
        if (duration <= 0L) return

        // Daily totals — attributed to the day that contains the session end
        val endDate = epochToDateKey(endMs)
        val dailyKey = "flutter.daily_ms_${pkg}_${endDate}"
        prefs.edit().putLong(dailyKey, prefs.getLong(dailyKey, 0L) + duration).apply()
        val deviceDailyKey = "flutter.device_daily_ms_${endDate}"
        prefs.edit().putLong(deviceDailyKey, prefs.getLong(deviceDailyKey, 0L) + duration).apply()

        // Hourly breakdown — walk from startMs to endMs in hour-boundary steps
        var cursor = startMs
        while (cursor < endMs) {
            val cal = java.util.Calendar.getInstance().apply { timeInMillis = cursor }
            val hour = cal.get(java.util.Calendar.HOUR_OF_DAY)
            val date = epochToDateKey(cursor)

            // Start of next hour
            val nextHourCal = java.util.Calendar.getInstance().apply {
                timeInMillis = cursor
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
                add(java.util.Calendar.HOUR_OF_DAY, 1)
            }
            val chunkEnd = minOf(nextHourCal.timeInMillis, endMs)
            val chunkMs  = chunkEnd - cursor

            val hourKey = "flutter.hourly_ms_${pkg}_${date}_${hour}"
            prefs.edit().putLong(hourKey, prefs.getLong(hourKey, 0L) + chunkMs).apply()
            val deviceHourKey = "flutter.device_hourly_ms_${date}_${hour}"
            prefs.edit().putLong(deviceHourKey, prefs.getLong(deviceHourKey, 0L) + chunkMs).apply()

            cursor = chunkEnd
        }

        // Session duration bucket (based on total duration, attributed to end date)
        val bucketIdx = when {
            duration < 60_000L  -> 0   // < 1 min
            duration < 300_000L -> 1   // 1–5 min
            duration < 900_000L -> 2   // 5–15 min
            else                -> 3   // > 15 min
        }
        val bucketKey = "flutter.session_bucket_${bucketIdx}_${endDate}"
        prefs.edit().putLong(bucketKey, prefs.safeGetCount(bucketKey) + 1).apply()
    }

    private fun incrementOpenCount(pkg: String) {
        val date = today()
        val hour = currentHour()
        val key = "flutter.open_count_${pkg}_${date}"
        prefs.edit().putLong(key, prefs.safeGetCount(key) + 1).apply()
        val hourKey = "flutter.hourly_opens_${pkg}_${date}_${hour}"
        prefs.edit().putLong(hourKey, prefs.safeGetCount(hourKey) + 1).apply()
    }

    private fun getDailyMs(pkg: String): Long =
        prefs.getLong("flutter.daily_ms_${pkg}_${today()}", 0L)

    private fun getOpenCount(pkg: String): Int =
        prefs.safeGetCount("flutter.open_count_${pkg}_${today()}").toInt()

    private fun getUnlockCount(): Int =
        prefs.safeGetCount("flutter.unlock_count_${today()}").toInt()

    private fun getDeviceDailyMs(): Long =
        prefs.getLong("flutter.device_daily_ms_${today()}", 0L)

    // ── Formatação ────────────────────────────────────────────────────────────

    private fun formatTime(ms: Long): String {
        val totalSec = ms / 1000
        val hours = totalSec / 3600
        val mins = (totalSec % 3600) / 60
        val secs = totalSec % 60
        return if (hours > 0) "%d:%02d:%02d".format(hours, mins, secs)
               else "%d:%02d".format(mins, secs)
    }

    // ── Notificação ───────────────────────────────────────────────────────────

    private fun buildNotification(): Notification {
        val channelId = "apptime_monitoring"
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(channelId) == null) {
            manager.createNotificationChannel(
                NotificationChannel(channelId, "AppTime Monitoramento",
                    NotificationManager.IMPORTANCE_MIN)
            )
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("AppTime monitorando")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
    }

    /** One-time migration: reset device_daily_ms_{today} if it exceeds 23 hours.
     *  The old rolling-24h logic could accumulate two calendar-days of data into a
     *  single key, producing impossible values. Any value ≥ 23h is corrupted.
     */
    private fun migrateCorruptedDeviceDaily() {
        val key = "flutter.device_daily_ms_${today()}"
        val value = prefs.getLong(key, 0L)
        if (value >= 23 * 3_600_000L) {
            prefs.edit().remove(key).apply()
        }
    }

    /** Remove all date-keyed SharedPreferences entries older than 31 days.
     *  Keys that embed a YYYY-MM-DD substring are matched and cleaned up.
     *  This keeps storage bounded while guaranteeing 30+ days of history.
     */
    private fun pruneOldData() {
        val cutoff = java.util.Calendar.getInstance().apply {
            add(java.util.Calendar.DATE, -31)
            if (get(java.util.Calendar.HOUR_OF_DAY) < 4) add(java.util.Calendar.DATE, -1)
        }
        val cutoffStr = "%04d-%02d-%02d".format(
            cutoff.get(java.util.Calendar.YEAR),
            cutoff.get(java.util.Calendar.MONTH) + 1,
            cutoff.get(java.util.Calendar.DAY_OF_MONTH)
        )
        val dateRegex = Regex("""(\d{4}-\d{2}-\d{2})""")
        val editor = prefs.edit()
        for (key in prefs.all.keys) {
            val match = dateRegex.find(key) ?: continue
            if (match.value <= cutoffStr) editor.remove(key)
        }
        editor.apply()
    }

    /** Read a counter written by either putLong (new) or putInt (legacy data). */
    private fun SharedPreferences.safeGetCount(key: String): Long =
        try { getLong(key, 0L) } catch (_: ClassCastException) { getInt(key, 0).toLong() }

    companion object {
        /** Parse the disabled-apps set stored by Flutter as a plain JSON string via setString(). */
        fun parseDisabledApps(prefs: android.content.SharedPreferences): Set<String> {
            val raw = prefs.getString("flutter.disabled_apps", null) ?: return emptySet()
            return try {
                val arr = org.json.JSONArray(raw)
                (0 until arr.length())
                    .map { arr.getString(it) }
                    .filter { it.isNotEmpty() && it.matches(Regex("[a-zA-Z0-9_.]+")) }
                    .toSet()
            } catch (_: Exception) { emptySet() }
        }


        const val NOTIF_ID = 1002

        val LAUNCHERS = setOf(
            "com.google.android.apps.nexuslauncher",
            "com.sec.android.app.launcher",
            "com.miui.home",
            "com.android.launcher",
            "com.android.launcher3",
            "com.huawei.android.launcher",
            "com.oneplus.launcher",
            "com.google.android.googlequicksearchbox",
        )
    }
}
