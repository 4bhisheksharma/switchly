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
 * - shows the predicted state instantly ([predict]), runs [toggle] off the main thread, then
 *   redraws with the real state; taps during a toggle are ignored so a double tap can't undo it
 * - optionally asks for unlock first ([requiresUnlock])
 */
abstract class BaseTile : TileService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var toggling = false

    /** Set to false for tiles that don't touch Settings (e.g. the VPN kill switch). */
    protected open val requiresSecureSettings: Boolean = true

    /** Ask for unlock before acting from the lock screen. Off for harmless display tweaks. */
    protected open val requiresUnlock: Boolean = true

    /** Draws the tile's state, label and subtitle. Called on the main thread. */
    protected abstract fun render(tile: Tile)

    /** Applies the next state. Called on [Dispatchers.IO]. */
    protected open fun toggle() {}

    /** Optional instant feedback: set the state the tile is about to reach. */
    protected open fun predict(tile: Tile) {}

    /** Tiles that open UI instead of toggling (dialogs, pickers) override this. */
    protected open fun onTap() {
        runToggle()
    }

    override fun onStartListening() {
        super.onStartListening()
        refresh()
    }

    override fun onClick() {
        super.onClick()
        if (toggling) return
        if (requiresSecureSettings && !Permissions.hasWriteSecureSettings(this)) {
            launchApp(LaunchRoutes.SETUP)
            return
        }
        if (requiresUnlock && isLocked) unlockAndRun(::onTap) else onTap()
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private fun runToggle() {
        toggling = true
        qsTile?.let {
            predict(it)
            it.updateTile()
        }
        scope.launch {
            try {
                withContext(Dispatchers.IO) { toggle() }
            } catch (e: Exception) {
                Log.e(javaClass.simpleName, "Toggle failed", e)
            } finally {
                toggling = false
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
        startActivityAndCollapseCompat(
            Intent(this, MainActivity::class.java).putExtra(LaunchRoutes.EXTRA_ROUTE, route),
        )
    }

    protected fun startActivityAndCollapseCompat(intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this, intent.component.hashCode(), intent,
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
