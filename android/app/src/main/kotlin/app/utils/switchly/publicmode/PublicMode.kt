package app.utils.switchly.publicmode

import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import app.utils.switchly.display.Grayscale
import app.utils.switchly.network.KillSwitch
import app.utils.switchly.network.WirelessDebugging
import app.utils.switchly.profiles.Profiles
import app.utils.switchly.tiles.TileRefresher
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

data class PublicModeConfig(
    val timeoutMinutes: Int = 10,
    val hiddenTiles: List<String> = listOf("payment_qr", "quick_texts", "wireless_debugging"),
    val blockedPackages: List<String> = emptyList(),
    val enableDnd: Boolean = true,
    val enableGrayscale: Boolean = false,
    val enableKillSwitch: Boolean = false,
    val pin: String? = null,
)

object PublicMode {
    private const val TAG = "PublicMode"
    private const val ACTIVE_KEY = "public_mode_active"
    private const val ENDS_AT_KEY = "public_mode_ends_at"
    private const val SNAPSHOT_KEY = "public_mode_snapshot"

    fun isActive(context: Context): Boolean =
        SharedConfig.nativeState(context).getBoolean(ACTIVE_KEY, false)

    fun endsAt(context: Context): Long =
        SharedConfig.nativeState(context).getLong(ENDS_AT_KEY, 0L)

    fun config(context: Context): PublicModeConfig {
        val raw = SharedConfig.getString(context, PrefKeys.PUBLIC_MODE_CONFIG) ?: return PublicModeConfig()
        return try {
            val json = JSONObject(raw)
            val hiddenArray = json.optJSONArray("hiddenTiles")
            val hiddenList = mutableListOf<String>()
            if (hiddenArray != null) {
                for (i in 0 until hiddenArray.length()) {
                    hiddenList.add(hiddenArray.getString(i))
                }
            } else {
                hiddenList.addAll(listOf("payment_qr", "quick_texts", "wireless_debugging"))
            }

            val blockedArray = json.optJSONArray("blockedPackages")
            val blockedList = mutableListOf<String>()
            if (blockedArray != null) {
                for (i in 0 until blockedArray.length()) {
                    blockedList.add(blockedArray.getString(i))
                }
            }

            PublicModeConfig(
                timeoutMinutes = json.optInt("timeoutMinutes", 10),
                hiddenTiles = hiddenList,
                blockedPackages = blockedList,
                enableDnd = json.optBoolean("enableDnd", true),
                enableGrayscale = json.optBoolean("enableGrayscale", false),
                enableKillSwitch = json.optBoolean("enableKillSwitch", false),
                pin = json.optString("pin").takeIf { it.isNotBlank() },
            )
        } catch (e: JSONException) {
            Log.w(TAG, "Error parsing PublicModeConfig", e)
            PublicModeConfig()
        }
    }

    @Suppress("DEPRECATION")
    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageAccess(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            context.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        }
    }

    fun canDrawOverlays(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    fun openOverlaySettings(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(intent)
            } catch (_: Exception) {
                context.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
        }
    }

    fun hasDndAccess(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.isNotificationPolicyAccessGranted == true
        } else {
            true
        }
    }

    fun openDndSettings(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(intent)
            } catch (e: Exception) {
                Log.w(TAG, "Cannot open DND settings", e)
            }
        }
    }

    /**
     * Activates Public Mode:
     * 1. Snapshots current active profile and system settings.
     * 2. Enables requested protection settings (DND, grayscale, kill switch, etc.).
     * 3. Calculates timeout and persists active state.
     * 4. Starts the foreground monitoring service.
     */
    fun activate(context: Context, cfg: PublicModeConfig? = null): Boolean {
        val currentCfg = cfg ?: config(context)
        val state = SharedConfig.nativeState(context)

        // Snapshot current settings to restore later
        val snapshot = JSONObject()
        val activeProfileId = Profiles.activeId(context)
        if (activeProfileId != null) {
            snapshot.put("profileId", activeProfileId)
        }

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null && nm.isNotificationPolicyAccessGranted) {
            snapshot.put("dndFilter", nm.currentInterruptionFilter)
        }

        snapshot.put("grayscale", Grayscale.isOn(context))
        snapshot.put("killSwitch", KillSwitch.isOn())
        snapshot.put("wirelessDebugging", WirelessDebugging.isOn(context))

        state.edit().putString(SNAPSHOT_KEY, snapshot.toString()).apply()

        // Apply Protection settings
        if (currentCfg.enableDnd && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null && nm.isNotificationPolicyAccessGranted) {
            try {
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
            } catch (e: Exception) {
                Log.w(TAG, "Failed setting DND filter", e)
            }
        }

        if (currentCfg.enableGrayscale) {
            Grayscale.set(context, true)
        }

        if (currentCfg.enableKillSwitch && !KillSwitch.isOn()) {
            if (KillSwitch.hasConsent(context)) {
                KillSwitch.start(context)
            }
        }

        if (WirelessDebugging.isOn(context)) {
            WirelessDebugging.set(context, false)
        }

        val endsAt = if (currentCfg.timeoutMinutes > 0) {
            System.currentTimeMillis() + (currentCfg.timeoutMinutes * 60_000L)
        } else {
            0L
        }

        state.edit()
            .putBoolean(ACTIVE_KEY, true)
            .putLong(ENDS_AT_KEY, endsAt)
            .apply()

        // Start Foreground monitoring service
        val serviceIntent = Intent(context, PublicModeService::class.java).apply {
            action = PublicModeService.ACTION_START
            putExtra(PublicModeService.EXTRA_ENDS_AT, endsAt)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed starting PublicModeService", e)
        }

        TileRefresher.refreshAll(context)
        return true
    }

    /**
     * Deactivates Public Mode and restores previous profile or individual settings.
     */
    fun deactivate(context: Context): Boolean {
        val state = SharedConfig.nativeState(context)
        val snapshotStr = state.getString(SNAPSHOT_KEY, null)
        val snapshot = snapshotStr?.let {
            try { JSONObject(it) } catch (_: Exception) { null }
        }

        // 1. If a profile was active before, restore it
        val prevProfileId = if (snapshot?.has("profileId") == true) snapshot.getString("profileId") else null
        if (!prevProfileId.isNullOrBlank()) {
            val allProfiles = Profiles.all(context)
            val profile = allProfiles.firstOrNull { it.id == prevProfileId }
            if (profile != null) {
                Profiles.apply(context, profile)
            }
        } else {
            // Restore individual settings
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null && nm.isNotificationPolicyAccessGranted) {
                val prevDnd = snapshot?.optInt("dndFilter", -1) ?: -1
                if (prevDnd != -1) {
                    try {
                        nm.setInterruptionFilter(prevDnd)
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to restore DND filter", e)
                    }
                }
            }

            if (snapshot?.has("grayscale") == true) {
                Grayscale.set(context, snapshot.getBoolean("grayscale"))
            }

            if (snapshot?.has("killSwitch") == true) {
                val prevKill = snapshot.getBoolean("killSwitch")
                if (!prevKill && KillSwitch.isOn()) {
                    KillSwitch.stop(context)
                }
            }

            if (snapshot?.has("wirelessDebugging") == true) {
                WirelessDebugging.set(context, snapshot.getBoolean("wirelessDebugging"))
            }
        }

        // Stop Foreground monitoring service
        val stopIntent = Intent(context, PublicModeService::class.java).apply {
            action = PublicModeService.ACTION_STOP
        }
        try {
            context.stopService(stopIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed stopping PublicModeService", e)
        }

        PublicModeOverlay.dismiss()

        state.edit()
            .putBoolean(ACTIVE_KEY, false)
            .putLong(ENDS_AT_KEY, 0L)
            .remove(SNAPSHOT_KEY)
            .apply()

        TileRefresher.refreshAll(context)
        return true
    }
}
