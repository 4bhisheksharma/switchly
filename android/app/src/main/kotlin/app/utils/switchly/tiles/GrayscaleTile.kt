package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.display.Grayscale
import app.utils.switchly.tiles.base.BaseTile

/** Toggles system-wide grayscale. Not a `SettingToggleTile` because it restores the previous colour-correction mode. */
class GrayscaleTile : BaseTile() {

    override fun render(tile: Tile) {
        val on = Grayscale.isOn(this)
        tile.state = if (on) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.subtitle = if (on) "On" else "Off"
    }

    override fun toggle() {
        Grayscale.set(this, !Grayscale.isOn(this))
    }
}
