package app.utils.switchly
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService
import app.utils.switchly.tiles.TileRegistry

/**
 * Flutter routes that native code can ask the app to open. Flutter treats these as hints
 * and ignores anything it doesn't recognise (MainActivity is exported).
 */
object LaunchRoutes {
    const val EXTRA_ROUTE = "app.utils.switchly.ROUTE"
    const val SETUP = "/setup"

    fun tile(id: String) = "/tile/$id"

    /** The route for a launch intent: a tile tap, a tile long-press, or null for a normal launch. */
    fun fromIntent(intent: Intent?): String? {
        intent ?: return null
        if (intent.action == TileService.ACTION_QS_TILE_PREFERENCES) {
            val component = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_COMPONENT_NAME, ComponentName::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_COMPONENT_NAME)
            }
            return TileRegistry.byComponent(component)?.let { tile(it.id) }
        }
        return intent.getStringExtra(EXTRA_ROUTE)
    }
}
