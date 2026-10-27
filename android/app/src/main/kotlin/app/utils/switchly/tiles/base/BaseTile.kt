package app.utils.switchly.tiles.base

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.core.Permissions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Common behaviour for every Switchly tile:
 * - refreshes state each time the Quick Settings panel opens
 * - when WRITE_SECURE_SETTINGS is missing, shows "Tap to set up" and opens onboarding on tap.
 *   STATE_UNAVAILABLE is not used for this because unavailable tiles can't be tapped.
 * - runs [toggle] off the main thread, then redraws
 * - asks for unlock first when the device is locked (these tiles change network/system settings)
 */
abstract class BaseTile : TileService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    /** Set to false for tiles that don't touch Settings (e.g. the VPN kill switch). */
    protected open val requiresSecureSettings: Boolean = true

    /** Draws the tile's state, label and subtitle. Called on the main thread. */
    protected abstract fun render(tile: Tile)

    /** Applies the next state. Called on [Dispatchers.IO]. */
    protected abstract fun toggle()

    override fun onStartListening() {
        super.onStartListening()
        refresh()
    }

    override fun onClick() {
        super.onClick()
        if (requiresSecureSettings && !Permissions.hasWriteSecureSettings(this)) {
            launchApp(LaunchRoutes.SETUP)
            return
        }
        if (isLocked) unlockAndRun(::runToggle) else runToggle()
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private fun runToggle() {
        scope.launch {
            try {
                withContext(Dispatchers.IO) { toggle() }
            } catch (e: Exception) {
                Log.e(javaClass.simpleName, "Toggle failed", e)
            }
            refresh()
        }
    }

    protected fun refresh() {
        // qsTile is null when the panel has already closed; it is redrawn on next open.
        val tile = qsTile ?: return
        if (requiresSecureSettings && !Permissions.hasWriteSecureSettings(this)) {
            tile.state = Tile.STATE_INACTIVE
            tile.subtitle = "Tap to set up"
        } else {
            render(tile)
        }
        tile.updateTile()
    }

    /** Opens the Flutter app at [route] and collapses the shade. */
    protected fun launchApp(route: String) {
        val intent = Intent(this, MainActivity::class.java)
            .putExtra(LaunchRoutes.EXTRA_ROUTE, route)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            // The Intent overload throws on API 34+ when targetSdk >= 34.
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
