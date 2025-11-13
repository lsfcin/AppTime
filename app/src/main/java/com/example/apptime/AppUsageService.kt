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
            Color.WHITE
        } else {
            Color.BLACK
        }
        overlayTextView.setTextColor(textColor)
        // Add a shadow for better visibility against any background
        overlayTextView.setShadowLayer(1.5f, 1f, 1f, Color.DKGRAY)
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
        val timeInLast24Hours = getTimeInInterval(foregroundApp, currentTime, TimeUnit.DAYS.toMillis(1))
        val timeInLast7Days = getTimeInInterval(foregroundApp, currentTime, TimeUnit.DAYS.toMillis(7))
        val appOpensLast24Hours = getAppOpensInInterval(foregroundApp, currentTime, TimeUnit.DAYS.toMillis(1))
        
        overlayTextView.text = formatUsageStats(sessionTime, timeInLast24Hours, timeInLast7Days, appOpensLast24Hours)
    }
    
    // ... (All other helper functions remain unchanged)

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
        val timeWindow = 1000 * 60
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
        var sessionTime: Long = 0
        val startTime = currentTime - TimeUnit.HOURS.toMillis(12)
        val events = usageStatsManager.queryEvents(startTime, currentTime)
        val event = UsageEvents.Event()
        var lastResumeTime: Long? = null
        val eventsForPackage = mutableListOf<Pair<Int, Long>>()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.packageName == packageName) {
                eventsForPackage.add(Pair(event.eventType, event.timeStamp))
            }
        }
        for (e in eventsForPackage.asReversed()) {
            if (e.first == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastResumeTime = e.second
                break 
            }
        }
        if (lastResumeTime != null) {
            sessionTime = currentTime - lastResumeTime
        }
        return sessionTime
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

    private fun formatUsageStats(sessionTime: Long, timeInLast24Hours: Long, timeInLast7Days: Long, appOpensLast24Hours: Int): String {
        val sessionMinutes = TimeUnit.MILLISECONDS.toMinutes(sessionTime)
        val sessionHours = TimeUnit.MILLISECONDS.toHours(sessionTime)
        val sessionDisplay = if(sessionHours > 0) String.format("%d:%02d", sessionHours, sessionMinutes % 60) else "${sessionMinutes}m"
        val hours24 = timeInLast24Hours / 3600000.0
        val hours7days = timeInLast7Days / 3600000.0
        return String.format("[ %s | %.1fh %.1fh | %dx ]",
            sessionDisplay,
            hours24,
            hours7days,
            appOpensLast24Hours
        )
    }

    companion object {
        private const val TAG = "AppUsageService"
        private const val UPDATE_INTERVAL = 2000L
    }
}
