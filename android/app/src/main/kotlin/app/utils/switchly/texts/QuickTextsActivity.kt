package app.utils.switchly.texts

import android.app.Activity
import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.ContextThemeWrapper
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.Toast
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R

/**
 * Transparent activity opened by the Quick texts tile. Showing the list here (instead of a
 * dialog inside the shade) collapses Quick Settings, so after copying the user is straight
 * back in the app they were typing in.
 */
class QuickTextsActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight)
        val texts = QuickTexts.all(this)

        val builder = AlertDialog.Builder(themed)
            .setTitle("Quick texts")
            .setNeutralButton("Manage") { _, _ -> openApp() }
            .setOnDismissListener { finish() }

        if (texts.isEmpty()) {
            builder.setMessage("Save snippets like your address, account number or a message you send often.")
                .setPositiveButton("Add one") { _, _ -> openApp() }
        } else {
            builder.setAdapter(adapter(themed, texts)) { _, which -> copy(texts[which]) }
                .setNegativeButton(android.R.string.cancel, null)
        }
        builder.show()
    }

    private fun adapter(context: android.content.Context, texts: List<QuickText>) =
        object : ArrayAdapter<QuickText>(context, R.layout.item_quick_text, texts) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val view = convertView ?: layoutInflater.cloneInContext(context)
                    .inflate(R.layout.item_quick_text, parent, false)
                val item = texts[position]
                view.findViewById<TextView>(R.id.title).text = item.displayTitle
                view.findViewById<TextView>(R.id.preview).text = item.text
                return view
            }
        }

    private fun copy(item: QuickText) {
        val clipboard = getSystemService(ClipboardManager::class.java)
        clipboard.setPrimaryClip(ClipData.newPlainText(item.displayTitle, item.text))
        // Android 13+ shows its own clipboard confirmation.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Toast.makeText(this, "Copied “${item.displayTitle}”", Toast.LENGTH_SHORT).show()
        }
    }

    private fun openApp() {
        startActivity(
            Intent(this, MainActivity::class.java)
                .putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("quick_texts"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }
}
