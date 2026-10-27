package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import android.text.format.DateFormat
import app.utils.switchly.power.Caffeine
import app.utils.switchly.tiles.base.BaseTile

/**
 * Keeps the screen on. Each tap moves to the next duration (default 5 → 15 → 30 → 60 min →
 * no limit → off); the timer restarts from the tap.
 */
class CaffeineTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    override fun render(tile: Tile) {
        tile.state = if (Caffeine.isOn) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        if (Caffeine.isOn) {
            // The end time goes in the label so it shows on small tiles too.
            tile.label = if (Caffeine.endsAt == 0L) {
                "Awake"
            } else {
                "Until ${DateFormat.getTimeFormat(this).format(Caffeine.endsAt)}"
            }
            tile.subtitle = if (Caffeine.endsAt == 0L) "No time limit" else "Caffeine"
        } else {
            tile.subtitle = "Off"
        }
    }

    override fun predict(tile: Tile) {
        tile.state = if (Caffeine.next(this) == null) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
    }

    override fun announcement(tile: Tile): String =
        if (Caffeine.isOn) "Caffeine: ${tile.label}" else "Caffeine: Off"

    override fun toggle() {
        val next = Caffeine.next(this)
        if (next == null) Caffeine.stop(this) else Caffeine.start(this, next)
    }
}
