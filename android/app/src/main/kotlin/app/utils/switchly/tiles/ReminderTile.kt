package app.utils.switchly.tiles

import android.content.Intent
import android.service.quicksettings.Tile
import app.utils.switchly.reminders.ReminderQuickActivity
import app.utils.switchly.reminders.Reminders
import app.utils.switchly.tiles.base.BaseTile

/** Shows upcoming reminders status and opens a fast dialog to manage, done, or add reminders. */
class ReminderTile : BaseTile() {
    override val requiresSecureSettings = false

    override fun render(tile: Tile) {
        val upcoming = Reminders.upcoming(this)
        if (upcoming.isEmpty()) {
            tile.state = Tile.STATE_INACTIVE
            tile.subtitle = "None scheduled"
            return
        }
        tile.state = Tile.STATE_ACTIVE
        val next = upcoming.first()
        val timeText = Reminders.formatCompactTileTime(this, next.scheduledAtMillis)
        tile.subtitle = if (upcoming.size == 1) {
            timeText
        } else {
            "$timeText (+${upcoming.size - 1})"
        }
    }

    override fun onTap() {
        startActivityAndCollapseCompat(Intent(this, ReminderQuickActivity::class.java))
    }
}
