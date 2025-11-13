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
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
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
    private var updateCounter = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        createNotificationChannel() // Still needed for foreground service
        startForegroundServiceNotification()

        if (floatingView == null) {
            showTestOverlay()
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

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Usage Service Channel",
                NotificationManager.IMPORTANCE_LOW // Use low importance for foreground service notification
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundServiceNotification() {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AppTime Running")
            .setContentText("Monitoring app usage (overlay active)")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
    }

    private fun showTestOverlay() {
        floatingView = LayoutInflater.from(this).inflate(R.layout.overlay_layout, null) // We'll create overlay_layout next
        overlayTextView = floatingView!!.findViewById(R.id.overlay_text_view) // We'll define this ID in overlay_layout

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
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, // Allows the view to be drawn outside of the screen bounds
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 100 // A bit below the status bar
        }

        windowManager.addView(floatingView, params)
        overlayTextView.text = "Test message 0"
    }

    private val updateOverlayRunnable = object : Runnable {
        override fun run() {
            updateCounter++
            overlayTextView.text = "Test message $updateCounter"
            handler.postDelayed(this, UPDATE_INTERVAL)
        }
    }

    // ... (rest of the app usage tracking functions are kept for later reintegration)
    private fun getForegroundApp(currentTime: Long): String? {
        var foregroundApp: String? = null
        val timeWindow = 1000 * 60 // 1 minute window
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
        val startTime = currentTime - TimeUnit.HOURS.toMillis(12) // Look back up to 12 hours
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

        return String.format("%s [%.1fh|%.1fh|%dx]",
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
