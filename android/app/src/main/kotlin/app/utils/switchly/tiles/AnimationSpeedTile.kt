package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.display.AnimationScale
import app.utils.switchly.tiles.base.BaseTile

/**
 * Moves to the next speed in the user's cycle (default Off → 0.5× → 1×).
 * Shown as active whenever the speed isn't the system default of 1×.
 */
class AnimationSpeedTile : BaseTile() {

    // Harmless display change: works straight from the lock screen.
    override val requiresUnlock = false

    override fun render(tile: Tile) {
        val scale = AnimationScale.read(this).uniform
        tile.state = if (scale != null && AnimationScale.same(scale, 1f)) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        // The value goes in the label so it shows on small tiles too.
        tile.label = "Anim ${scale?.let(AnimationScale::label) ?: "Custom"}"
        tile.subtitle = when {
            scale == null -> "Custom speeds"
            AnimationScale.same(scale, 0f) -> "No animations"
            scale < 1f -> "Faster"
            AnimationScale.same(scale, 1f) -> "Default"
            else -> "Slower"
        }
    }

    override fun announcement(tile: Tile): String =
        "Animation speed: ${AnimationScale.read(this).uniform?.let(AnimationScale::label) ?: "Custom"}"

    override fun toggle() {
        val cycle = AnimationScale.cycle(this)
        val current = AnimationScale.read(this).uniform
        // -1 when the current speed isn't in the cycle (or the three scales differ) → first entry.
        val index = cycle.indexOfFirst { current != null && AnimationScale.same(it, current) }
        AnimationScale.set(this, cycle[(index + 1) % cycle.size])
    }
}
