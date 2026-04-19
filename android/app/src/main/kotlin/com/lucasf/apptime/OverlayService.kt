package com.lucasf.apptime

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.TextView
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    // ── Regular overlay (tiny counter in status-bar zone) ─────────────────────
    private lateinit var overlayView: TextView
    private val handler = Handler(Looper.getMainLooper())
    private var isViewAdded = false

    // ── F.PM — personalized message shown inside the regular overlay ─────────
    private var pmActive = false
    private var pmJustEnded = false       // triggers fade-in after PM fade-out
    private var pmCooldownUntil = 0L

    // ── F.BN — breathing-nudge state ──────────────────────────────────────────
    private var breathingActive = false
    private var breathingAnimator: ObjectAnimator? = null  // only for breathing
    private var pmAnimator: ObjectAnimator? = null          // only for PM

    // ── F.VW — visual weight: stored as multiplier, applied via font size ─────
    // Using font-size scaling instead of scaleX/scaleY keeps the window and
    // GradientDrawable corners correctly sized at all times.
    private var visualWeightMult: Float = 1f

    // ── Unlock tracking for F.PM-on-unlock ───────────────────────────────────
    private var lastSeenUnlockCount = 0

    // ── Feedback evaluation every 5 poll ticks (~2.5 s) ──────────────────────
    private var evalTick = 0

    // ── Max overlay width in px (set once in addOverlayView) ─────────────────
    private var maxWidthPx = 0

    // ── Delayed show — avoid blink on app switch ──────────────────────────────
    // ── Slide suppression — only reposition window when y actually changes ────
    private var lastTopY = -1

    // ── Poll loop ─────────────────────────────────────────────────────────────
    private val pollRunnable = object : Runnable {
        override fun run() {
            updateOverlay()
            if (++evalTick >= 5) {
                evalTick = 0
                evaluateFeedbacks()
            }
            handler.postDelayed(this, 500)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())
        if (!isViewAdded) addOverlayView()
        handler.removeCallbacks(pollRunnable)
        handler.post(pollRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        if (isViewAdded) {
            try { windowManager.removeView(overlayView) } catch (_: Exception) {}
            isViewAdded = false
        }
        super.onDestroy()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Regular overlay (counter)
    // ─────────────────────────────────────────────────────────────────────────

    private val windowManager by lazy { getSystemService(WINDOW_SERVICE) as WindowManager }

    private fun addOverlayView() {
        val screenWidthPx = resources.displayMetrics.widthPixels
        maxWidthPx = (screenWidthPx * 0.88f).toInt()

        overlayView = TextView(this).apply {
            text = ""
            textSize = 14f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            setShadowLayer(3f, 1f, 1f, Color.BLACK)
            setPadding(16, 8, 16, 8)
            maxWidth = maxWidthPx
            setSingleLine(false)
            // Always 1:1 — visual weight is expressed via font size, not scale
            scaleX = 1f
            scaleY = 1f
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = 0
            y = 120
        }
        try {
            windowManager.addView(overlayView, params)
            isViewAdded = true
        } catch (e: Exception) {
            isViewAdded = false
        }
    }

    private fun updateOverlay() {
        if (!isViewAdded) return
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val showBg     = prefs.getBoolean("flutter.overlay_show_background", false)
        val showBorder = prefs.getBoolean("flutter.overlay_show_border", false)
        val topDp      = readFloat(prefs, "flutter.overlay_top_dp", 40f).coerceIn(0f, 800f)
        val density    = resources.displayMetrics.density

        // Font size stored as Int for cross-process reliability;
        // fall back to readFloat for any existing Float/Double legacy data.
        // Flutter shared_preferences stores int as Long on Android; use getLong().toInt().
        val fontSizeBase = run {
            val asLong = try { prefs.getLong("flutter.overlay_font_size", 0L) }
                         catch (_: ClassCastException) { 0L }
            if (asLong > 0L) asLong.toFloat()
            else readFloat(prefs, "flutter.overlay_font_size", 14f)
        }.coerceIn(10f, 30f)

        val fontSize = fontSizeBase * visualWeightMult

        overlayView.textSize = fontSize
        overlayView.scaleX = 1f   // never use view scale — font size does the work
        overlayView.scaleY = 1f

        val bg = GradientDrawable().apply {
            cornerRadius = 8f * density
            setColor(if (showBg) Color.argb(160, 0, 0, 0) else Color.TRANSPARENT)
            if (showBorder) setStroke((1.5f * density).toInt(), Color.WHITE)
        }
        overlayView.background = bg

        // Only reposition the window when y actually changed — calling
        // updateViewLayout every tick causes the OS to re-center WRAP_CONTENT
        // width on each frame, producing a subtle lateral slide.
        if (!pmActive) {
            try {
                val lp = overlayView.layoutParams as WindowManager.LayoutParams
                val newY = (topDp * density).toInt()
                if (newY != lastTopY) {
                    lp.y = newY
                    lastTopY = newY
                    windowManager.updateViewLayout(overlayView, lp)
                }
            } catch (_: Exception) {
                isViewAdded = false
                return
            }
        }

        if (pmActive) return   // PM owns text and visibility

        val text           = prefs.getString("flutter.overlay_text", "") ?: ""
        val visible        = prefs.getBoolean("flutter.overlay_visible", false)
        val overlayEnabled = prefs.getBoolean("flutter.overlay_enabled", true)
        val currentPkg    = prefs.getString("flutter.current_pkg", null)
        val isUnmonitored = currentPkg != null &&
            MonitoringService.parseDisabledApps(prefs).contains(currentPkg)
        val shouldShow    = overlayEnabled && visible && text.isNotEmpty() && !isUnmonitored

        overlayView.text = text
        overlayView.alpha = 1f
        overlayView.visibility = if (shouldShow) View.VISIBLE else View.INVISIBLE

        if (pmJustEnded && shouldShow) {
            pmJustEnded = false
            animatePm(overlayView, 0f, 1f, 500L) {}
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Feedback evaluation
    // ─────────────────────────────────────────────────────────────────────────

    private fun evaluateFeedbacks() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val goalLevel = prefs.safeGetCount("flutter.goal_level").toInt()

        if (goalLevel == 0) {
            stopBreathing()
            resetVisualWeight()
            return
        }

        val pkg = prefs.getString("flutter.current_pkg", null)
        val isLauncher = pkg != null && MonitoringService.LAUNCHERS.contains(pkg)

        // Skip all feedback for apps the user marked as unmonitored.
        if (pkg != null && !isLauncher &&
            MonitoringService.parseDisabledApps(prefs).contains(pkg)) {
            stopBreathing()
            resetVisualWeight()
            return
        }

        val thresholds = GoalThresholds.forLevel(goalLevel)
        val lang = prefs.getString("flutter.language_code", "pt") ?: "pt"
        val date = today()
        val hour = currentHour()
        val now  = System.currentTimeMillis()
        val sessionStartMs = prefs.getLong("flutter.current_session_start_ms", now)
        val sessionMs = if (pkg != null) (now - sessionStartMs).coerceAtLeast(0L) else 0L

        val deviceMs  = prefs.getLong("flutter.device_daily_ms_$date", 0L)
        val unlocks   = prefs.safeGetCount("flutter.unlock_count_$date").toInt()
        val appMs     = if (pkg != null && !isLauncher)
            prefs.getLong("flutter.daily_ms_${pkg}_$date", 0L) else 0L

        val appGoalLevel = if (pkg != null && !isLauncher)
            prefs.safeGetCount("flutter.app_goal_$pkg").toInt()
                .let { if (it == 0) goalLevel else it }
        else goalLevel
        val appThresholds = GoalThresholds.forLevel(appGoalLevel)

        val phonePct   = if (thresholds.phoneLimitMs > 0)
            (deviceMs  * 100 / thresholds.phoneLimitMs).toInt()  else 0
        val appPct     = if (appThresholds.appLimitMs > 0 && pkg != null && !isLauncher)
            (appMs     * 100 / appThresholds.appLimitMs).toInt() else 0
        val sessionPct = if (thresholds.maxSessionMs > 0 && pkg != null && !isLauncher)
            (sessionMs * 100 / thresholds.maxSessionMs).toInt()  else 0

        val inSleepWindow  = (thresholds.sleepCutoffHour > 0) && when {
            thresholds.sleepCutoffHour >= 18 -> hour >= thresholds.sleepCutoffHour || hour < 6
            else -> hour >= thresholds.sleepCutoffHour && hour < 6
        }
        val inWakeupWindow = (thresholds.wakeupHour > 0) && (hour < thresholds.wakeupHour)
        val isSocialApp    = pkg != null && SOCIAL_PATTERNS.any { pkg.contains(it) }

        var wantBn = false
        var wantVw = false
        var maxPct = 0
        var pmMessage: String? = null

        if (phonePct >= 100) {
            wantBn = true; maxPct = maxOf(maxPct, phonePct)
            if (phonePct >= 200) { wantVw = true; pmMessage = pmMessage ?: PmMessages.phoneTimeExceeded(lang) }
        }
        if (appPct >= 100 && pkg != null && !isLauncher) {
            wantBn = true; maxPct = maxOf(maxPct, appPct)
            if (appPct >= 200) {
                wantVw = true
                pmMessage = pmMessage ?: PmMessages.appLimitExceeded(lang, pkg.split(".").last())
            }
        }
        if (sessionPct >= 100 && pkg != null && !isLauncher) {
            wantBn = true; maxPct = maxOf(maxPct, sessionPct)
            if (sessionPct >= 200) { wantVw = true; pmMessage = pmMessage ?: PmMessages.sessionExceeded(lang) }
        }
        if (inSleepWindow && pkg != null && !isLauncher) {
            wantVw = true
            pmMessage = pmMessage ?: PmMessages.sleepingHours(lang)
        }
        if (inWakeupWindow && isSocialApp) {
            wantVw = true
            pmMessage = pmMessage ?: PmMessages.wakeupSocial(lang)
        }

        val currentUnlocks = prefs.safeGetCount("flutter.unlock_count_$date").toInt()
        if (currentUnlocks > lastSeenUnlockCount) {
            lastSeenUnlockCount = currentUnlocks
            if (currentUnlocks > thresholds.unlockLimit) {
                val msg = PmMessages.unlockExceeded(lang)
                handler.postDelayed({ triggerPm(msg) }, 3_000L)
            }
        }

        if (wantBn) startBreathing() else stopBreathing()
        if (wantVw) applyVisualWeight(maxPct) else resetVisualWeight()
        if (pmMessage != null) triggerPm(pmMessage)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // F.BN — Breathing Nudge
    // ─────────────────────────────────────────────────────────────────────────

    private fun startBreathing() {
        if (breathingActive || pmActive) return
        breathingActive = true
        scheduleBreathe()
    }

    private fun stopBreathing() {
        breathingActive = false
        if (!pmActive) {
            breathingAnimator?.cancel()
            breathingAnimator = null
            if (isViewAdded && !pmJustEnded) overlayView.alpha = 1f
        }
    }

    private fun scheduleBreathe() {
        if (!breathingActive || !isViewAdded || pmActive) return
        val fadeOutMs = (2_000L..3_000L).random()
        val dimMs     = (3_000L..6_000L).random()
        val fadeInMs  = (2_000L..3_000L).random()

        animateBreathe(overlayView, 1f, DIM_ALPHA, fadeOutMs) {
            handler.postDelayed({
                if (!breathingActive || pmActive) return@postDelayed
                animateBreathe(overlayView, DIM_ALPHA, 1f, fadeInMs) {
                    if (breathingActive) scheduleBreathe()
                }
            }, dimMs)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // F.VW — Visual Weight (via font size, not view scale)
    // ─────────────────────────────────────────────────────────────────────────

    private fun applyVisualWeight(pct: Int) {
        // 80% → 1.0×  …  100% → 1.2×  …  200% → 1.5× (capped)
        val newMult = (1f + ((pct - 80).coerceAtLeast(0) * 0.007f)).coerceAtMost(1.5f)
        visualWeightMult = newMult
        // updateOverlay() next tick will apply the new font size
    }

    private fun resetVisualWeight() {
        visualWeightMult = 1f
    }

    // ─────────────────────────────────────────────────────────────────────────
    // F.PM — Personalized Message
    // ─────────────────────────────────────────────────────────────────────────

    private fun triggerPm(message: String) {
        val now = System.currentTimeMillis()
        if (now < pmCooldownUntil) return
        if (pmActive) return
        if (!isViewAdded) return
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.overlay_enabled", true)) return

        pmActive = true
        pmCooldownUntil = now + 60_000L
        breathingActive = false
        breathingAnimator?.cancel()
        breathingAnimator = null

        val fontSizeBase = run {
            val asLong = try { prefs.getLong("flutter.overlay_font_size", 0L) }
                         catch (_: ClassCastException) { 0L }
            if (asLong > 0L) asLong.toFloat()
            else readFloat(prefs, "flutter.overlay_font_size", 14f)
        }.coerceIn(10f, 30f)

        val pmFontSize = (fontSizeBase - 2f).coerceAtLeast(11f)

        // Widen the window so multi-line PM text isn't cropped
        setWindowWidth(maxWidthPx)

        // Phase 1: fade out the current timer (from whatever alpha it currently has)
        val startAlpha = if (overlayView.visibility == View.VISIBLE) overlayView.alpha else 0f
        animatePm(overlayView, startAlpha, 0f, 400L) {
            // Phase 2: swap content
            overlayView.textSize = pmFontSize
            overlayView.text = message
            overlayView.visibility = View.VISIBLE
            // Phase 3: fade in PM
            animatePm(overlayView, 0f, 1f, 800L) {
                // Phase 4: hold for 20 s
                handler.postDelayed({
                    if (!pmActive) return@postDelayed
                    // Phase 5: fade out PM
                    animatePm(overlayView, 1f, 0f, 800L) {
                        // Phase 6: restore timer mode
                        overlayView.textSize = fontSizeBase
                        setWindowWidth(WindowManager.LayoutParams.WRAP_CONTENT)
                        pmActive = false
                        pmJustEnded = true
                        // alpha stays 0; updateOverlay() will fade timer back in
                    }
                }, 20_000L)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Animation helpers — SEPARATE animators for breathing vs PM so they
    // never cancel each other.
    // ─────────────────────────────────────────────────────────────────────────

    /** Breathing-nudge animator — cancelled if breathing stops. */
    private fun animateBreathe(view: View, from: Float, to: Float,
                               durationMs: Long, onEnd: () -> Unit) {
        breathingAnimator?.cancel()
        var cancelled = false
        breathingAnimator = ObjectAnimator.ofFloat(view, View.ALPHA, from, to).apply {
            duration = durationMs
            interpolator = AccelerateDecelerateInterpolator()
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(a: Animator) {
                    if (a == breathingAnimator) breathingAnimator = null
                    if (!cancelled) onEnd()
                }
                override fun onAnimationCancel(a: Animator) {
                    if (a == breathingAnimator) breathingAnimator = null
                    cancelled = true
                }
            })
            start()
        }
    }

    /** PM animator — never cancelled by breathing logic. */
    private fun animatePm(view: View, from: Float, to: Float,
                          durationMs: Long, onEnd: () -> Unit) {
        pmAnimator?.cancel()
        var cancelled = false
        pmAnimator = ObjectAnimator.ofFloat(view, View.ALPHA, from, to).apply {
            duration = durationMs
            interpolator = AccelerateDecelerateInterpolator()
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(a: Animator) {
                    if (a == pmAnimator) pmAnimator = null
                    if (!cancelled) onEnd()
                }
                override fun onAnimationCancel(a: Animator) {
                    if (a == pmAnimator) pmAnimator = null
                    cancelled = true
                }
            })
            start()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Window width helper
    // ─────────────────────────────────────────────────────────────────────────

    private fun setWindowWidth(widthPx: Int) {
        if (!isViewAdded) return
        try {
            val lp = overlayView.layoutParams as WindowManager.LayoutParams
            lp.width = widthPx
            windowManager.updateViewLayout(overlayView, lp)
        } catch (_: Exception) {}
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private fun today(): String {
        val c = java.util.Calendar.getInstance()
        if (c.get(java.util.Calendar.HOUR_OF_DAY) < 4) c.add(java.util.Calendar.DATE, -1)
        return "%04d-%02d-%02d".format(
            c.get(java.util.Calendar.YEAR),
            c.get(java.util.Calendar.MONTH) + 1,
            c.get(java.util.Calendar.DAY_OF_MONTH)
        )
    }

    private fun currentHour(): Int =
        java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)

    private fun SharedPreferences.safeGetCount(key: String): Long =
        try { getLong(key, 0L) } catch (_: ClassCastException) { getInt(key, 0).toLong() }

    private fun readFloat(prefs: SharedPreferences, key: String, default: Float): Float {
        val raw = prefs.all[key] ?: return default
        return when (raw) {
            is Float  -> raw
            is Double -> raw.toFloat()
            is Long   -> java.lang.Double.longBitsToDouble(raw).toFloat()
            is Int    -> raw.toFloat()
            is String -> raw.toFloatOrNull() ?: default
            else      -> default
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Notification
    // ─────────────────────────────────────────────────────────────────────────

    private fun buildNotification(): Notification {
        val channelId = "apptime_overlay"
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(channelId) == null) {
            manager.createNotificationChannel(
                NotificationChannel(channelId, "AppTime Overlay",
                    NotificationManager.IMPORTANCE_MIN)
            )
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("AppTime ativo")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
    }

    companion object {
        const val NOTIF_ID = 1001
        const val DIM_ALPHA = 0.35f

        val SOCIAL_PATTERNS = listOf(
            "instagram", "tiktok", "twitter", "facebook", "snapchat",
            "reddit", "pinterest", "linkedin", "threads", "bluesky",
            "gmail", "outlook", "yahoo.mail", "protonmail",
            "whatsapp", "telegram", "signal", "discord"
        )
    }
}
