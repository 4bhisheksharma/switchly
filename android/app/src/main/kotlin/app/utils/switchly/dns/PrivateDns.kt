package app.utils.switchly.dns

import android.content.Context
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SecureSettings
import app.utils.switchly.core.SettingsTable
import app.utils.switchly.core.SharedConfig
import org.json.JSONException
import org.json.JSONObject

data class DnsProvider(val id: String, val name: String, val host: String, val enabled: Boolean)

/** One state the tile can move to. */
sealed interface DnsCycleEntry {
    data object Off : DnsCycleEntry
    data object Automatic : DnsCycleEntry
    data class Host(val provider: DnsProvider) : DnsCycleEntry
}

/** The tile's cycle, edited in Flutter. Mirrors `DnsConfig` in lib/features/dns/data/dns_models.dart. */
data class DnsConfig(
    val includeOff: Boolean,
    val includeAutomatic: Boolean,
    val providers: List<DnsProvider>,
) {
    /** States in tap order: Off, Automatic, then enabled providers in the user's order. */
    fun cycle(): List<DnsCycleEntry> = buildList {
        if (includeOff) add(DnsCycleEntry.Off)
        if (includeAutomatic) add(DnsCycleEntry.Automatic)
        providers.filter { it.enabled }.forEach { add(DnsCycleEntry.Host(it)) }
    }
}

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

    /** Used until the user edits the cycle in the app. Keep in sync with dns_models.dart. */
    private val DEFAULT_CONFIG = DnsConfig(
        includeOff = true,
        includeAutomatic = false,
        providers = listOf(
            DnsProvider("adguard", "AdGuard", "dns.adguard-dns.com", true),
            DnsProvider("cloudflare", "Cloudflare", "one.one.one.one", true),
            DnsProvider("google", "Google", "dns.google", true),
            DnsProvider("quad9", "Quad9", "dns.quad9.net", true),
            DnsProvider("mullvad", "Mullvad", "dns.mullvad.net", false),
        ),
    )

    data class State(val mode: String, val hostname: String?) {
        fun matches(entry: DnsCycleEntry): Boolean = when (entry) {
            DnsCycleEntry.Off -> mode == MODE_OFF
            DnsCycleEntry.Automatic -> mode == MODE_AUTOMATIC
            is DnsCycleEntry.Host -> mode == MODE_HOSTNAME && entry.provider.host.equals(hostname, ignoreCase = true)
        }
    }

    fun read(context: Context): State {
        // An unset mode means the system default, which is "Automatic" on stock Android.
        val mode = SecureSettings.getString(context, SettingsTable.GLOBAL, KEY_MODE) ?: MODE_AUTOMATIC
        val host = SecureSettings.getString(context, SettingsTable.GLOBAL, KEY_SPECIFIER)
        return State(mode, host)
    }

    fun apply(context: Context, entry: DnsCycleEntry): Boolean = when (entry) {
        DnsCycleEntry.Off -> setMode(context, MODE_OFF)
        DnsCycleEntry.Automatic -> setMode(context, MODE_AUTOMATIC)
        is DnsCycleEntry.Host -> setHostname(context, entry.provider.host)
    }

    fun setMode(context: Context, mode: String): Boolean =
        SecureSettings.putString(context, SettingsTable.GLOBAL, KEY_MODE, mode)

    fun setHostname(context: Context, host: String): Boolean =
        // Write the host before the mode so the system never sees "hostname" with an old host.
        SecureSettings.putString(context, SettingsTable.GLOBAL, KEY_SPECIFIER, host) &&
            setMode(context, MODE_HOSTNAME)

    /** The user's cycle from Flutter, or the default if it is unset or invalid. */
    fun config(context: Context): DnsConfig {
        val json = SharedConfig.getString(context, PrefKeys.DNS_CONFIG) ?: return DEFAULT_CONFIG
        return try {
            val root = JSONObject(json)
            val array = root.getJSONArray("providers")
            val providers = (0 until array.length())
                .map { array.getJSONObject(it) }
                .map {
                    DnsProvider(
                        id = it.optString("id"),
                        name = it.optString("name"),
                        host = it.optString("host").trim(),
                        enabled = it.optBoolean("enabled", true),
                    )
                }
                .filter { it.host.isNotEmpty() }
            DnsConfig(
                includeOff = root.optBoolean("includeOff", true),
                includeAutomatic = root.optBoolean("includeAutomatic", false),
                providers = providers,
            )
        } catch (e: JSONException) {
            Log.w("PrivateDns", "Invalid DNS config, using defaults", e)
            DEFAULT_CONFIG
        }
    }
}
