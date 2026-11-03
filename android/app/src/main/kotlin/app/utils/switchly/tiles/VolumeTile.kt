package app.utils.switchly.tiles

import android.app.Dialog
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.os.Build
import android.service.quicksettings.Tile
import android.util.Log
import android.view.LayoutInflater
import android.view.Window
import android.view.WindowManager
import android.widget.Button
import android.widget.SeekBar
import android.widget.TextView
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.R
import app.utils.switchly.tiles.base.BaseTile
import app.utils.switchly.volume.VolumeController

/**
 * Quick Settings volume slider tile.
 * Displays live volume loudness (e.g. "Volume: 80%") and presents an interactive
 * slider dialog directly on top of Quick Settings when tapped.
 */
class VolumeTile : BaseTile() {
    override val requiresSecureSettings = false
    override val requiresUnlock = false

    private var activeDialog: Dialog? = null
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
        activeDialog?.dismiss()
        activeDialog = null
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
        showVolumeSlidersDialog()
    }

    private fun showVolumeSlidersDialog() {
        try {
            activeDialog?.dismiss()

            val themedDialog = Dialog(this, android.R.style.Theme_DeviceDefault_DayNight)
            themedDialog.requestWindowFeature(Window.FEATURE_NO_TITLE)

            val inflater = LayoutInflater.from(this)
            val view = inflater.inflate(R.layout.dialog_volume_sliders, null)
            themedDialog.setContentView(view)

            themedDialog.window?.apply {
                setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
                setLayout(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT
                )
            }

            // Stream states
            val mediaInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_MUSIC)
            val ringInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_RING)
            val notifInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_NOTIFICATION)
            val alarmInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_ALARM)
            val ringerMode = VolumeController.getRingerMode(this)

            // Ringer Mode badge
            val ringerBadge = view.findViewById<TextView>(R.id.dialog_volume_ringer_badge)
            ringerBadge.text = when (ringerMode) {
                AudioManager.RINGER_MODE_SILENT -> "Silent"
                AudioManager.RINGER_MODE_VIBRATE -> "Vibrate"
                else -> "Sound On"
            }

            // 1. Media
            val mediaText = view.findViewById<TextView>(R.id.dialog_volume_media_text)
            val mediaSeek = view.findViewById<SeekBar>(R.id.dialog_volume_media_seek)
            mediaText.text = "${mediaInfo.percent}%"
            mediaSeek.max = (mediaInfo.max - mediaInfo.min).coerceAtLeast(1)
            mediaSeek.progress = (mediaInfo.current - mediaInfo.min).coerceAtLeast(0)
            mediaSeek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        val target = mediaInfo.min + progress
                        VolumeController.setStreamVolume(this@VolumeTile, AudioManager.STREAM_MUSIC, target)
                        val range = (mediaInfo.max - mediaInfo.min).coerceAtLeast(1)
                        val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                        mediaText.text = "$pct%"
                        refresh()
                    }
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })

            // 2. Ring
            val ringText = view.findViewById<TextView>(R.id.dialog_volume_ring_text)
            val ringSeek = view.findViewById<SeekBar>(R.id.dialog_volume_ring_seek)
            ringText.text = "${ringInfo.percent}%"
            ringSeek.max = (ringInfo.max - ringInfo.min).coerceAtLeast(1)
            ringSeek.progress = (ringInfo.current - ringInfo.min).coerceAtLeast(0)
            ringSeek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        val target = ringInfo.min + progress
                        VolumeController.setStreamVolume(this@VolumeTile, AudioManager.STREAM_RING, target)
                        val range = (ringInfo.max - ringInfo.min).coerceAtLeast(1)
                        val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                        ringText.text = "$pct%"
                        refresh()
                    }
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })

            // 3. Notifications
            val notifText = view.findViewById<TextView>(R.id.dialog_volume_notif_text)
            val notifSeek = view.findViewById<SeekBar>(R.id.dialog_volume_notif_seek)
            notifText.text = "${notifInfo.percent}%"
            notifSeek.max = (notifInfo.max - notifInfo.min).coerceAtLeast(1)
            notifSeek.progress = (notifInfo.current - notifInfo.min).coerceAtLeast(0)
            notifSeek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        val target = notifInfo.min + progress
                        VolumeController.setStreamVolume(this@VolumeTile, AudioManager.STREAM_NOTIFICATION, target)
                        val range = (notifInfo.max - notifInfo.min).coerceAtLeast(1)
                        val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                        notifText.text = "$pct%"
                    }
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })

            // 4. Alarm
            val alarmText = view.findViewById<TextView>(R.id.dialog_volume_alarm_text)
            val alarmSeek = view.findViewById<SeekBar>(R.id.dialog_volume_alarm_seek)
            alarmText.text = "${alarmInfo.percent}%"
            alarmSeek.max = (alarmInfo.max - alarmInfo.min).coerceAtLeast(1)
            alarmSeek.progress = (alarmInfo.current - alarmInfo.min).coerceAtLeast(0)
            alarmSeek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        val target = alarmInfo.min + progress
                        VolumeController.setStreamVolume(this@VolumeTile, AudioManager.STREAM_ALARM, target)
                        val range = (alarmInfo.max - alarmInfo.min).coerceAtLeast(1)
                        val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                        alarmText.text = "$pct%"
                    }
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })

            // Buttons
            view.findViewById<Button>(R.id.dialog_volume_btn_system).setOnClickListener {
                themedDialog.dismiss()
                VolumeController.showSystemVolume(this)
            }

            view.findViewById<Button>(R.id.dialog_volume_btn_more).setOnClickListener {
                themedDialog.dismiss()
                launchApp(LaunchRoutes.tile("volume"))
            }

            view.findViewById<Button>(R.id.dialog_volume_btn_done).setOnClickListener {
                themedDialog.dismiss()
            }

            activeDialog = themedDialog
            showDialog(themedDialog)
        } catch (e: Exception) {
            Log.w("VolumeTile", "Could not show volume dialog, fallback to system volume UI", e)
            VolumeController.showSystemVolume(this)
        }
    }
}
