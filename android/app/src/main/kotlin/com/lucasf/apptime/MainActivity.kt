package com.lucasf.apptime

import android.app.ActivityManager
import android.app.AppOpsManager
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "apptime/service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMonitoring" -> {
                        startService(Intent(this, OverlayService::class.java))
                        startService(Intent(this, MonitoringService::class.java))
                        result.success(null)
                    }
                    "stopMonitoring" -> {
                        stopService(Intent(this, OverlayService::class.java))
                        stopService(Intent(this, MonitoringService::class.java))
                        result.success(null)
                    }
                    "isRunning" -> result.success(isServiceRunning(MonitoringService::class.java))
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                            )
                        }
                        result.success(null)
                    }
                    "hasOverlayPermission" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this) else true
                        result.success(granted)
                    }
                    "requestUsagePermission" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "hasUsagePermission" -> result.success(hasUsagePermission())
                    "getInstalledApps" -> {
                        val pm = packageManager
                        val apps = mutableMapOf<String, String>()
                        for (appInfo in pm.getInstalledApplications(0)) {
                            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                            if (!isSystem) {
                                apps[appInfo.packageName] =
                                    pm.getApplicationLabel(appInfo).toString()
                            }
                        }
                        result.success(apps)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    @Suppress("DEPRECATION")
    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return manager.getRunningServices(Int.MAX_VALUE)
            .any { it.service.className == serviceClass.name }
    }
}
