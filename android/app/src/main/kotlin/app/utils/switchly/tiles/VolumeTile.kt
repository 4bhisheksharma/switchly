package app.utils.switchly.tiles

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.os.Build
import android.service.quicksettings.Tile
import android.util.Log
import app.utils.switchly.R
import app.utils.switchly.tiles.base.BaseTile
import app.utils.switchly.volume.VolumeController
import app.utils.switchly.volume.VolumeDialogActivity

/**
 * Quick Settings volume slider tile.
 * Displays live volume loudness (e.g. "Volume: 80%") and presents an interactive
 * slider dialog directly on top of Quick Settings via [VolumeDialogActivity] when tapped.
 */
class VolumeTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    private var isReceiverRegistered = false

    private val volumeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            try {
                refresh()
            } catch (e: Exception) {
                Log.w("VolumeTile", "Error in volume broadcast receiver", e)
            }
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        registerVolumeReceiver()
    }

    override fun onStopListening() {
        unregisterVolumeReceiver()
        super.onStopListening()
    }

    override fun onDestroy() {
        unregisterVolumeReceiver()
        super.onDestroy()
    }

    private fun registerVolumeReceiver() {
        if (!isReceiverRegistered) {
            try {
                val filter = IntentFilter().apply {
                    addAction("android.media.VOLUME_CHANGED_ACTION")
                    addAction(AudioManager.RINGER_MODE_CHANGED_ACTION)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(volumeReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                } else {
                    registerReceiver(volumeReceiver, filter)
                }
                isReceiverRegistered = true
            } catch (e: Exception) {
                Log.w("VolumeTile", "Could not register volume receiver", e)
            }
        }
    }

    private fun unregisterVolumeReceiver() {
        if (isReceiverRegistered) {
            try {
                unregisterReceiver(volumeReceiver)
            } catch (_: Exception) {}
            isReceiverRegistered = false
        }
    }

    override fun render(tile: Tile) {
        val media = VolumeController.getStreamInfo(this, AudioManager.STREAM_MUSIC)
        val ringerMode = VolumeController.getRingerMode(this)

        val isMuted = media.percent == 0 || ringerMode == AudioManager.RINGER_MODE_SILENT

        tile.state = if (isMuted) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.icon = Icon.createWithResource(
            this,
            if (isMuted) R.drawable.ic_tile_volume_mute else R.drawable.ic_tile_volume
        )
        tile.label = "Volume: ${media.percent}%"
        tile.subtitle = when {
            media.percent == 0 -> "Muted"
            ringerMode == AudioManager.RINGER_MODE_VIBRATE -> "Vibrate · ${media.percent}%"
            ringerMode == AudioManager.RINGER_MODE_SILENT -> "Silent"
            else -> "Tap for sliders"
        }
    }

    override fun onTap() {
        startActivityAndCollapseCompat(Intent(this, VolumeDialogActivity::class.java))
    }
}
