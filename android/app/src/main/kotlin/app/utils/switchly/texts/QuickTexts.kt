package app.utils.switchly.texts

import android.content.Context
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import org.json.JSONArray
import org.json.JSONException

/** A saved snippet. Mirrors `QuickText` in lib/features/quick_texts/data/quick_text.dart. */
data class QuickText(val id: String, val title: String, val text: String) {
    /** The title, or the first line of the text when there is no title. */
    val displayTitle: String get() = title.ifBlank { text.lineSequence().first().take(60) }
}

object QuickTexts {
    /** Shown until the user saves their own list. Mirrors `QuickTextsRepository.defaults`. */
    private val DEFAULTS = listOf(QuickText("welcome", "Welcome", "Welcome to Switchly"))

    fun all(context: Context): List<QuickText> {
        val json = SharedConfig.getString(context, PrefKeys.QUICK_TEXTS) ?: return DEFAULTS
        return try {
            val array = JSONArray(json)
            (0 until array.length()).map {
                val o = array.getJSONObject(it)
                QuickText(o.optString("id"), o.optString("title"), o.optString("text"))
            }.filter { it.text.isNotEmpty() }
        } catch (e: JSONException) {
            Log.w("QuickTexts", "Invalid quick texts", e)
            emptyList()
        }
    }
}
