package app.utils.switchly.network

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import app.utils.switchly.core.SecureSettings
import app.utils.switchly.core.SettingsTable
import java.io.IOException
import java.net.Inet4Address

/** Wireless debugging (ADB over Wi-Fi), Android 11+. */
object WirelessDebugging {
    const val KEY = "adb_wifi_enabled"
    private const val KEY_DEV_OPTIONS = "development_settings_enabled"

    val supported: Boolean get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

    fun isOn(context: Context): Boolean = SecureSettings.getString(context, SettingsTable.GLOBAL, KEY) == "1"

    /** Wireless debugging only works while Developer options are enabled. */
    fun devOptionsEnabled(context: Context): Boolean =
        SecureSettings.getString(context, SettingsTable.GLOBAL, KEY_DEV_OPTIONS) == "1"

    fun set(context: Context, on: Boolean): Boolean =
        SecureSettings.putString(context, SettingsTable.GLOBAL, KEY, if (on) "1" else "0")

    /** `ip:port` for `adb connect`, just the IP if the port isn't readable, or null without Wi-Fi. */
    fun address(context: Context): String? {
        val ip = wifiIpv4(context) ?: return null
        return adbPort()?.let { "$ip:$it" } ?: ip
    }

    private fun wifiIpv4(context: Context): String? {
        val cm = context.getSystemService(ConnectivityManager::class.java)
        // Scan all networks: with the kill switch (a VPN) on, the active network isn't Wi-Fi.
        @Suppress("DEPRECATION")
        val wifi = cm.allNetworks.firstOrNull {
            cm.getNetworkCapabilities(it)?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        } ?: return null
        return cm.getLinkProperties(wifi)?.linkAddresses
            ?.map { it.address }
            ?.firstOrNull { it is Inet4Address }
            ?.hostAddress
    }

    /**
     * The random TLS port adbd listens on. Read through `getprop`; some builds' SELinux policy
     * hides it from apps, in which case only the IP is shown.
     */
    private fun adbPort(): String? = try {
        val process = Runtime.getRuntime().exec(arrayOf("getprop", "service.adb.tls.port"))
        process.inputStream.bufferedReader().use { it.readText() }.trim().takeIf { it.isNotEmpty() && it != "0" }
    } catch (e: IOException) {
        null
    }
}
