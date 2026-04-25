package com.mujtaba.coresync

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val channelName = "com.mujtaba.coresync/step_counter"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intent = Intent(this, StepCounterForegroundService::class.java)
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopService" -> {
                        stopService(Intent(this, StepCounterForegroundService::class.java))
                        result.success(null)
                    }
                    "getSteps" -> {
                        result.success(StepCounterForegroundService.getSteps(this))
                    }
                    "setBaseline" -> {
                        val baseline = call.argument<Int>("steps") ?: 0
                        if (baseline > 0) {
                            val prefs = getSharedPreferences(
                                StepCounterForegroundService.PREFS_NAME,
                                MODE_PRIVATE
                            )
                            val today = StepCounterForegroundService.todayKey()
                            val currentSteps = if (prefs.getString(
                                    StepCounterForegroundService.KEY_DATE, null
                                ) == today
                            ) {
                                prefs.getInt(StepCounterForegroundService.KEY_STEPS, 0)
                            } else 0

                            // Only add baseline when native has fewer steps than
                            // Firestore (fresh install: native started from 0).
                            // On a normal day native >= Firestore so this is a no-op.
                            if (currentSteps < baseline) {
                                val newSteps = currentSteps + baseline
                                prefs.edit()
                                    .putString(StepCounterForegroundService.KEY_DATE, today)
                                    .putInt(StepCounterForegroundService.KEY_STEPS, newSteps)
                                    .apply()
                            }
                        }
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openOemBatterySettings" -> {
                        result.success(openOemBatterySettings())
                    }
                    "getManufacturer" -> {
                        result.success(Build.MANUFACTURER.lowercase())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openOemBatterySettings(): Boolean {
        val oemIntents = listOf(
            // Xiaomi / MIUI
            Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
            // Huawei / HarmonyOS
            Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
            // Samsung
            Intent().setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity")),
            // OPPO / ColorOS
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
            // Vivo
            Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
            // OnePlus
            Intent().setComponent(ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")),
        )

        for (intent in oemIntents) {
            if (intent.resolveActivity(packageManager) != null) {
                try {
                    startActivity(intent)
                    return true
                } catch (_: Exception) { }
            }
        }

        // Fallback: generic battery optimization settings
        try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            return true
        } catch (_: Exception) { }

        return false
    }
}