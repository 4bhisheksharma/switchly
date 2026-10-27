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

/**
 * The three animation scales from Developer options (Settings.Global), always set together.
 */
object AnimationScale {
    private val KEYS = listOf("window_animation_scale", "transition_animation_scale", "animator_duration_scale")

    /** Used until the user edits the cycle. Keep in sync with display_models.dart. */
    private val DEFAULT_CYCLE = listOf(0f, 0.5f, 1f)

    data class Scales(val window: Float, val transition: Float, val animator: Float) {
        /** The shared scale, or null if they differ (set individually in Developer options). */
        val uniform: Float? get() = window.takeIf { same(it, transition) && same(it, animator) }
    }

    fun read(context: Context): Scales {
        val (window, transition, animator) = KEYS.map { key ->
            SecureSettings.getString(context, SettingsTable.GLOBAL, key)?.toFloatOrNull() ?: 1f
        }
        return Scales(window, transition, animator)
    }

    /** Writes all three scales. Returns false if any write was refused. */
    fun set(context: Context, scale: Float): Boolean =
        KEYS.map { SecureSettings.putString(context, SettingsTable.GLOBAL, it, scale.toString()) }.all { it }

    /** The user's cycle from Flutter, or the default if it is unset or invalid. */
    fun cycle(context: Context): List<Float> {
        val json = SharedConfig.getString(context, PrefKeys.ANIMATION_CONFIG) ?: return DEFAULT_CYCLE
        return try {
            val speeds = JSONObject(json).getJSONArray("speeds")
            (0 until speeds.length()).map { speeds.getDouble(it).toFloat() }.ifEmpty { DEFAULT_CYCLE }
        } catch (e: JSONException) {
            Log.w("AnimationScale", "Invalid animation config, using defaults", e)
            DEFAULT_CYCLE
        }
    }

    fun label(scale: Float): String = when {
        same(scale, 0f) -> "Off"
        same(scale, scale.toInt().toFloat()) -> "${scale.toInt()}×"
        else -> "$scale×"
    }

    fun same(a: Float, b: Float) = abs(a - b) < 0.01f
}
