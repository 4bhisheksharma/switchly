package app.utils.switchly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import app.utils.switchly.channel.QsTogglesChannel
import app.utils.switchly.tiles.TileRefresher
import app.utils.switchly.volume.VolumeController
import app.utils.switchly.widgets.WidgetRefresher
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter UI. Also receives QS_TILE_PREFERENCES (tile long-press) and
 * tile-tap launches, and forwards the target route to Flutter.
 */
class MainActivity : FlutterActivity() {
    private var channel: QsTogglesChannel? = null
    private var isVolumeReceiverRegistered = false

    private val volumeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            channel?.pushVolumeChanged(VolumeController.getAllLevels(this@MainActivity))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = QsTogglesChannel(this, flutterEngine.dartExecutor.binaryMessenger).also {
            it.setInitialRoute(LaunchRoutes.fromIntent(intent))
        }
    }

    override fun onResume() {
        super.onResume()
        if (!isVolumeReceiverRegistered) {
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
                isVolumeReceiverRegistered = true
            } catch (_: Exception) {}
        }
    }

    @Deprecated("Needed for the VpnService consent dialog")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (channel?.onActivityResult(requestCode, resultCode) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onPause() {
        if (isVolumeReceiverRegistered) {
            try {
                unregisterReceiver(volumeReceiver)
            } catch (_: Exception) {}
            isVolumeReceiverRegistered = false
        }
        super.onPause()
        // Push config edits (provider names, saved texts, profiles) to the active tiles and widgets.
        TileRefresher.refreshAll(this)
        WidgetRefresher.refreshAll(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        LaunchRoutes.fromIntent(intent)?.let { channel?.pushRoute(it) }
    }
}
