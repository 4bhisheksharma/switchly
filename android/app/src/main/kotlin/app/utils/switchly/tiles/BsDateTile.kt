package app.utils.switchly.tiles

import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.view.ContextThemeWrapper
import android.widget.Toast
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.calendar.BikramSambat
import app.utils.switchly.tiles.base.BaseTile
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Today's Bikram Sambat date, with the day number drawn into the icon. Tapping shows the full
 * BS and AD dates with a copy button.
 *
 * Unlike the other tiles this is NOT an active tile: it must re-render whenever the panel
 * opens so the date rolls over at midnight without alarms or boot receivers.
 */
class BsDateTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    private var dialog: AlertDialog? = null

    override fun render(tile: Tile) {
        val nepali = BikramSambat.useNepali(this)
        val today = LocalDate.now()
        val bs = BikramSambat.fromAd(today) ?: return
        tile.state = Tile.STATE_ACTIVE
        tile.label = "${BikramSambat.monthName(bs.month, nepali)} ${BikramSambat.digits(bs.day, nepali)}"
        tile.subtitle = "${BikramSambat.weekday(today.dayOfWeek, nepali)} · ${BikramSambat.digits(bs.year, nepali)}"
        tile.icon = dayIcon(BikramSambat.digits(bs.day, nepali))
    }

    override fun onTap() {
        val nepali = BikramSambat.useNepali(this)
        val today = LocalDate.now()
        val bs = BikramSambat.fromAd(today) ?: return
        val bsText = "${BikramSambat.weekday(today.dayOfWeek, nepali)}, ${BikramSambat.format(bs, nepali)}"
        val adText = today.format(DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy", Locale.ENGLISH))
        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight)
        dialog?.dismiss()
        dialog = AlertDialog.Builder(themed)
            .setTitle(BikramSambat.format(bs, nepali))
            .setMessage("$bsText\n$adText")
            .setPositiveButton("Copy") { _, _ -> copy(BikramSambat.format(bs, nepali)) }
            .setNeutralButton("Calendar") { _, _ -> launchApp(LaunchRoutes.tile("bs_date")) }
            .create()
            .also(::showDialog)
    }

    override fun onDestroy() {
        dialog?.dismiss()
        dialog = null
        super.onDestroy()
    }

    private fun copy(text: String) {
        getSystemService(ClipboardManager::class.java).setPrimaryClip(ClipData.newPlainText("BS date", text))
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Toast.makeText(this, "Copied $text", Toast.LENGTH_SHORT).show()
        }
    }

    /** A small calendar outline with the day number, drawn white so the system can tint it. */
    private fun dayIcon(day: String): Icon {
        val size = (24 * resources.displayMetrics.density).toInt().coerceAtLeast(48)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val stroke = size * 0.08f
        val frame = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = stroke
        }
        val rect = RectF(stroke, size * 0.14f, size - stroke, size - stroke)
        canvas.drawRoundRect(rect, size * 0.16f, size * 0.16f, frame)
        val header = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
        canvas.drawRect(rect.left, rect.top, rect.right, rect.top + size * 0.18f, header)
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            typeface = Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
            textSize = size * if (day.length > 1) 0.42f else 0.5f
        }
        val baseline = rect.top + size * 0.18f + (rect.bottom - rect.top - size * 0.18f) / 2 - (text.descent() + text.ascent()) / 2
        canvas.drawText(day, rect.centerX(), baseline, text)
        return Icon.createWithBitmap(bitmap)
    }
}
