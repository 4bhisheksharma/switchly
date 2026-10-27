package app.utils.switchly.tiles

import android.content.Intent
import android.provider.Settings
import android.service.quicksettings.Tile
import app.utils.switchly.core.SettingsTable
import app.utils.switchly.network.WirelessDebugging
import app.utils.switchly.tiles.base.SettingToggleTile

/**
 * Toggles ADB over Wi-Fi and shows the `ip:port` to connect to.
 * Always asks for unlock: opening a debugging port from the lock screen would be unsafe.
 */
class WirelessDebuggingTile : SettingToggleTile() {
    override val table = SettingsTable.GLOBAL
    override val key = WirelessDebugging.KEY
    override val onValue = "1"
    override val offValue = "0"

    override fun render(tile: Tile) {
        when {
            !WirelessDebugging.supported -> {
                tile.state = Tile.STATE_UNAVAILABLE
                tile.subtitle = "Needs Android 11"
            }
            !WirelessDebugging.devOptionsEnabled(this) -> {
                tile.state = Tile.STATE_INACTIVE
                tile.subtitle = "Enable Developer options"
            }
            currentlyOn() -> {
                tile.state = Tile.STATE_ACTIVE
                tile.subtitle = WirelessDebugging.address(this) ?: "Waiting for Wi-Fi"
            }
            else -> {
                tile.state = Tile.STATE_INACTIVE
                tile.subtitle = "Off"
            }
        }
    }

    override fun onTap() {
        if (!WirelessDebugging.devOptionsEnabled(this)) {
            startActivityAndCollapseCompat(Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS))
            return
        }
        super.onTap()
    }

    override fun toggle() {
        super.toggle()
        // adbd picks its port a moment after starting; wait briefly so the subtitle can show it.
        if (currentlyOn()) repeat(10) {
            if (WirelessDebugging.address(this)?.contains(':') == true) return
            Thread.sleep(150)
        }
    }
}
