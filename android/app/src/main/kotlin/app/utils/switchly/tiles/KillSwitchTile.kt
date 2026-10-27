package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.network.KillSwitch
import app.utils.switchly.tiles.base.BaseTile

/**
 * Blocks or restores internet access. Needs no special permission, only the one-time VPN
 * consent, which the app asks for (the tile opens it when consent is missing).
 */
class KillSwitchTile : BaseTile() {
    override val requiresSecureSettings = false

    override fun render(tile: Tile) {
        val on = KillSwitch.isOn()
        tile.state = if (on) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.subtitle = if (on) "Internet blocked" else "Off"
    }

    override fun predict(tile: Tile) {
        val turningOn = tile.state != Tile.STATE_ACTIVE
        tile.state = if (turningOn) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.subtitle = if (turningOn) "Internet blocked" else "Off"
    }

    override fun onTap() {
        if (!KillSwitch.isOn() && !KillSwitch.hasConsent(this)) {
            launchApp(LaunchRoutes.tile("kill_switch"))
            return
        }
        super.onTap()
    }

    override fun toggle() {
        val turnOn = !KillSwitch.isOn()
        if (turnOn) KillSwitch.start(this) else KillSwitch.stop(this)
        KillSwitch.awaitState(turnOn)
    }
}
