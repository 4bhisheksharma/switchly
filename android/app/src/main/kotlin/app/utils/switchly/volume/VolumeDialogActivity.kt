package app.utils.switchly.volume

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.media.AudioManager
import android.os.Bundle
import android.view.ContextThemeWrapper
import android.view.LayoutInflater
import android.widget.Button
import android.widget.SeekBar
import android.widget.TextView
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R
import app.utils.switchly.tiles.TileRefresher
import app.utils.switchly.tiles.VolumeTile
import app.utils.switchly.widgets.WidgetRefresher

/**
 * Foreground transparent dialog activity for Quick Settings volume control.
 *
 * An Activity rather than TileService.showDialog() because modern Android (Android 10+)
 * blocks or ignores background audio stream modifications unless the process has an active
 * foreground While-In-Use context. Hosting the sliders inside this transparent activity
 * guarantees immediate real-time volume adjustment across all devices and OEM launchers.
 */
class VolumeDialogActivity : Activity() {
    private var dialog: AlertDialog? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)

        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight)
        val inflater = LayoutInflater.from(themed)
        val view = inflater.inflate(R.layout.dialog_volume_sliders, null)

        val mediaInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_MUSIC)
        val ringInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_RING)
        val notifInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_NOTIFICATION)
        val alarmInfo = VolumeController.getStreamInfo(this, AudioManager.STREAM_ALARM)
        val ringerMode = VolumeController.getRingerMode(this)

        // Ringer mode badge
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
                    VolumeController.setStreamVolume(
                        this@VolumeDialogActivity,
                        AudioManager.STREAM_MUSIC,
                        target,
                        0
                    )
                    val range = (mediaInfo.max - mediaInfo.min).coerceAtLeast(1)
                    val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                    mediaText.text = "$pct%"
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                WidgetRefresher.refreshVolume(this@VolumeDialogActivity)
                TileRefresher.refresh(this@VolumeDialogActivity, VolumeTile::class.java)
            }
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
                    VolumeController.setStreamVolume(
                        this@VolumeDialogActivity,
                        AudioManager.STREAM_RING,
                        target,
                        0
                    )
                    val range = (ringInfo.max - ringInfo.min).coerceAtLeast(1)
                    val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                    ringText.text = "$pct%"
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                VolumeController.setStreamVolume(
                    this@VolumeDialogActivity,
                    AudioManager.STREAM_RING,
                    ringInfo.min + ringSeek.progress,
                    AudioManager.FLAG_PLAY_SOUND
                )
                WidgetRefresher.refreshVolume(this@VolumeDialogActivity)
                TileRefresher.refresh(this@VolumeDialogActivity, VolumeTile::class.java)
            }
        })

        // 3. Notification
        val notifText = view.findViewById<TextView>(R.id.dialog_volume_notif_text)
        val notifSeek = view.findViewById<SeekBar>(R.id.dialog_volume_notif_seek)
        notifText.text = "${notifInfo.percent}%"
        notifSeek.max = (notifInfo.max - notifInfo.min).coerceAtLeast(1)
        notifSeek.progress = (notifInfo.current - notifInfo.min).coerceAtLeast(0)
        notifSeek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    val target = notifInfo.min + progress
                    VolumeController.setStreamVolume(
                        this@VolumeDialogActivity,
                        AudioManager.STREAM_NOTIFICATION,
                        target,
                        0
                    )
                    val range = (notifInfo.max - notifInfo.min).coerceAtLeast(1)
                    val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                    notifText.text = "$pct%"
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                VolumeController.setStreamVolume(
                    this@VolumeDialogActivity,
                    AudioManager.STREAM_NOTIFICATION,
                    notifInfo.min + notifSeek.progress,
                    AudioManager.FLAG_PLAY_SOUND
                )
                WidgetRefresher.refreshVolume(this@VolumeDialogActivity)
                TileRefresher.refresh(this@VolumeDialogActivity, VolumeTile::class.java)
            }
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
                    VolumeController.setStreamVolume(
                        this@VolumeDialogActivity,
                        AudioManager.STREAM_ALARM,
                        target,
                        0
                    )
                    val range = (alarmInfo.max - alarmInfo.min).coerceAtLeast(1)
                    val pct = ((progress.toDouble() / range) * 100).toInt().coerceIn(0, 100)
                    alarmText.text = "$pct%"
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                VolumeController.setStreamVolume(
                    this@VolumeDialogActivity,
                    AudioManager.STREAM_ALARM,
                    alarmInfo.min + alarmSeek.progress,
                    AudioManager.FLAG_PLAY_SOUND
                )
                WidgetRefresher.refreshVolume(this@VolumeDialogActivity)
                TileRefresher.refresh(this@VolumeDialogActivity, VolumeTile::class.java)
            }
        })

        // Buttons
        view.findViewById<Button>(R.id.dialog_volume_btn_system).setOnClickListener {
            dialog?.dismiss()
            VolumeController.showSystemVolume(this)
            finish()
        }

        view.findViewById<Button>(R.id.dialog_volume_btn_more).setOnClickListener {
            dialog?.dismiss()
            val intent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("volume"))
            }
            startActivity(intent)
            finish()
        }

        view.findViewById<Button>(R.id.dialog_volume_btn_done).setOnClickListener {
            dialog?.dismiss()
            finish()
        }

        val alertDialog = AlertDialog.Builder(themed)
            .setView(view)
            .setOnDismissListener { finish() }
            .create()

        alertDialog.window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        dialog = alertDialog
        alertDialog.show()
    }

    override fun onDestroy() {
        dialog?.dismiss()
        dialog = null
        WidgetRefresher.refreshVolume(this)
        TileRefresher.refresh(this, VolumeTile::class.java)
        super.onDestroy()
    }
}

