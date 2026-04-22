package com.mujtaba.coresync

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class StepCounterForegroundService : Service(), SensorEventListener {

    companion object {
        const val CHANNEL_ID = "step_counter_channel"
        const val NOTIFICATION_ID = 1001
        const val PREFS_NAME = "step_counter_native"
        const val KEY_DATE = "date"
        const val KEY_RAW = "raw"
        const val KEY_STEPS = "steps"
        private const val SYNC_INTERVAL = 15 * 60 * 1000L

        /** Read today's cached step count from any Context. */
        fun getSteps(context: Context): Int {
            val prefs = context.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            return if (prefs.getString(KEY_DATE, null) == todayKey()) {
                prefs.getInt(KEY_STEPS, 0)
            } else 0
        }

        fun todayKey(): String {
            val cal = Calendar.getInstance()
            return "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.MONTH) + 1}-${cal.get(Calendar.DAY_OF_MONTH)}"
        }
    }

    private var sensorManager: SensorManager? = null
    private val handler = Handler(Looper.getMainLooper())
    private var syncRunnable: Runnable? = null
    private var lastSyncedSteps = 0

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        val notification = buildNotification(getSteps(this))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        registerSensor()
        startPeriodicSync()

        // Schedule WorkManager for reliable sync that survives Doze mode
        try { StepSyncWorker.schedule(this) } catch (_: Exception) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int =
        START_STICKY

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        // Final sync before the service stops
        syncToFirestore()
        try { StepSyncWorker.syncNow(this) } catch (_: Exception) {}
        sensorManager?.unregisterListener(this)
        syncRunnable?.let { handler.removeCallbacks(it) }
        super.onDestroy()
    }

    // ── Sensor ──

    private fun registerSensor() {
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_STEP_COUNTER) return
        val rawSteps = event.values[0].toInt()

        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val today = todayKey()
        val savedDate = prefs.getString(KEY_DATE, null)
        val savedRaw = prefs.getInt(KEY_RAW, -1)
        val savedSteps = prefs.getInt(KEY_STEPS, 0)

        val todaySteps = if (savedDate == today && savedRaw >= 0) {
            if (rawSteps >= savedRaw) {
                savedSteps + (rawSteps - savedRaw)
            } else {
                // Device rebooted — counter reset to 0
                savedSteps + rawSteps
            }
        } else {
            // New day or first run — sync old day's final count before resetting
            if (savedDate != null && savedSteps > 0) {
                syncOldDayToFirestore(savedDate, savedSteps)
            }
            lastSyncedSteps = 0
            0
        }

        prefs.edit()
            .putString(KEY_DATE, today)
            .putInt(KEY_RAW, rawSteps)
            .putInt(KEY_STEPS, todaySteps)
            .apply()

        updateNotification(todaySteps)

        // Sync to Firestore every 500 steps so data isn't lost if service is killed
        if (todaySteps - lastSyncedSteps >= 500) {
            lastSyncedSteps = todaySteps
            syncToFirestore()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // ── Firestore sync ──

    private fun startPeriodicSync() {
        syncRunnable = object : Runnable {
            override fun run() {
                syncToFirestore()
                handler.postDelayed(this, SYNC_INTERVAL)
            }
        }
        // First sync after 1 minute, then every 15 minutes
        handler.postDelayed(syncRunnable!!, 60_000L)
    }

    private fun syncToFirestore() {
        try {
            if (FirebaseApp.getApps(this).isEmpty()) return
            val user = FirebaseAuth.getInstance().currentUser ?: return
            val steps = getSteps(this)
            if (steps <= 0) return

            val dateKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val docRef = FirebaseFirestore.getInstance()
                .collection("users").document(user.uid)
                .collection("gym_steps").document(dateKey)

            docRef.get().addOnSuccessListener { doc ->
                val existing = doc.getLong("steps")?.toInt() ?: 0
                if (steps > existing) {
                    docRef.set(mapOf("steps" to steps), SetOptions.merge())
                }
            }
        } catch (_: Exception) {
        }
    }

    /** Sync a previous day's final step count before day rollover. */
    private fun syncOldDayToFirestore(savedDate: String, steps: Int) {
        try {
            if (FirebaseApp.getApps(this).isEmpty()) return
            val user = FirebaseAuth.getInstance().currentUser ?: return

            // Convert native date key (e.g. "2026-4-13") to Firestore key ("2026-04-13")
            val parts = savedDate.split("-")
            if (parts.size != 3) return
            val dateKey = "%04d-%02d-%02d".format(
                parts[0].toInt(), parts[1].toInt(), parts[2].toInt()
            )

            val docRef = FirebaseFirestore.getInstance()
                .collection("users").document(user.uid)
                .collection("gym_steps").document(dateKey)

            docRef.get().addOnSuccessListener { doc ->
                val existing = doc.getLong("steps")?.toInt() ?: 0
                if (steps > existing) {
                    docRef.set(mapOf("steps" to steps), SetOptions.merge())
                }
            }
        } catch (_: Exception) {
        }
    }

    // ── Notification ──

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "Step Counter", NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows your daily step count"
            setShowBadge(false)
        }
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)
    }

    private fun buildNotification(steps: Int): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("$steps steps today")
            .setContentText("CoreSync Go is tracking your steps")
            .setSmallIcon(R.drawable.ic_step_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun updateNotification(steps: Int) {
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
            .notify(NOTIFICATION_ID, buildNotification(steps))
    }
}