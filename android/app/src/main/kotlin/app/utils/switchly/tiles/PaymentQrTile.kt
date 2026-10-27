package app.utils.switchly.tiles

import android.app.Dialog
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.service.quicksettings.Tile
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.payments.PaymentQr
import app.utils.switchly.payments.PaymentQrs
import app.utils.switchly.tiles.base.BaseTile

/**
 * Shows your payment QR full screen at maximum brightness, straight from Quick Settings and
 * even on the lock screen (a receive-only QR is safe to show; it can't send money). Shown as a
 * tile dialog rather than an activity so it opens instantly.
 */
class PaymentQrTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    private var dialog: Dialog? = null

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
        val qrs = PaymentQrs.all(this)
        if (qrs.isEmpty()) {
            launchApp(LaunchRoutes.tile("payment_qr"))
            return
        }
        dialog?.dismiss()
        dialog = Dialog(this, android.R.style.Theme_DeviceDefault_NoActionBar_Fullscreen).apply {
            setContentView(QrView(qrs) { dismiss() }.root)
            window?.apply {
                setBackgroundDrawable(ColorDrawable(Color.argb(235, 8, 8, 12)))
                // Max brightness and screen kept on while showing, so scanners read it first time.
                attributes = attributes.apply { screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_FULL }
                addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }.also(::showDialog)
    }

    override fun onDestroy() {
        dialog?.dismiss()
        dialog = null
        super.onDestroy()
    }

    private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

    /** Built in code: a white rounded card with the QR, its name, and a picker when there are several. */
    private inner class QrView(private val qrs: List<PaymentQr>, private val onClose: () -> Unit) {
        val root = FrameLayout(this@PaymentQrTile)
        private val image = ImageView(this@PaymentQrTile).apply {
            adjustViewBounds = true
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        private val name = TextView(this@PaymentQrTile).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        private val chips = mutableListOf<TextView>()

        init {
            root.setOnClickListener { onClose() }
            val column = LinearLayout(this@PaymentQrTile).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                val pad = dp(24f).toInt()
                setPadding(pad, pad, pad, pad)
            }
            if (qrs.size > 1) column.addView(chipRow(), LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply {
                bottomMargin = dp(24f).toInt()
            })
            val card = FrameLayout(this@PaymentQrTile).apply {
                background = GradientDrawable().apply {
                    setColor(Color.WHITE)
                    cornerRadius = dp(28f)
                }
                val pad = dp(20f).toInt()
                setPadding(pad, pad, pad, pad)
                isClickable = true // Taps on the QR itself don't close it.
                addView(image, FrameLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))
            }
            column.addView(card, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))
            column.addView(name, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(20f).toInt() })
            column.addView(
                TextView(this@PaymentQrTile).apply {
                    text = "Tap outside to close"
                    setTextColor(Color.argb(150, 255, 255, 255))
                    gravity = Gravity.CENTER
                },
                LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(8f).toInt() },
            )
            root.addView(column, FrameLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT, Gravity.CENTER))
            select(0)
        }

        private fun chipRow(): View {
            val row = LinearLayout(this@PaymentQrTile).apply { orientation = LinearLayout.HORIZONTAL }
            qrs.forEachIndexed { index, qr ->
                val chip = TextView(this@PaymentQrTile).apply {
                    text = qr.name
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    typeface = Typeface.DEFAULT_BOLD
                    val h = dp(18f).toInt()
                    val v = dp(10f).toInt()
                    setPadding(h, v, h, v)
                    setOnClickListener { select(index) }
                }
                chips += chip
                row.addView(chip, LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { marginEnd = dp(8f).toInt() })
            }
            return HorizontalScrollView(this@PaymentQrTile).apply {
                isHorizontalScrollBarEnabled = false
                addView(row)
            }
        }

        private fun select(index: Int) {
            val qr = qrs[index]
            image.setImageBitmap(decode(qr.path))
            name.text = qr.name
            chips.forEachIndexed { i, chip ->
                val selected = i == index
                chip.setTextColor(if (selected) Color.BLACK else Color.WHITE)
                chip.background = GradientDrawable().apply {
                    cornerRadius = dp(99f)
                    setColor(if (selected) Color.WHITE else Color.argb(40, 255, 255, 255))
                }
            }
        }

        /** Downsamples large screenshots; a QR needs ~1000px at most. */
        private fun decode(path: String): Bitmap? {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= 1000 && bounds.outHeight / (sample * 2) >= 1000) sample *= 2
            return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        }
    }
}
