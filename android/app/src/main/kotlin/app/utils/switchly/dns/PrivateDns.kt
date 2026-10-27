package app.utils.switchly.dns

import android.content.Context
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SecureSettings
import app.utils.switchly.core.SettingsTable
import app.utils.switchly.core.SharedConfig
import org.json.JSONArray
import org.json.JSONException

data class DnsProvider(val name: String, val host: String)

/**
 * Reads and writes Android's Private DNS (DNS-over-TLS, API 28+) settings.
 *
 * The keys are hidden constants in Settings.Global, so they are used by name here.
 */
object PrivateDns {
    private const val KEY_MODE = "private_dns_mode"
    private const val KEY_SPECIFIER = "private_dns_specifier"

    const val MODE_OFF = "off"
    const val MODE_AUTOMATIC = "opportunistic"
    const val MODE_HOSTNAME = "hostname"

    val DEFAULT_PROVIDERS = listOf(
        DnsProvider("Cloudflare", "one.one.one.one"),
        DnsProvider("Google", "dns.google"),
        DnsProvider("AdGuard", "dns.adguard-dns.com"),
        DnsProvider("Quad9", "dns.quad9.net"),
    )

    data class State(val mode: String, val hostname: String?)

    fun read(context: Context): State {
        // An unset mode means the system default, which is "Automatic" on stock Android.
        val mode = SecureSettings.getString(context, SettingsTable.GLOBAL, KEY_MODE) ?: MODE_AUTOMATIC
        val host = SecureSettings.getString(context, SettingsTable.GLOBAL, KEY_SPECIFIER)
        return State(mode, host)
    }

    fun setOff(context: Context): Boolean =
        SecureSettings.putString(context, SettingsTable.GLOBAL, KEY_MODE, MODE_OFF)

    fun setHostname(context: Context, host: String): Boolean =
        // Write the host before the mode so the system never sees "hostname" with an old host.
        SecureSettings.putString(context, SettingsTable.GLOBAL, KEY_SPECIFIER, host) &&
            SecureSettings.putString(context, SettingsTable.GLOBAL, KEY_MODE, MODE_HOSTNAME)

    /** The user's provider list from Flutter, or the defaults if it is unset or invalid. */
    fun providers(context: Context): List<DnsProvider> {
        val json = SharedConfig.getString(context, PrefKeys.DNS_PROVIDERS) ?: return DEFAULT_PROVIDERS
        return try {
            val array = JSONArray(json)
            (0 until array.length())
                .map { array.getJSONObject(it) }
                .map { DnsProvider(it.optString("name"), it.optString("host").trim()) }
                .filter { it.host.isNotEmpty() }
                .ifEmpty { DEFAULT_PROVIDERS }
        } catch (e: JSONException) {
            Log.w("PrivateDns", "Invalid provider list, using defaults", e)
            DEFAULT_PROVIDERS
        }
    }
}
