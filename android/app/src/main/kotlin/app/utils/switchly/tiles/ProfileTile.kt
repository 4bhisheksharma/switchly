package app.utils.switchly.tiles

import android.app.AlertDialog
import android.service.quicksettings.Tile
import android.view.ContextThemeWrapper
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.profiles.Profiles
import app.utils.switchly.tiles.base.BaseTile
import kotlin.concurrent.thread

/**
 * Shows the user's profiles in a dialog over Quick Settings. Picking one applies it; while a
 * profile is active the dialog also offers "Restore previous settings".
 */
class ProfileTile : BaseTile() {

    /** The open dialog, so a second tap replaces it instead of stacking another. */
    private var dialog: AlertDialog? = null

    override fun render(tile: Tile) {
        val active = Profiles.active(this)
        tile.state = if (active != null) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.subtitle = active?.name ?: "None"
    }

    override fun onTap() {
        val profiles = Profiles.all(this)
        if (profiles.isEmpty()) {
            launchApp(LaunchRoutes.tile("profiles"))
            return
        }
        val activeId = Profiles.activeId(this)
        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight)
        val builder = AlertDialog.Builder(themed)
            .setTitle("Apply profile")
            .setSingleChoiceItems(
                profiles.map { it.name }.toTypedArray(),
                profiles.indexOfFirst { it.id == activeId },
            ) { dialog, which ->
                dialog.dismiss()
                runInBackground { Profiles.apply(this, profiles[which]) }
            }
            .setNegativeButton("Manage") { _, _ -> launchApp(LaunchRoutes.tile("profiles")) }
        if (activeId != null) {
            builder.setPositiveButton("Restore previous") { _, _ -> runInBackground { Profiles.restore(this) } }
        }
        dialog?.dismiss()
        dialog = builder.create().also(::showDialog)
    }

    override fun onDestroy() {
        dialog?.dismiss()
        dialog = null
        super.onDestroy()
    }

    private fun runInBackground(work: () -> Unit) {
        thread(name = "profile-apply") {
            work()
            mainExecutor.execute { refresh() }
        }
    }
}
