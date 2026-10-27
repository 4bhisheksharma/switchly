package app.utils.switchly.network

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import org.json.JSONException
import org.json.JSONObject

/**
 * Internet kill switch: a local VPN that routes all traffic into a tunnel nobody reads, so
 * every app goes offline. Apps in the user's exception list bypass it and stay online.
 */
object KillSwitch {
    private const val TAG = "KillSwitch"

    fun isOn(): Boolean = KillSwitchVpnService.running

    /** True once the user has accepted Android's one-time VPN prompt for this app. */
    fun hasConsent(context: Context): Boolean = VpnService.prepare(context) == null

    /** Starts (or re-applies the exception list to) the VPN. Requires [hasConsent]. */
    fun start(context: Context): Boolean = send(context, Intent(context, KillSwitchVpnService::class.java))

    fun stop(context: Context): Boolean =
        send(context, Intent(context, KillSwitchVpnService::class.java).setAction(KillSwitchVpnService.ACTION_STOP))

    /** Blocks until [isOn] matches [on], up to ~1.5 s; the service starts asynchronously. */
    fun awaitState(on: Boolean) {
        repeat(15) {
            if (isOn() == on) return
            Thread.sleep(100)
        }
    }

    fun allowedApps(context: Context): List<String> {
        val json = SharedConfig.getString(context, PrefKeys.KILL_SWITCH_CONFIG) ?: return emptyList()
        return try {
            val apps = JSONObject(json).optJSONArray("allowedApps") ?: return emptyList()
            (0 until apps.length()).map { apps.getString(it) }
        } catch (e: JSONException) {
            Log.w(TAG, "Invalid kill switch config", e)
            emptyList()
        }
    }

    private fun send(context: Context, intent: Intent): Boolean = try {
        context.startService(intent)
        true
    } catch (e: IllegalStateException) {
        // Background start not allowed right now (app not in a foreground-ish state).
        Log.w(TAG, "Couldn't start the VPN service", e)
        false
    }
}
