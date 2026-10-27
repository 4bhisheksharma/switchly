package app.utils.switchly.tiles.base

import android.service.quicksettings.Tile
import app.utils.switchly.core.SecureSettings
import app.utils.switchly.core.SettingsTable

/**
 * A tile that flips one Settings key between [onValue] and [offValue].
 *
 * ```
 * class WirelessDebuggingTile : SettingToggleTile() {
 *     override val table = SettingsTable.GLOBAL
 *     override val key = "adb_wifi_enabled"
 *     override val onValue = "1"
 *     override val offValue = "0"
 * }
 * ```
 */
abstract class SettingToggleTile : BaseTile() {
    protected abstract val table: SettingsTable
    protected abstract val key: String
    protected abstract val onValue: String
    protected abstract val offValue: String

    /** Override when "on" covers more than one stored value. An unset key counts as off. */
    protected open fun isOn(value: String?): Boolean = value == onValue

    /** Hook for tiles that need companion keys written before switching on (e.g. grayscale mode). */
    protected open fun beforeEnable() {}

    protected fun currentlyOn(): Boolean = isOn(SecureSettings.getString(this, table, key))

    override fun render(tile: Tile) {
        val on = currentlyOn()
        tile.state = if (on) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.subtitle = if (on) "On" else "Off"
    }

    override fun predict(tile: Tile) {
        val turningOn = tile.state != Tile.STATE_ACTIVE
        tile.state = if (turningOn) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.subtitle = if (turningOn) "On" else "Off"
    }

    override fun toggle() {
        if (currentlyOn()) {
            SecureSettings.putString(this, table, key, offValue)
        } else {
            beforeEnable()
            SecureSettings.putString(this, table, key, onValue)
        }
    }
}
