package com.lsf.apptime

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
import android.os.PowerManager
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    // ── Regular overlay (tiny counter in status-bar zone) ─────────────────────
    private lateinit var overlayView: TextView
    private lateinit var prefs: SharedPreferences
    private lateinit var powerManager: PowerManager
    private val handler = Handler(Looper.getMainLooper())
    private var isViewAdded = false

    // ── Feedback engine (PM — Personalized Messages) ──────────────────────────
    // Lazily initialized once — must survive watchdog restarts (onStartCommand
    // is called every 30 s by MonitoringService) without resetting PM schedules.
    private var feedbackEngine: FeedbackEngine? = null

    // ── Feedback evaluation every 5 poll ticks (~2.5 s) ──────────────────────
    private var evalTick = 0

    // ── Max overlay width in px (set once in addOverlayView) ─────────────────
    private var maxWidthPx = 0

    // ── Slide suppression — only reposition window when y actually changes ────
    private var lastTopY = -1

    // ── Width restoration — tracked to defer WRAP_CONTENT until timer text is set ──
    private var pmWasActive = false

    // ── Poll loop ─────────────────────────────────────────────────────────────
    // Use a slower interval when the screen is off — the overlay is invisible
    // and feedback evaluation is unnecessary, so 2 s wastes ~4× less CPU.
    private val pollRunnable = object : Runnable {
        override fun run() {
            val screenOn = powerManager.isInteractive
            if (screenOn) {
                updateOverlay()
                if (++evalTick >= 5) {
                    evalTick = 0
                    feedbackEngine?.evaluate()
                }
            }
            handler.postDelayed(this, if (screenOn) 500L else 2_000L)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())
        prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        powerManager = getSystemService(POWER_SERVICE) as PowerManager
        if (!isViewAdded) addOverlayView()
        if (feedbackEngine == null) {
            feedbackEngine = FeedbackEngine(
                view           = overlayView,
                getViewAdded   = { isViewAdded },
                setWindowWidth = ::setWindowWidth,
                getMaxWidthPx  = { maxWidthPx },
                getPrefs       = { prefs },
                getAppLabel    = ::resolveAppLabel,
            )
        }
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
            alpha = 1f
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

        // Snapshot once — prefs.all copies the entire map; reusing it here avoids
        // multiple copies and reduces synchronized lock acquisitions on the 500ms path.
        val snap = prefs.all

        val showBg     = snap["flutter.overlay_show_background"] as? Boolean ?: true
        val showBorder = snap["flutter.overlay_show_border"] as? Boolean ?: true
        val topDp      = readFloat(snap, "flutter.overlay_top_dp", 40f).coerceIn(0f, 800f)
        val density    = resources.displayMetrics.density

        // Flutter shared_preferences stores int as Long on Android.
        val fontSizeBase = run {
            val asLong = snap["flutter.overlay_font_size"] as? Long ?: 0L
            if (asLong > 0L) asLong.toFloat()
            else readFloat(snap, "flutter.overlay_font_size", 14f)
        }.coerceIn(10f, 30f)

        val bg = GradientDrawable().apply {
            cornerRadius = 8f * density
            setColor(if (showBg) Color.argb(160, 0, 0, 0) else Color.TRANSPARENT)
            if (showBorder) setStroke((1.5f * density).toInt(), Color.WHITE)
        }
        overlayView.background = bg

        // Only reposition the window when y actually changed — calling
        // updateViewLayout every tick causes the OS to re-center WRAP_CONTENT
        // width on each frame, producing a subtle lateral slide.
        val pmActive = feedbackEngine?.pmActive ?: false

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

        if (pmActive) {
            pmWasActive = true
            return   // PM owns text, textSize, typeface, alpha, visibility
        }

        overlayView.textSize = fontSizeBase
        overlayView.alpha    = 1f

        val text           = snap["flutter.overlay_text"] as? String ?: ""
        val visible        = snap["flutter.overlay_visible"] as? Boolean ?: false
        val overlayEnabled = snap["flutter.overlay_enabled"] as? Boolean ?: true
        val currentPkg     = snap["flutter.current_pkg"] as? String
        val isUnmonitored  = currentPkg != null &&
            AppConstants.parseDisabledApps(prefs).contains(currentPkg)
        val shouldShow     = overlayEnabled && visible && text.isNotEmpty() && !isUnmonitored

        overlayView.text       = text
        overlayView.visibility = if (shouldShow) View.VISIBLE else View.INVISIBLE

        // Width restoration: the timer text is now in place — safe to shrink the window.
        // This fires only on the first tick after a PM ends so updateViewLayout isn't
        // called every 500 ms (which would cause lateral drift on WRAP_CONTENT windows).
        if (pmWasActive) {
            pmWasActive = false
            setWindowWidth(WindowManager.LayoutParams.WRAP_CONTENT)
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

    private fun readFloat(snap: Map<String, *>, key: String, default: Float): Float {
        val raw = snap[key] ?: return default
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
    // App label resolution — mirrors the Dart labelForApp() three-tier strategy
    // ─────────────────────────────────────────────────────────────────────────

    private fun resolveAppLabel(pkg: String): String {
        // Tier 1 — PackageManager display name (same source as AppInfoService.labels in Dart)
        try {
            return packageManager.getApplicationInfo(pkg, 0)
                .loadLabel(packageManager).toString()
        } catch (_: Exception) { /* app not installed or PM unavailable */ }

        // Tier 3 — heuristic fallback matching Dart's labelForApp()
        val tld   = setOf("com", "org", "net", "io", "br", "uk", "de", "fr", "co")
        val noise = setOf("android", "app", "apps", "mobile", "production", "release",
                          "mediaclient", "frontpage", "katana", "barcelona")
        val brand = pkg.split(".")
            .filter { it !in tld && it !in noise && it.length > 1 }
            .firstOrNull() ?: pkg.split(".").last()
        return brand.replaceFirstChar { it.uppercase() }
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
    }
}
