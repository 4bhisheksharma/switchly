package app.utils.switchly.core

import android.content.Context
import android.content.SharedPreferences

/** Key names written by the Flutter side. Keep in sync with lib/core/storage/pref_keys.dart. */
object PrefKeys {
    /** JSON: `{"includeOff", "includeAutomatic", "providers": [{"id", "name", "host", "enabled"}]}`. */
    const val DNS_CONFIG = "dns_config"
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
}
