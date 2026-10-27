package app.utils.switchly.core

import android.content.ContentResolver
import android.content.Context
import android.provider.Settings
import android.util.Log

/** The three Settings tables Android exposes through [Settings]. */
enum class SettingsTable { GLOBAL, SECURE, SYSTEM }

/**
 * Safe read/write access to Settings.Global/Secure/System.
 *
 * Writes need WRITE_SECURE_SETTINGS (granted once over ADB). Every call catches the
 * exceptions OEM builds throw for hidden or restricted keys, so callers only have to
 * handle a `false` return.
 */
object SecureSettings {
    private const val TAG = "SecureSettings"

    fun getString(context: Context, table: SettingsTable, key: String): String? = try {
        val resolver = context.contentResolver
        when (table) {
            SettingsTable.GLOBAL -> Settings.Global.getString(resolver, key)
            SettingsTable.SECURE -> Settings.Secure.getString(resolver, key)
            SettingsTable.SYSTEM -> Settings.System.getString(resolver, key)
        }
    } catch (e: SecurityException) {
        Log.w(TAG, "Read denied for $table/$key", e)
        null
    }

    /** Returns true if the value was written. A `null` value deletes the key on most builds. */
    fun putString(context: Context, table: SettingsTable, key: String, value: String?): Boolean = try {
        put(context.contentResolver, table, key, value)
    } catch (e: SecurityException) {
        Log.w(TAG, "Write denied for $table/$key", e)
        false
    } catch (e: IllegalArgumentException) {
        // Thrown by some builds for keys that are unknown or read-only for apps.
        Log.w(TAG, "Write rejected for $table/$key", e)
        false
    }

    private fun put(resolver: ContentResolver, table: SettingsTable, key: String, value: String?): Boolean =
        when (table) {
            SettingsTable.GLOBAL -> Settings.Global.putString(resolver, key, value)
            SettingsTable.SECURE -> Settings.Secure.putString(resolver, key, value)
            SettingsTable.SYSTEM -> Settings.System.putString(resolver, key, value)
        }
}
