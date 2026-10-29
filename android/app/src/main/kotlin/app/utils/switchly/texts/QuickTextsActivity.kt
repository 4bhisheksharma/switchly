package app.utils.switchly.texts

import android.app.Activity
import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.ContextThemeWrapper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.Toast
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R

/**
 * Lightweight dialog activity opened by the Quick Texts tile.
 *
 * An activity rather than TileService.showDialog() because SystemUI on several
 * OEM launchers (notably Xiaomi MIUI / HyperOS) drops dialog windows attached
 * to tiles or restricts background service popups. Running as a foreground activity
 * ensures reliable window rendering and foreground clipboard access across all devices.
 */
class QuickTextsActivity : Activity() {
    private var dialog: AlertDialog? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)

        val texts = QuickTexts.all(this)
        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight)
        val builder = AlertDialog.Builder(themed)
            .setTitle(getString(R.string.tile_quick_texts))
            .setNeutralButton("Manage") { _, _ ->
                openManage()
            }
            .setOnCancelListener {
                finish()
            }

        if (texts.isEmpty()) {
            builder.setMessage("Save snippets like your address, account number or a message you send often.")
                .setPositiveButton("Add one") { _, _ ->
                    openManage()
                }
        } else {
            builder.setAdapter(adapter(themed, texts)) { _, which ->
                copy(texts[which])
                finish()
            }
        }

        dialog = builder.create().apply {
            setOnDismissListener { finish() }
            show()
        }
    }

    private fun openManage() {
        val intent = Intent(this, MainActivity::class.java).apply {
            putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("quick_texts"))
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
        finish()
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
        val clip = ClipData.newPlainText(item.displayTitle, item.text)
        val cm = getSystemService(ClipboardManager::class.java)
        cm?.setPrimaryClip(clip)

        // Android 13+ displays its own clipboard overlay notification on copy.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Toast.makeText(this, "Copied “${item.displayTitle}”", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onDestroy() {
        dialog?.dismiss()
        dialog = null
        super.onDestroy()
    }
}
