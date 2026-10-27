package app.utils.switchly.power

import android.content.Context
import android.content.Intent
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import org.json.JSONException
import org.json.JSONObject

/**
 * Keeps the screen on for a while ([CaffeineService] holds the wake lock).
 *
 * State lives in memory: if the process dies the wake lock goes with it, so "off" is right.
 */
object Caffeine {
    /** Used until the user edits them. Keep in sync with caffeine_models.dart. 0 = no time limit. */
    private val DEFAULT_MINUTES = listOf(5, 15, 30, 60, 0)

    data class Config(val minutes: List<Int>, val stopOnLock: Boolean)

    /** The running session's duration in minutes (0 = no limit), or null when off. */
    @Volatile
    var minutes: Int? = null
        internal set

    /** When the running session ends (epoch millis), or 0 for no limit / off. */
    @Volatile
    var endsAt: Long = 0
        internal set

    val isOn: Boolean get() = minutes != null

    fun config(context: Context): Config {
        val json = SharedConfig.getString(context, PrefKeys.CAFFEINE_CONFIG)
            ?: return Config(DEFAULT_MINUTES, true)
        return try {
            val o = JSONObject(json)
            val array = o.optJSONArray("minutes")
            val minutes = array?.let { a -> (0 until a.length()).map { a.getInt(it) } }.orEmpty()
            Config(minutes.ifEmpty { DEFAULT_MINUTES }, o.optBoolean("stopOnLock", true))
        } catch (e: JSONException) {
            Log.w("Caffeine", "Invalid caffeine config, using defaults", e)
            Config(DEFAULT_MINUTES, true)
        }
    }

    /**
     * Starts (or restarts) for [minutes]; 0 means until turned off. State is set before the
     * service starts so a tile redraw right after shows it. Returns false if Android refused.
     */
    fun start(context: Context, minutes: Int): Boolean {
        this.minutes = minutes
        endsAt = if (minutes > 0) System.currentTimeMillis() + minutes * 60_000L else 0
        return try {
            context.startForegroundService(
                Intent(context, CaffeineService::class.java).putExtra(CaffeineService.EXTRA_MINUTES, minutes),
            )
            true
        } catch (e: IllegalStateException) {
            // ForegroundServiceStartNotAllowedException (API 31+) when started from the background.
            Log.w("Caffeine", "Couldn't start", e)
            clear()
            false
        }
    }

    fun stop(context: Context): Boolean {
        clear()
        context.stopService(Intent(context, CaffeineService::class.java))
        return true
    }

    /** The next step when the tile is tapped: the duration after the current one, or null = off. */
    fun next(context: Context): Int? {
        val options = config(context).minutes
        val current = minutes ?: return options.first()
        return options.getOrNull(options.indexOf(current) + 1)
    }

    internal fun clear() {
        minutes = null
        endsAt = 0
    }
}
