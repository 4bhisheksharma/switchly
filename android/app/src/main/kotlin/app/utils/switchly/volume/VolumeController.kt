package app.utils.switchly.volume

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.util.Log

data class StreamInfo(
    val current: Int,
    val max: Int,
    val min: Int,
    val percent: Int
)

/**
 * Thread-safe, bulletproof wrapper around Android's [AudioManager].
 * Handles all permission checks, security exceptions (e.g. DND restrictions on Android 7+),
 * and stream volume operations without crashing.
 */
object VolumeController {
    private const val TAG = "VolumeController"

    fun streamTypeFromString(name: String): Int = when (name.lowercase()) {
        "ring" -> AudioManager.STREAM_RING
        "notification" -> AudioManager.STREAM_NOTIFICATION
        "alarm" -> AudioManager.STREAM_ALARM
        "call" -> AudioManager.STREAM_VOICE_CALL
        else -> AudioManager.STREAM_MUSIC
    }

    private fun audioManager(context: Context): AudioManager? = try {
        context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    } catch (e: Exception) {
        Log.w(TAG, "Failed to get AudioManager", e)
        null
    }

    fun getStreamInfo(context: Context, streamType: Int): StreamInfo {
        val am = audioManager(context) ?: return StreamInfo(0, 15, 0, 0)
        return try {
            val max = am.getStreamMaxVolume(streamType).coerceAtLeast(1)
            val min = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                try {
                    am.getStreamMinVolume(streamType).coerceAtLeast(0)
                } catch (_: Exception) {
                    0
                }
            } else 0
            val current = am.getStreamVolume(streamType).coerceIn(min, max)
            val range = (max - min).coerceAtLeast(1)
            val percent = (((current - min).toDouble() / range) * 100).toInt().coerceIn(0, 100)
            StreamInfo(current, max, min, percent)
        } catch (e: Exception) {
            Log.w(TAG, "Error getting stream info for $streamType", e)
            StreamInfo(0, 15, 0, 0)
        }
    }

    fun setStreamVolume(context: Context, streamType: Int, index: Int, flags: Int = 0): Boolean {
        val am = audioManager(context) ?: return false
        return try {
            val max = am.getStreamMaxVolume(streamType)
            val min = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                try {
                    am.getStreamMinVolume(streamType)
                } catch (_: Exception) {
                    0
                }
            } else 0
            val clamped = index.coerceIn(min, max)
            am.setStreamVolume(streamType, clamped, flags)
            true
        } catch (e: SecurityException) {
            // Android 7.0+ restricts changing ring/notification stream to silent without DND permission
            Log.w(TAG, "SecurityException adjusting volume for stream $streamType: ${e.message}")
            false
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set volume for stream $streamType", e)
            false
        }
    }

    fun setStreamPercent(context: Context, streamType: Int, percent: Int, flags: Int = 0): Boolean {
        val am = audioManager(context) ?: return false
        return try {
            val max = am.getStreamMaxVolume(streamType)
            val min = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                try {
                    am.getStreamMinVolume(streamType)
                } catch (_: Exception) {
                    0
                }
            } else 0
            val range = (max - min).coerceAtLeast(1)
            val target = (min + (range * (percent.coerceIn(0, 100) / 100.0))).toInt()
            setStreamVolume(context, streamType, target, flags)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set stream percent for $streamType", e)
            false
        }
    }

    fun getRingerMode(context: Context): Int {
        val am = audioManager(context) ?: return AudioManager.RINGER_MODE_NORMAL
        return try {
            am.ringerMode
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get ringer mode", e)
            AudioManager.RINGER_MODE_NORMAL
        }
    }

    fun setRingerMode(context: Context, mode: Int): Boolean {
        val am = audioManager(context) ?: return false
        return try {
            am.ringerMode = mode
            true
        } catch (e: SecurityException) {
            Log.w(TAG, "SecurityException changing ringer mode: ${e.message}")
            false
        } catch (e: Exception) {
            Log.w(TAG, "Failed to change ringer mode", e)
            false
        }
    }

    fun showSystemVolume(context: Context): Boolean {
        val am = audioManager(context) ?: return false
        return try {
            am.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_SAME,
                AudioManager.FLAG_SHOW_UI
            )
            true
        } catch (e: Exception) {
            Log.w(TAG, "Failed to show system volume UI", e)
            false
        }
    }

    fun getAllLevels(context: Context): Map<String, Any> {
        val music = getStreamInfo(context, AudioManager.STREAM_MUSIC)
        val ring = getStreamInfo(context, AudioManager.STREAM_RING)
        val notif = getStreamInfo(context, AudioManager.STREAM_NOTIFICATION)
        val alarm = getStreamInfo(context, AudioManager.STREAM_ALARM)
        val call = getStreamInfo(context, AudioManager.STREAM_VOICE_CALL)
        val ringerMode = getRingerMode(context)

        return mapOf(
            "music" to mapOf("current" to music.current, "max" to music.max, "min" to music.min, "percent" to music.percent),
            "ring" to mapOf("current" to ring.current, "max" to ring.max, "min" to ring.min, "percent" to ring.percent),
            "notification" to mapOf("current" to notif.current, "max" to notif.max, "min" to notif.min, "percent" to notif.percent),
            "alarm" to mapOf("current" to alarm.current, "max" to alarm.max, "min" to alarm.min, "percent" to alarm.percent),
            "call" to mapOf("current" to call.current, "max" to call.max, "min" to call.min, "percent" to call.percent),
            "ringerMode" to ringerMode
        )
    }
}

