package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.display.FontScale
import app.utils.switchly.tiles.base.BaseTile

/**
 * Moves to the next font size in the user's cycle (default 100% → 130% → 150%).
 * Shown as active whenever the size isn't the system default.
 */
class FontSizeTile : BaseTile() {

    // Harmless display change: works straight from the lock screen.
    override val requiresUnlock = false

    override fun render(tile: Tile) {
        val scale = FontScale.read(this)
        tile.state = if (FontScale.same(scale, 1f)) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.subtitle = FontScale.label(scale)
    }

    override fun toggle() {
        val cycle = FontScale.cycle(this)
        val current = FontScale.read(this)
        // -1 when the current size isn't in the cycle → first entry.
        val index = cycle.indexOfFirst { FontScale.same(it, current) }
        FontScale.set(this, cycle[(index + 1) % cycle.size])
    }
}
