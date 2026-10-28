package app.utils.switchly.screentime

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import org.json.JSONObject
import java.util.Calendar

data class ScreenTimeConfig(
    val packageName: String,
    val appName: String,
    val openAppOnTap: Boolean = true,
)

object AppScreenTime {

    /** Checks whether Switchly has been granted the PACKAGE_USAGE_STATS permission via AppOps. */
    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Directs the user to Android's "Usage Access" settings page. */
    fun openUsageAccessSettings(context: Context) {
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

    /** Reads the currently selected app config from SharedPreferences. */
    fun getConfig(context: Context): ScreenTimeConfig? {
        val raw = SharedConfig.getString(context, PrefKeys.APP_USAGE_CONFIG) ?: return null
        return try {
            val json = JSONObject(raw)
            val pkg = json.optString("packageName", "")
            if (pkg.isBlank()) null else ScreenTimeConfig(
                packageName = pkg,
                appName = json.optString("appName", pkg),
                openAppOnTap = json.optBoolean("openAppOnTap", true),
            )
        } catch (_: Exception) {
            null
        }
    }

    /** Calculates foreground screen time in milliseconds for [targetPackage] since midnight today. */
    fun getTodayForegroundTimeMillis(context: Context, targetPackage: String): Long {
        if (targetPackage.isBlank() || !hasUsageAccess(context)) return 0L

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return 0L

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        return try {
            val aggregated = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
            aggregated[targetPackage]?.totalTimeInForeground ?: 0L
        } catch (_: Exception) {
            0L
        }
    }

    /** Fetches foreground usage for all packages today. Useful for the app picker list. */
    fun getTodayAllUsageStats(context: Context): Map<String, Long> {
        if (!hasUsageAccess(context)) return emptyMap()

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyMap()

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        return try {
            val aggregated = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
            val result = mutableMapOf<String, Long>()
            for ((pkg, stats) in aggregated) {
                if (stats.totalTimeInForeground > 0) {
                    result[pkg] = stats.totalTimeInForeground
                }
            }
            result
        } catch (_: Exception) {
            emptyMap()
        }
    }

    /** Formats duration into a concise, tile-friendly label (e.g. "1h 24m", "42m", "< 1m"). */
    fun formatDuration(totalMillis: Long): String {
        val totalSeconds = totalMillis / 1000
        val minutes = (totalSeconds / 60) % 60
        val hours = totalSeconds / 3600

        return when {
            hours > 0 && minutes > 0 -> "${hours}h ${minutes}m"
            hours > 0 -> "${hours}h"
            minutes > 0 -> "${minutes}m"
            totalSeconds > 0 -> "< 1m"
            else -> "0m"
        }
    }
}
