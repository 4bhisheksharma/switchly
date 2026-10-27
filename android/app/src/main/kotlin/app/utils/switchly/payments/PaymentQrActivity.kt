package app.utils.switchly.payments

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.WindowManager

/**
 * Full-screen payment QR at maximum brightness, opened by the Payment QR tile.
 *
 * A plain (non-Flutter) activity so it opens quickly, and an activity rather than a tile dialog
 * because TileService.showDialog only works while SystemUI is listening to the tile, which
 * some launchers (notably MIUI's Control Center) don't guarantee: the dialog would silently not
 * appear. Shown over the lock screen: a receive-only QR can't be used to take money.
 */
class PaymentQrActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val qrs = PaymentQrs.all(this)
        if (qrs.isEmpty()) {
            finish()
            return
        }
        setShowWhenLocked(true)
        window.apply {
            setBackgroundDrawable(ColorDrawable(Color.rgb(8, 8, 12)))
            // Max brightness and screen kept on while showing, so scanners read it first time.
            attributes = attributes.apply { screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_FULL }
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        setContentView(QrView(this, qrs, ::finish).root)
    }
}
