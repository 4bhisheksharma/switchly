package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.audio.MicRouter
import app.utils.switchly.tiles.base.BaseTile

/**
 * Quick Settings tile to switch between available microphones:
 * Phone Mic (Built-in) → Earbuds Mic (Bluetooth) → Earphones Mic (Wired/USB) → Auto.
 */
class MicSwitcherTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    override fun onStartListening() {
        super.onStartListening()
        MicRouter.ensureListeners(this)
    }

    override fun render(tile: Tile) {
        val mode = MicRouter.getCurrentMode(this)
        val (label, subtitle) = MicRouter.modeLabel(this, mode)

        tile.state = if (mode == MicRouter.MODE_AUTO) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.label = label
        tile.subtitle = subtitle
    }

    override fun predict(tile: Tile) {
        val available = MicRouter.getAvailableModes(this)
        val current = MicRouter.getCurrentMode(this)
        val currentIndex = available.indexOf(current)
        val nextMode = if (currentIndex == -1) available.first() else available[(currentIndex + 1) % available.size]

        tile.state = if (nextMode == MicRouter.MODE_AUTO) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        val (label, subtitle) = MicRouter.modeLabel(this, nextMode)
        tile.label = label
        tile.subtitle = subtitle
    }

    override fun announcement(tile: Tile): String =
        "Microphone: ${tile.label} (${tile.subtitle})"

    override fun toggle() {
        MicRouter.cycleNextMode(this)
    }
}
