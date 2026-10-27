package app.utils.switchly.display

import android.content.Context
import app.utils.switchly.core.SecureSettings
import app.utils.switchly.core.SettingsTable
import app.utils.switchly.core.SharedConfig

/**
 * System-wide grayscale via the accessibility colour-correction ("daltonizer") settings in
 * Settings.Secure. Monochromacy is daltonizer mode 0.
 *
 * The user may already use colour correction for colour blindness, so the previous mode is
 * saved when grayscale turns on and restored when it turns off.
 */
object Grayscale {
    private const val KEY_ENABLED = "accessibility_display_daltonizer_enabled"
    private const val KEY_MODE = "accessibility_display_daltonizer"
    private const val MODE_MONOCHROMACY = "0"

    private const val PREV_ENABLED = "grayscale_prev_enabled"
    private const val PREV_MODE = "grayscale_prev_mode"

    fun isOn(context: Context): Boolean =
        get(context, KEY_ENABLED) == "1" && get(context, KEY_MODE) == MODE_MONOCHROMACY

    /** Returns true if the system accepted the change. */
    fun set(context: Context, on: Boolean): Boolean {
        if (on == isOn(context)) return true
        val saved = SharedConfig.nativeState(context)
        return if (on) {
            saved.edit()
                .putString(PREV_ENABLED, get(context, KEY_ENABLED))
                .putString(PREV_MODE, get(context, KEY_MODE))
                .apply()
            put(context, KEY_MODE, MODE_MONOCHROMACY) && put(context, KEY_ENABLED, "1")
        } else {
            val prevEnabled = saved.getString(PREV_ENABLED, null)
            val prevMode = saved.getString(PREV_MODE, null)
            // Restore colour correction only if it was on with a non-grayscale mode.
            val restoreCorrection = prevEnabled == "1" && prevMode != null && prevMode != MODE_MONOCHROMACY
            if (restoreCorrection) {
                put(context, KEY_MODE, prevMode) && put(context, KEY_ENABLED, "1")
            } else {
                put(context, KEY_ENABLED, "0").also { if (prevMode != null) put(context, KEY_MODE, prevMode) }
            }
        }
    }

    private fun get(context: Context, key: String) = SecureSettings.getString(context, SettingsTable.SECURE, key)

    private fun put(context: Context, key: String, value: String?) =
        SecureSettings.putString(context, SettingsTable.SECURE, key, value)
}
