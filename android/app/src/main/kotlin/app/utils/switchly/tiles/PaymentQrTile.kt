package app.utils.switchly.tiles

import android.content.Intent
import android.service.quicksettings.Tile
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.payments.PaymentQrActivity
import app.utils.switchly.payments.PaymentQrs
import app.utils.switchly.tiles.base.BaseTile

/**
 * Shows your payment QR full screen at maximum brightness, straight from Quick Settings and
 * even on the lock screen. Opens [PaymentQrActivity]; see there for why it isn't a tile dialog.
 */
class PaymentQrTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    override fun render(tile: Tile) {
        val qrs = PaymentQrs.all(this)
        tile.state = Tile.STATE_INACTIVE
        tile.subtitle = when (qrs.size) {
            0 -> "Tap to add"
            1 -> qrs.first().name
            else -> "${qrs.size} saved"
        }
    }

    override fun onTap() {
        if (PaymentQrs.all(this).isEmpty()) {
            launchApp(LaunchRoutes.tile("payment_qr"))
        } else {
            startActivityAndCollapseCompat(Intent(this, PaymentQrActivity::class.java))
        }
    }
}
