package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.publicmode.PublicMode
import app.utils.switchly.tiles.base.BaseTile
import kotlin.concurrent.thread

/**
 * Quick Settings tile to activate/deactivate Public Mode in one tap.
 */
class PublicModeTile : BaseTile() {

    override fun render(tile: Tile) {
        val active = PublicMode.isActive(this)
        tile.state = if (active) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = "Public Mode"
        tile.subtitle = if (active) {
            val endsAt = PublicMode.endsAt(this)
            if (endsAt > 0) {
                val remainingMins = ((endsAt - System.currentTimeMillis()) / 60_000L).coerceAtLeast(0)
                if (remainingMins > 0) "${remainingMins}m left" else "Ending"
            } else {
                "Active"
            }
        } else {
            "Hand over"
        }
    }

    override fun onTap() {
        val active = PublicMode.isActive(this)
        if (active) {
            // Disabling always requires PIN authentication via the app
            launchApp(LaunchRoutes.tile("public_mode"))
        } else {
            val config = PublicMode.config(this)
            if (config.pin.isNullOrBlank()) {
                // Enabling requires a PIN to be configured first; route to setup
                launchApp(LaunchRoutes.tile("public_mode"))
                return
            }
            runInBackground { PublicMode.activate(this) }
        }
    }

    private fun runInBackground(work: () -> Unit) {
        thread(name = "public-mode-toggle") {
            work()
            TileRefresher.refreshAll(this)
            mainExecutor.execute { refresh() }
        }
    }
}
