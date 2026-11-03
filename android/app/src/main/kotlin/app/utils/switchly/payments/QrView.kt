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
import android.widget.ScrollView
import android.widget.TextView
import app.utils.switchly.R

/** Built in code: a white rounded card with the QR, its name, brightness toggle, and a picker when there are several. */
class QrView(
    private val context: Context,
    private val qrs: List<PaymentQr>,
    initialFullBrightness: Boolean,
    private val onToggleBrightness: (Boolean) -> Unit,
    private val onClose: () -> Unit,
) {
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

    private var isFullBrightness = initialFullBrightness
    private lateinit var brightnessIcon: ImageView
    private lateinit var brightnessLabel: TextView
    private lateinit var brightnessPill: LinearLayout

    init {
        root.setOnClickListener { onClose() }
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            val pad = dp(24f).toInt()
            setPadding(pad, pad, pad, pad)
        }

        column.addView(topBar(), LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply {
            bottomMargin = dp(20f).toInt()
        })

        if (qrs.size > 1) column.addView(chipRow(), LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply {
            bottomMargin = dp(20f).toInt()
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
        val scroll = ScrollView(context).apply {
            isFillViewport = true
            isVerticalScrollBarEnabled = false
            setOnClickListener { onClose() }
        }
        scroll.addView(column, FrameLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT, Gravity.CENTER))
        root.addView(scroll, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        select(0)
    }

    private fun topBar(): View {
        val bar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            isClickable = true
        }

        // Close button
        val closeBtn = ImageView(context).apply {
            setImageResource(R.drawable.ic_close)
            setColorFilter(Color.WHITE)
            background = GradientDrawable().apply {
                cornerRadius = dp(99f)
                setColor(Color.argb(45, 255, 255, 255))
            }
            val pad = dp(10f).toInt()
            setPadding(pad, pad, pad, pad)
            val size = dp(42f).toInt()
            layoutParams = LinearLayout.LayoutParams(size, size)
            setOnClickListener { onClose() }
        }
        bar.addView(closeBtn)

        // Spacer to push brightness toggle to right
        val spacer = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, 1, 1f)
        }
        bar.addView(spacer)

        // Brightness toggle pill
        brightnessIcon = ImageView(context).apply {
            val size = dp(18f).toInt()
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                marginEnd = dp(6f).toInt()
            }
        }

        brightnessLabel = TextView(context).apply {
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.DEFAULT_BOLD
        }

        brightnessPill = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val h = dp(14f).toInt()
            val v = dp(8f).toInt()
            setPadding(h, v, h, v)
            background = GradientDrawable().apply {
                cornerRadius = dp(99f)
                setColor(Color.argb(45, 255, 255, 255))
            }
            addView(brightnessIcon)
            addView(brightnessLabel)
            setOnClickListener {
                isFullBrightness = !isFullBrightness
                updateBrightnessUi()
                onToggleBrightness(isFullBrightness)
            }
        }
        updateBrightnessUi()
        bar.addView(brightnessPill)

        return bar
    }

    private fun updateBrightnessUi() {
        if (isFullBrightness) {
            brightnessIcon.setImageResource(R.drawable.ic_brightness_high)
            brightnessIcon.setColorFilter(Color.parseColor("#FDE047"))
            brightnessLabel.text = "Max Brightness"
            brightnessLabel.setTextColor(Color.WHITE)
        } else {
            brightnessIcon.setImageResource(R.drawable.ic_brightness_normal)
            brightnessIcon.setColorFilter(Color.parseColor("#9CA3AF"))
            brightnessLabel.text = "Normal Brightness"
            brightnessLabel.setTextColor(Color.parseColor("#D1D5DB"))
        }
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
