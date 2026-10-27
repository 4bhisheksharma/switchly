package app.utils.switchly.tiles

import android.content.Intent
import android.service.quicksettings.Tile
import app.utils.switchly.scanner.ScannerActivity
import app.utils.switchly.tiles.base.BaseTile

/**
 * Opens the QR scanner. Asks for unlock on the lock screen because a scan can open links and
 * other apps.
 */
class QrScannerTile : BaseTile() {
    override val requiresSecureSettings = false

    override fun render(tile: Tile) {
        tile.state = Tile.STATE_INACTIVE
        tile.subtitle = "Tap to scan"
    }

    override fun onTap() {
        startActivityAndCollapseCompat(Intent(this, ScannerActivity::class.java))
    }
}
