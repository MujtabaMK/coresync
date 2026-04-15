package com.mujtaba.coresync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StepCounterBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            if (intent?.action in listOf(
                    Intent.ACTION_BOOT_COMPLETED,
                    Intent.ACTION_MY_PACKAGE_REPLACED,
                    "android.intent.action.QUICKBOOT_POWERON",
                    "com.htc.intent.action.QUICKBOOT_POWERON"
                )
            ) {
                // Only start if the user has previously used step tracking
                val prefs = context.getSharedPreferences(
                    StepCounterForegroundService.PREFS_NAME, Context.MODE_PRIVATE
                )
                if (prefs.contains(StepCounterForegroundService.KEY_DATE)) {
                    val serviceIntent =
                        Intent(context, StepCounterForegroundService::class.java)
                    context.startForegroundService(serviceIntent)

                    // Schedule WorkManager sync in case the foreground service
                    // gets killed before its Handler fires
                    try { StepSyncWorker.schedule(context) } catch (_: Exception) {}
                }
            }
        } catch (_: Exception) {
            // Prevent ANR if anything goes wrong during boot/update
        }
    }
}