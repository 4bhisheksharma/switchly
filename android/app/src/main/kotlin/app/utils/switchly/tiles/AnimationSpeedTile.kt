package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.display.AnimationScale
import app.utils.switchly.tiles.base.BaseTile

/**
 * Moves to the next speed in the user's cycle (default Off → 0.5× → 1×).
 * Shown as active whenever the speed isn't the system default of 1×.
 */
class AnimationSpeedTile : BaseTile() {

    override fun render(tile: Tile) {
        val scale = AnimationScale.read(this).uniform
        tile.state = if (scale != null && AnimationScale.same(scale, 1f)) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.subtitle = scale?.let(AnimationScale::label) ?: "Custom"
    }

    override fun toggle() {
        val cycle = AnimationScale.cycle(this)
        val current = AnimationScale.read(this).uniform
        // -1 when the current speed isn't in the cycle (or the three scales differ) → first entry.
        val index = cycle.indexOfFirst { current != null && AnimationScale.same(it, current) }
        AnimationScale.set(this, cycle[(index + 1) % cycle.size])
    }
}
