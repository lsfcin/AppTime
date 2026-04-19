package com.lucasf.apptime

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Starts MonitoringService after device reboot.
 *
 * Limitation: OEM skins (MIUI, EMUI, ColorOS, etc.) require the user to grant
 * "Auto-start" permission manually in system settings. Without that permission
 * this receiver will be silently blocked and AppTime will not resume until the
 * user opens the app. This is a known Android ecosystem restriction — there is
 * no reliable programmatic workaround.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            context.startForegroundService(Intent(context, MonitoringService::class.java))
        }
    }
}
