package app.utils.switchly.tiles

import android.content.ComponentName
import android.content.Context
import android.service.quicksettings.TileService
import android.util.Log

/**
 * Our tiles are "active" tiles (ACTIVE_TILE in the manifest): Android shows their last state
 * without keeping them bound, and only binds on a tap or when asked. That avoids the system's
 * small limit on bound tile services, which otherwise delays and drops taps once several
 * custom tiles are added. The cost is that state changes made elsewhere must be pushed:
 * call this after anything changes a tile's state.
 */
object TileRefresher {
    fun refreshAll(context: Context) {
        TileRegistry.all.forEach { refresh(context, it.service) }
    }

    fun refresh(context: Context, service: Class<out TileService>) {
        try {
            TileService.requestListeningState(context, ComponentName(context, service))
        } catch (e: RuntimeException) {
            // Thrown on some builds when the tile isn't added; nothing to refresh then.
            Log.d("TileRefresher", "Couldn't refresh ${service.simpleName}", e)
        }
    }
}
