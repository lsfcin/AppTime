package com.example.apptime

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.concurrent.TimeUnit

class AppUsageService : Service() {

    private val CHANNEL_ID = "AppUsageServiceChannel"
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var windowManager: WindowManager
    private var floatingView: View? = null
    private lateinit var overlayTextView: TextView
    private val handler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        createNotificationChannel()
        startForegroundServiceNotification()

        if (floatingView == null) {
            showOverlay()
        }

        handler.post(updateOverlayRunnable)

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        handler.removeCallbacks(updateOverlayRunnable)
        if (floatingView != null) {
            windowManager.removeView(floatingView)
            floatingView = null
        }
        stopForeground(true)
    }

    private fun showOverlay() {
        floatingView = LayoutInflater.from(this).inflate(R.layout.overlay_layout, null)
        overlayTextView = floatingView!!.findViewById(R.id.overlay_text_view)

        updateTextColorBasedOnTheme() // Set initial text color

        val layoutParamsType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutParamsType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 16f, resources.displayMetrics).toInt()
            y = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 4f, resources.displayMetrics).toInt()
        }

        windowManager.addView(floatingView, params)
    }

    private fun updateTextColorBasedOnTheme() {
        val currentNightMode = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        val textColor = if (currentNightMode == Configuration.UI_MODE_NIGHT_YES) {
            Color.LTGRAY
        } else {
            Color.DKGRAY
        }
        overlayTextView.setTextColor(textColor)
        overlayTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        // Add a shadow for better visibility against any background
        //overlayTextView.setShadowLayer(1.5f, 1f, 1f, Color.DKGRAY)
    }

    private val updateOverlayRunnable = object : Runnable {
        override fun run() {
            updateTextColorBasedOnTheme() // Periodically check for theme changes
            updateOverlayWithUsageStats()
            handler.postDelayed(this, UPDATE_INTERVAL)
        }
    }

    private fun updateOverlayWithUsageStats() {
        val currentTime = System.currentTimeMillis()
        val foregroundApp = getForegroundApp(currentTime)

        if (foregroundApp == null || foregroundApp == packageName) {
            overlayTextView.text = "" // Hide text when no app is tracked
            return
        }

        val sessionTime = getSessionTime(foregroundApp, currentTime)
        val appName = getAppName(foregroundApp)
        overlayTextView.text = formatUsageStats(appName, sessionTime)
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Usage Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundServiceNotification() {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AppTime is Active")
            .setContentText("Displaying usage stats over other apps.")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
    }
    
    private fun getForegroundApp(currentTime: Long): String? {
        var foregroundApp: String? = null
        val timeWindow = 1000 * 60 * 5 // 5 minute window
        val events = usageStatsManager.queryEvents(currentTime - timeWindow, currentTime)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                foregroundApp = event.packageName
            }
        }
        return foregroundApp
    }
    
    private fun getSessionTime(packageName: String, currentTime: Long): Long {
        val events = usageStatsManager.queryEvents(currentTime - TimeUnit.HOURS.toMillis(1), currentTime)
        val event = UsageEvents.Event()

        var sessionStartTime = 0L
        var lastResumedPackage: String? = null
        var lastResumeTimeForPackage = 0L
        var lastPauseTimeForPackage = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                if (lastResumedPackage != event.packageName) {
                    lastResumedPackage = event.packageName
                    if (lastResumedPackage == packageName) {
                        sessionStartTime = event.timeStamp
                    }
                }
            }

            if (event.packageName == packageName) {
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    lastResumeTimeForPackage = event.timeStamp
                } else if (event.eventType == UsageEvents.Event.ACTIVITY_PAUSED) {
                    lastPauseTimeForPackage = event.timeStamp
                }
            }
        }

        if (lastResumedPackage == packageName && lastResumeTimeForPackage > lastPauseTimeForPackage) {
            if (sessionStartTime > 0) {
                return currentTime - sessionStartTime
            }
        }

        return 0L
    }


    private fun getTimeInInterval(packageName: String, currentTime: Long, intervalMillis: Long): Long {
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            currentTime - intervalMillis,
            currentTime
        )
        return stats.filter { it.packageName == packageName }
            .sumOf { it.totalTimeInForeground }
    }

    private fun getAppOpensInInterval(packageName: String, currentTime: Long, intervalMillis: Long): Int {
        val usageEvents = usageStatsManager.queryEvents(currentTime - intervalMillis, currentTime)
        var launchCount = 0
        val event = UsageEvents.Event()
        var lastResumeTime = 0L
        val NEW_LAUNCH_THRESHOLD_MILLIS = TimeUnit.SECONDS.toMillis(5)
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.packageName == packageName && event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                 if (event.timeStamp - lastResumeTime > NEW_LAUNCH_THRESHOLD_MILLIS) {
                    launchCount++
                }
                lastResumeTime = event.timeStamp
            }
        }
        return launchCount
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    private fun formatUsageStats(appName: String, sessionTime: Long): String {
        val sessionSeconds = TimeUnit.MILLISECONDS.toSeconds(sessionTime)
        return "$appName: ${sessionSeconds}s"
    }

    companion object {
        private const val TAG = "AppUsageService"
        private const val UPDATE_INTERVAL = 2000L
        private const val SESSION_CONTINUITY_THRESHOLD = 5000L // 5 seconds
    }
}
