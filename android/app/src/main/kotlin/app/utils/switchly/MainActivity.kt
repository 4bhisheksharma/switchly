package app.utils.switchly

import android.content.Intent
import app.utils.switchly.channel.QsTogglesChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter UI. Also receives QS_TILE_PREFERENCES (tile long-press) and
 * tile-tap launches, and forwards the target route to Flutter.
 */
class MainActivity : FlutterActivity() {
    private var channel: QsTogglesChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = QsTogglesChannel(this, flutterEngine.dartExecutor.binaryMessenger).also {
            it.setInitialRoute(LaunchRoutes.fromIntent(intent))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        LaunchRoutes.fromIntent(intent)?.let { channel?.pushRoute(it) }
    }
}
