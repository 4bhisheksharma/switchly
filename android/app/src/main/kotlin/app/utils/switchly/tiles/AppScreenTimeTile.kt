package app.utils.switchly.tiles

import android.content.Intent
import android.service.quicksettings.Tile
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.R
import app.utils.switchly.screentime.AppScreenTime
import app.utils.switchly.tiles.base.BaseTile

/**
 * Shows today's screen time for a user-selected app.
 *
 * Like [BatteryTile], this is not marked ACTIVE_TILE in the manifest, so SystemUI calls
 * onStartListening and re-renders every time the panel opens, giving fresh up-to-the-minute
 * screen time calculations without background alarms or battery drain.
 */
class AppScreenTimeTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    override fun render(tile: Tile) {
        val hasPermission = AppScreenTime.hasUsageAccess(this)
        if (!hasPermission) {
            tile.state = Tile.STATE_INACTIVE
            tile.label = getString(R.string.tile_app_screen_time)
            tile.subtitle = "Permission needed"
            return
        }

        val config = AppScreenTime.getConfig(this)
        if (config == null || config.packageName.isBlank()) {
            tile.state = Tile.STATE_INACTIVE
            tile.label = getString(R.string.tile_app_screen_time)
            tile.subtitle = "Select an app"
            return
        }

        val millis = AppScreenTime.getTodayForegroundTimeMillis(this, config.packageName)
        val formatted = AppScreenTime.formatDuration(millis)

        tile.state = if (millis > 0) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = "${config.appName}: $formatted"
        tile.subtitle = "$formatted today"
    }

    override fun onTap() {
        if (!AppScreenTime.hasUsageAccess(this)) {
            AppScreenTime.openUsageAccessSettings(this)
            return
        }

        val config = AppScreenTime.getConfig(this)
        if (config == null || config.packageName.isBlank()) {
            launchApp(LaunchRoutes.tile("app_screen_time"))
            return
        }

        if (config.openAppOnTap) {
            val launchIntent = packageManager.getLaunchIntentForPackage(config.packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivityAndCollapseCompat(launchIntent)
                return
            }
        }

        launchApp(LaunchRoutes.tile("app_screen_time"))
    }
}
