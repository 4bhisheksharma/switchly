package app.utils.switchly.tiles

import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.service.quicksettings.Tile
import android.view.ContextThemeWrapper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.Toast
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.R
import app.utils.switchly.texts.QuickText
import app.utils.switchly.texts.QuickTexts
import app.utils.switchly.tiles.base.BaseTile

/**
 * Shows saved snippets in a dialog straight from the tile (no activity launch, so it opens
 * instantly); tapping one copies it. Asks for unlock first because snippets can be personal.
 */
class QuickTextsTile : BaseTile() {
    override val requiresSecureSettings = false

    /** The open dialog, so a second tap replaces it instead of stacking another. */
    private var dialog: AlertDialog? = null

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
        val texts = QuickTexts.all(this)
        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight)
        val builder = AlertDialog.Builder(themed)
            .setTitle("Quick texts")
            .setNeutralButton("Manage") { _, _ -> launchApp(LaunchRoutes.tile("quick_texts")) }
        if (texts.isEmpty()) {
            builder.setMessage("Save snippets like your address, account number or a message you send often.")
                .setPositiveButton("Add one") { _, _ -> launchApp(LaunchRoutes.tile("quick_texts")) }
        } else {
            builder.setAdapter(adapter(themed, texts)) { _, which -> copy(texts[which]) }
        }
        dialog?.dismiss()
        dialog = builder.create().also(::showDialog)
    }

    override fun onDestroy() {
        dialog?.dismiss()
        dialog = null
        super.onDestroy()
    }

    private fun adapter(context: Context, texts: List<QuickText>) =
        object : ArrayAdapter<QuickText>(context, R.layout.item_quick_text, texts) {
            private val inflater = LayoutInflater.from(context)

            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val view = convertView ?: inflater.inflate(R.layout.item_quick_text, parent, false)
                val item = texts[position]
                view.findViewById<TextView>(R.id.title).text = item.displayTitle
                view.findViewById<TextView>(R.id.preview).text = item.text
                return view
            }
        }

    private fun copy(item: QuickText) {
        getSystemService(ClipboardManager::class.java)
            .setPrimaryClip(ClipData.newPlainText(item.displayTitle, item.text))
        // Android 13+ shows its own clipboard confirmation.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Toast.makeText(this, "Copied “${item.displayTitle}”", Toast.LENGTH_SHORT).show()
        }
    }
}
