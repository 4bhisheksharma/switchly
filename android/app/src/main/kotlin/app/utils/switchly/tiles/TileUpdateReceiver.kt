package app.utils.switchly.tiles

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.utils.switchly.widgets.WidgetRefresher

/** After an app update, pushes fresh state (and icons) to every added tile and widget. */
class TileUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            TileRefresher.refreshAll(context)
            WidgetRefresher.refreshAll(context)
        }
    }
}
