package app.utils.switchly.payments

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/** Built in code: a white rounded card with the QR, its name, and a picker when there are several. */
class QrView(private val context: Context, private val qrs: List<PaymentQr>, private val onClose: () -> Unit) {
    val root = FrameLayout(context)
    private val image = ImageView(context).apply {
        adjustViewBounds = true
        scaleType = ImageView.ScaleType.FIT_CENTER
    }
    private val name = TextView(context).apply {
        setTextColor(Color.WHITE)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
        typeface = Typeface.DEFAULT_BOLD
        gravity = Gravity.CENTER
    }
    private val chips = mutableListOf<TextView>()

    init {
        root.setOnClickListener { onClose() }
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            val pad = dp(24f).toInt()
            setPadding(pad, pad, pad, pad)
        }
        if (qrs.size > 1) column.addView(chipRow(), LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply {
            bottomMargin = dp(24f).toInt()
        })
        val card = FrameLayout(context).apply {
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
            TextView(context).apply {
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
        val row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        qrs.forEachIndexed { index, qr ->
            val chip = TextView(context).apply {
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
        return HorizontalScrollView(context).apply {
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

    private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, context.resources.displayMetrics)
}
