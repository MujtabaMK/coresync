package com.mujtaba.coresync

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock

/**
 * AlarmManager-based backup layer for step counting.
 *
 * Fires every ~15 minutes — even in deep Doze — to:
 * 1. Restart the foreground service if it was killed
 * 2. Trigger a WorkManager one-shot sync to Firestore
 * 3. Schedule the next alarm (non-repeating chain)
 *
 * Uses [setExactAndAllowWhileIdle] when exact alarms are available
 * (allows starting a foreground service from background on Android 12+),
 * otherwise falls back to [setAndAllowWhileIdle].
 */
class StepAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val REQUEST_CODE = 9001
        private const val INTERVAL_MS = 15 * 60 * 1000L  // 15 minutes

        fun schedule(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, StepAlarmReceiver::class.java)
            val pi = PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val triggerAt = SystemClock.elapsedRealtime() + INTERVAL_MS

            // setExactAndAllowWhileIdle lets us start foreground services from
            // the resulting BroadcastReceiver on Android 12+.
            if (Build.VERSION.SDK_INT >= 31 && !am.canScheduleExactAlarms()) {
                // Exact alarm permission not granted — use inexact Doze alarm.
                // Won't be able to restart the foreground service from background
                // on Android 12+, but the WorkManager sync will still fire.
                am.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi
                )
            } else {
                am.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi
                )
            }
        }

        fun cancel(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, StepAlarmReceiver::class.java)
            val pi = PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pi != null) am.cancel(pi)
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val prefs = context.getSharedPreferences(
            StepCounterForegroundService.PREFS_NAME, Context.MODE_PRIVATE
        )

        // Only act if user has previously used step tracking
        if (!prefs.contains(StepCounterForegroundService.KEY_DATE)) {
            return
        }

        // Layer 5: Self-healing — restart the foreground service if killed
        if (!StepCounterForegroundService.isRunning(context)) {
            try {
                context.startForegroundService(
                    Intent(context, StepCounterForegroundService::class.java)
                )
            } catch (_: Exception) {
                // Android 12+ may block background foreground-service starts
                // if exact alarm permission was revoked.  WorkManager sync
                // below still runs as a fallback.
            }
        }

        // Trigger an immediate WorkManager sync (reads SharedPrefs → Firestore)
        try { StepSyncWorker.syncNow(context) } catch (_: Exception) {}

        // Schedule the next alarm (non-repeating chain for reliability)
        schedule(context)
    }
}