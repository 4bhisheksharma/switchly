package app.utils.switchly.tiles

import android.content.Intent
import android.service.quicksettings.Tile
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.R
import app.utils.switchly.accessibility.ScreenshotActionActivity
import app.utils.switchly.accessibility.SwitchlyAccessibilityService
import app.utils.switchly.tiles.base.BaseTile

class ScreenshotTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    override fun render(tile: Tile) {
        val ready = SwitchlyAccessibilityService.isRunning()
        tile.state = if (ready) Tile.STATE_INACTIVE else Tile.STATE_UNAVAILABLE
        tile.label = getString(R.string.tile_screenshot)
        tile.subtitle = if (ready) "Tap to capture" else "Tap to set up"
    }

    override fun onTap() {
        if (SwitchlyAccessibilityService.isRunning()) {
            startActivityAndCollapseCompat(Intent(this, ScreenshotActionActivity::class.java))
        } else {
            launchApp(LaunchRoutes.tile("screenshot"))
        }
    }
}

