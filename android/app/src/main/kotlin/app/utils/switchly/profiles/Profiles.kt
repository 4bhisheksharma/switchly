package app.utils.switchly.profiles

import android.content.Context
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import app.utils.switchly.display.AnimationScale
import app.utils.switchly.display.Grayscale
import app.utils.switchly.dns.PrivateDns
import app.utils.switchly.network.KillSwitch
import app.utils.switchly.network.WirelessDebugging
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * A named bundle of settings. Every field is optional; null means "don't change".
 * Mirrors `Profile` in lib/features/profiles/data/profile_models.dart.
 */
data class Profile(
    val id: String,
    val name: String,
    val dnsMode: String?,
    val dnsHost: String?,
    val grayscale: Boolean?,
    val animationSpeed: Float?,
    val wirelessDebugging: Boolean?,
    val killSwitch: Boolean?,
)

/**
 * Applies profiles and restores what was there before.
 *
 * The first profile applied snapshots the current value of every setting it touches; later
 * profiles add any new settings to that snapshot. "Restore" puts back only the snapshotted
 * settings, so changes the user made to other settings in the meantime are kept.
 */
object Profiles {
    private const val TAG = "Profiles"
    private const val ACTIVE_ID = "profile_active_id"
    private const val SNAPSHOT = "profile_snapshot"

    fun all(context: Context): List<Profile> {
        val json = SharedConfig.getString(context, PrefKeys.PROFILES) ?: return emptyList()
        return try {
            val array = JSONArray(json)
            (0 until array.length()).map { parse(array.getJSONObject(it)) }
        } catch (e: JSONException) {
            Log.w(TAG, "Invalid profiles", e)
            emptyList()
        }
    }

    fun activeId(context: Context): String? = SharedConfig.nativeState(context).getString(ACTIVE_ID, null)

    fun active(context: Context): Profile? = activeId(context)?.let { id -> all(context).firstOrNull { it.id == id } }

    /** Returns false if any part was refused (e.g. missing permission or VPN consent). */
    fun apply(context: Context, profile: Profile): Boolean {
        val state = SharedConfig.nativeState(context)
        val snapshot = state.getString(SNAPSHOT, null)?.let(::JSONObject) ?: JSONObject()
        captureMissing(context, profile, snapshot)

        val ok = applyValues(
            context,
            dnsMode = profile.dnsMode,
            dnsHost = profile.dnsHost,
            grayscale = profile.grayscale,
            animationSpeed = profile.animationSpeed,
            wirelessDebugging = profile.wirelessDebugging,
            killSwitch = profile.killSwitch,
        )
        state.edit().putString(SNAPSHOT, snapshot.toString()).putString(ACTIVE_ID, profile.id).apply()
        return ok
    }

    /** Puts back the settings from before the first profile was applied. */
    fun restore(context: Context): Boolean {
        val state = SharedConfig.nativeState(context)
        val snapshot = state.getString(SNAPSHOT, null)?.let(::JSONObject)
        val ok = snapshot == null || applyValues(
            context,
            dnsMode = snapshot.optStringOrNull("dnsMode"),
            dnsHost = snapshot.optStringOrNull("dnsHost"),
            grayscale = snapshot.optBooleanOrNull("grayscale"),
            animationSpeed = snapshot.optDoubleOrNull("animationSpeed")?.toFloat(),
            wirelessDebugging = snapshot.optBooleanOrNull("wirelessDebugging"),
            killSwitch = snapshot.optBooleanOrNull("killSwitch"),
        )
        state.edit().remove(SNAPSHOT).remove(ACTIVE_ID).apply()
        return ok
    }

    private fun captureMissing(context: Context, profile: Profile, snapshot: JSONObject) {
        if (profile.dnsMode != null && !snapshot.has("dnsMode")) {
            val dns = PrivateDns.read(context)
            snapshot.put("dnsMode", dns.mode).put("dnsHost", dns.hostname ?: JSONObject.NULL)
        }
        if (profile.grayscale != null && !snapshot.has("grayscale")) {
            snapshot.put("grayscale", Grayscale.isOn(context))
        }
        if (profile.animationSpeed != null && !snapshot.has("animationSpeed")) {
            snapshot.put("animationSpeed", AnimationScale.read(context).window.toDouble())
        }
        if (profile.wirelessDebugging != null && !snapshot.has("wirelessDebugging")) {
            snapshot.put("wirelessDebugging", WirelessDebugging.isOn(context))
        }
        if (profile.killSwitch != null && !snapshot.has("killSwitch")) {
            snapshot.put("killSwitch", KillSwitch.isOn())
        }
    }

    private fun applyValues(
        context: Context,
        dnsMode: String?,
        dnsHost: String?,
        grayscale: Boolean?,
        animationSpeed: Float?,
        wirelessDebugging: Boolean?,
        killSwitch: Boolean?,
    ): Boolean {
        var ok = true
        when (dnsMode) {
            null -> Unit
            PrivateDns.MODE_HOSTNAME -> ok = dnsHost != null && PrivateDns.setHostname(context, dnsHost) && ok
            else -> ok = PrivateDns.setMode(context, dnsMode) && ok
        }
        grayscale?.let { ok = Grayscale.set(context, it) && ok }
        animationSpeed?.let { ok = AnimationScale.set(context, it) && ok }
        if (wirelessDebugging != null && WirelessDebugging.supported) {
            ok = WirelessDebugging.set(context, wirelessDebugging) && ok
        }
        when (killSwitch) {
            true -> ok = KillSwitch.hasConsent(context) && KillSwitch.start(context) && ok
            false -> if (KillSwitch.isOn()) ok = KillSwitch.stop(context) && ok
            null -> Unit
        }
        return ok
    }

    private fun parse(json: JSONObject) = Profile(
        id = json.getString("id"),
        name = json.optString("name"),
        dnsMode = json.optJSONObject("dns")?.optStringOrNull("mode"),
        dnsHost = json.optJSONObject("dns")?.optStringOrNull("host"),
        grayscale = json.optBooleanOrNull("grayscale"),
        animationSpeed = json.optDoubleOrNull("animationSpeed")?.toFloat(),
        wirelessDebugging = json.optBooleanOrNull("wirelessDebugging"),
        killSwitch = json.optBooleanOrNull("killSwitch"),
    )

    private fun JSONObject.optStringOrNull(key: String): String? =
        if (has(key) && !isNull(key)) getString(key) else null

    private fun JSONObject.optBooleanOrNull(key: String): Boolean? =
        if (has(key) && !isNull(key)) getBoolean(key) else null

    private fun JSONObject.optDoubleOrNull(key: String): Double? =
        if (has(key) && !isNull(key)) getDouble(key) else null
}
