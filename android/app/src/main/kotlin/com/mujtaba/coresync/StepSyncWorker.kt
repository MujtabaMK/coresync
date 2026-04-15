package com.mujtaba.coresync

import android.content.Context
import androidx.work.*
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * WorkManager worker that reliably syncs today's step count to Firestore.
 *
 * Unlike Handler.postDelayed(), WorkManager:
 * - Survives process death and device reboots
 * - Executes during Doze maintenance windows
 * - Retries on failure with exponential back-off
 * - Only runs when network is available
 */
class StepSyncWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val WORK_NAME = "step_sync_periodic"

        /** Enqueue a unique periodic sync job (no-op if already scheduled). */
        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = PeriodicWorkRequestBuilder<StepSyncWorker>(
                15, TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(
                    WORK_NAME,
                    ExistingPeriodicWorkPolicy.KEEP,
                    request
                )
        }

        /** Enqueue a one-shot immediate sync (e.g. on service destroy). */
        fun syncNow(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = OneTimeWorkRequestBuilder<StepSyncWorker>()
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueue(request)
        }
    }

    override fun doWork(): Result {
        try {
            if (FirebaseApp.getApps(applicationContext).isEmpty()) return Result.retry()
            val user = FirebaseAuth.getInstance().currentUser ?: return Result.retry()

            val prefs = applicationContext.getSharedPreferences(
                StepCounterForegroundService.PREFS_NAME, Context.MODE_PRIVATE
            )

            val savedDate = prefs.getString(StepCounterForegroundService.KEY_DATE, null)
            val nativeTodayKey = StepCounterForegroundService.todayKey()
            val steps = prefs.getInt(StepCounterForegroundService.KEY_STEPS, 0)

            if (savedDate != nativeTodayKey) {
                // Date mismatch: sync old day's final count if available
                if (savedDate != null && steps > 0) {
                    val parts = savedDate.split("-")
                    if (parts.size == 3) {
                        val dateKey = "%04d-%02d-%02d".format(
                            parts[0].toInt(), parts[1].toInt(), parts[2].toInt()
                        )
                        val docRef = FirebaseFirestore.getInstance()
                            .collection("users").document(user.uid)
                            .collection("gym_steps").document(dateKey)
                        val doc = Tasks.await(docRef.get())
                        val existing = doc.getLong("steps")?.toInt() ?: 0
                        if (steps > existing) {
                            Tasks.await(docRef.set(mapOf("steps" to steps), SetOptions.merge()))
                        }
                    }
                }
                return Result.success()
            }

            if (steps <= 0) return Result.success()

            val firestoreDateKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val docRef = FirebaseFirestore.getInstance()
                .collection("users").document(user.uid)
                .collection("gym_steps").document(firestoreDateKey)

            val doc = Tasks.await(docRef.get())
            val existing = doc.getLong("steps")?.toInt() ?: 0
            if (steps > existing) {
                Tasks.await(docRef.set(mapOf("steps" to steps), SetOptions.merge()))
            }

            return Result.success()
        } catch (_: Exception) {
            return Result.retry()
        }
    }
}