package app.utils.switchly.core

import android.content.Context
import android.content.SharedPreferences

/** Key names written by the Flutter side. Keep in sync with lib/core/storage/pref_keys.dart. */
object PrefKeys {
    /** JSON: `{"includeOff", "includeAutomatic", "providers": [{"id", "name", "host", "enabled"}]}`. */
    const val DNS_CONFIG = "dns_config"

    /** JSON: `{"speeds": [Double]}` in tap order. */
    const val ANIMATION_CONFIG = "animation_config"

    /** JSON array of `{"id", "title", "text"}`. */
    const val QUICK_TEXTS = "quick_texts"

    /** JSON: `{"allowedApps": [packageName]}`: apps that stay online. */
    const val KILL_SWITCH_CONFIG = "kill_switch_config"

    /** JSON array of profiles; see profiles/Profiles.kt for the shape. */
    const val PROFILES = "profiles"

    /** JSON: `{"nepali": Boolean}`: Devanagari or English for the BS date. */
    const val BS_CONFIG = "bs_config"

    /** JSON array of `{"id", "name", "path"}`; path is an image in the app's files dir. */
    const val PAYMENT_QRS = "payment_qrs"

    /** JSON: `{"scales": [Double]}` in tap order. */
    const val FONT_CONFIG = "font_config"

    /** JSON: `{"minutes": [Int], "stopOnLock": Boolean}`; 0 minutes means no time limit. */
    const val CAFFEINE_CONFIG = "caffeine_config"

    /** Boolean: show a message at the top after a tile tap (closes the panel). Default false. */
    const val SHOW_TILE_MESSAGE = "show_tile_message"

    /** JSON: `{"packageName", "appName", "openAppOnTap"}`. */
    const val APP_USAGE_CONFIG = "app_usage_config"

    /** JSON: Public mode config. */
    const val PUBLIC_MODE_CONFIG = "public_mode_config"
}

/**
 * Read-only view of the config Flutter writes with the legacy `SharedPreferences` API.
 *
 * That API stores everything in the `FlutterSharedPreferences` file with a `flutter.`
 * prefix. Complex values are stored as JSON strings so they can be parsed here.
 */
object SharedConfig {
    private const val FILE = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun getString(context: Context, key: String): String? =
        prefs(context).getString(PREFIX + key, null)

    fun getBoolean(context: Context, key: String, default: Boolean): Boolean =
        prefs(context).getBoolean(PREFIX + key, default)

    /** Native-only state (snapshots, active profile). Flutter never reads this file. */
    fun nativeState(context: Context): SharedPreferences =
        context.getSharedPreferences("switchly_tile_state", Context.MODE_PRIVATE)
}
