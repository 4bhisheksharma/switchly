package app.utils.switchly.tiles

import android.service.quicksettings.Tile
import app.utils.switchly.dns.PrivateDns
import app.utils.switchly.tiles.base.BaseTile

/**
 * Moves to the next state in the user's cycle (Off → Automatic → providers…, each optional).
 *
 * If the current state isn't in the cycle (e.g. a host set from system Settings), the next
 * tap goes to the first state.
 */
class PrivateDnsTile : BaseTile() {

    override fun render(tile: Tile) {
        val state = PrivateDns.read(this)
        when (state.mode) {
            PrivateDns.MODE_HOSTNAME -> {
                tile.state = Tile.STATE_ACTIVE
                // The provider goes in the label so it shows on small tiles too.
                tile.label = PrivateDns.config(this).providers
                    .firstOrNull { it.host.equals(state.hostname, ignoreCase = true) }?.name
                    ?: state.hostname
                    ?: "Custom DNS"
                tile.subtitle = "Private DNS"
            }
            PrivateDns.MODE_OFF -> {
                tile.state = Tile.STATE_INACTIVE
                tile.subtitle = "Off"
            }
            else -> {
                tile.state = Tile.STATE_INACTIVE
                tile.label = "DNS Auto"
                tile.subtitle = "Automatic"
            }
        }
    }

    override fun toggle() {
        val cycle = PrivateDns.config(this).cycle()
        if (cycle.isEmpty()) return
        val state = PrivateDns.read(this)
        val current = cycle.indexOfFirst { state.matches(it) } // -1 → next is index 0
        PrivateDns.apply(this, cycle[(current + 1) % cycle.size])
    }
}
