package app.utils.switchly.tiles

import android.content.Intent
import android.service.quicksettings.Tile
import app.utils.switchly.texts.QuickTexts
import app.utils.switchly.texts.QuickTextsActivity
import app.utils.switchly.tiles.base.BaseTile

/**
 * Opens a list of saved snippets; tapping one copies it. Asks for unlock first because
 * snippets can be personal (addresses, account numbers).
 */
class QuickTextsTile : BaseTile() {
    override val requiresSecureSettings = false

    override fun render(tile: Tile) {
        val count = QuickTexts.all(this).size
        tile.state = Tile.STATE_INACTIVE
        tile.subtitle = when (count) {
            0 -> "None saved"
            1 -> "1 saved"
            else -> "$count saved"
        }
    }

    override fun onTap() {
        startActivityAndCollapseCompat(Intent(this, QuickTextsActivity::class.java))
    }
}
