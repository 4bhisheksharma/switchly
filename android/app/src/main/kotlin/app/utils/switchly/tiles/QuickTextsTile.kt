package app.utils.switchly.tiles

import android.content.Intent
import android.service.quicksettings.Tile
import app.utils.switchly.texts.QuickTexts
import app.utils.switchly.texts.QuickTextsActivity
import app.utils.switchly.tiles.base.BaseTile

/**
 * Shows saved snippets in a fast dialog activity; tapping one copies it.
 *
 * Uses QuickTextsActivity rather than TileService.showDialog() so that Xiaomi/Redmi
 * (MIUI/HyperOS) and OEM launchers that drop tile dialog tokens or restrict background
 * popups render the dialog reliably every time.
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
