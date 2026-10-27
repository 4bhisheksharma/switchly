package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.dns.PrivateDns
import app.utils.switchly.tiles.base.BaseTile

/**
 * Cycles Off → provider 1 → provider 2 → … → Off.
 *
 * "Automatic" or a host that isn't in the list (set from system Settings) counts as Off,
 * so the next tap always goes to the first provider.
 */
class PrivateDnsTile : BaseTile() {

    override fun render(tile: Tile) {
        val state = PrivateDns.read(this)
        when (state.mode) {
            PrivateDns.MODE_HOSTNAME -> {
                tile.state = Tile.STATE_ACTIVE
                tile.subtitle = providerName(state.hostname) ?: state.hostname ?: "Custom"
            }
            PrivateDns.MODE_OFF -> {
                tile.state = Tile.STATE_INACTIVE
                tile.subtitle = "Off"
            }
            else -> {
                tile.state = Tile.STATE_INACTIVE
                tile.subtitle = "Automatic"
            }
        }
    }

    override fun toggle() {
        val providers = PrivateDns.providers(this)
        val state = PrivateDns.read(this)
        // Position 0 is Off; providers occupy 1..n.
        val position = if (state.mode == PrivateDns.MODE_HOSTNAME) {
            providers.indexOfFirst { it.host.equals(state.hostname, ignoreCase = true) } + 1
        } else {
            0
        }
        val next = (position + 1) % (providers.size + 1)
        if (next == 0) PrivateDns.setOff(this) else PrivateDns.setHostname(this, providers[next - 1].host)
    }

    private fun providerName(host: String?): String? =
        PrivateDns.providers(this).firstOrNull { it.host.equals(host, ignoreCase = true) }?.name
}
