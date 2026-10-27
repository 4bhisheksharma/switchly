package app.utils.switchly.display

import android.content.Context
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SecureSettings
import app.utils.switchly.core.SettingsTable
import app.utils.switchly.core.SharedConfig
import org.json.JSONException
import org.json.JSONObject
import kotlin.math.abs
import kotlin.math.roundToInt

/** System font size (Settings.System `font_scale`, 1.0 = default). */
object FontScale {
    private const val KEY = "font_scale"

    /** Used until the user edits the cycle. Keep in sync with display_models.dart. */
    private val DEFAULT_CYCLE = listOf(1f, 1.3f, 1.5f)

    fun read(context: Context): Float =
        SecureSettings.getString(context, SettingsTable.SYSTEM, KEY)?.toFloatOrNull() ?: 1f

    /** Apps redraw with the new size right away. Returns false if the write was refused. */
    fun set(context: Context, scale: Float): Boolean =
        SecureSettings.putString(context, SettingsTable.SYSTEM, KEY, scale.toString())

    /** The user's cycle from Flutter, or the default if it is unset or invalid. */
    fun cycle(context: Context): List<Float> {
        val json = SharedConfig.getString(context, PrefKeys.FONT_CONFIG) ?: return DEFAULT_CYCLE
        return try {
            val scales = JSONObject(json).getJSONArray("scales")
            (0 until scales.length()).map { scales.getDouble(it).toFloat() }.ifEmpty { DEFAULT_CYCLE }
        } catch (e: JSONException) {
            Log.w("FontScale", "Invalid font config, using defaults", e)
            DEFAULT_CYCLE
        }
    }

    fun label(scale: Float): String = "${(scale * 100).roundToInt()}%"

    fun same(a: Float, b: Float) = abs(a - b) < 0.01f
}
