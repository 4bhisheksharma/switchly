package app.utils.switchly.channel

import android.app.Activity
import android.app.StatusBarManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import app.utils.switchly.core.Permissions
import app.utils.switchly.tiles.TileRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Native side of the `qs_toggles` channel. Mirrored by lib/core/platform/qs_channel.dart. */
class QsTogglesChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME).also { it.setMethodCallHandler(this) }

    /** Route from the intent that cold-started the app, kept until Flutter asks for it. */
    private var pendingRoute: String? = null

    fun setInitialRoute(route: String?) {
        pendingRoute = route
    }

    /** Called for intents delivered to the running activity. */
    fun pushRoute(route: String) {
        channel.invokeMethod("onLaunchRoute", route)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasWriteSecureSettings" -> result.success(Permissions.hasWriteSecureSettings(activity))
            "getDeviceInfo" -> result.success(
                mapOf("packageName" to activity.packageName, "sdkInt" to Build.VERSION.SDK_INT),
            )
            "takeLaunchRoute" -> {
                result.success(pendingRoute)
                pendingRoute = null
            }
            "requestAddTile" -> requestAddTile(call.argument("tile"), result)
            "openSystemPanel" -> result.success(openSystemPanel(call.argument("panel")))
            else -> result.notImplemented()
        }
    }

    private fun requestAddTile(tileId: String?, result: MethodChannel.Result) {
        val tile = TileRegistry.byId(tileId)
            ?: return result.error("unknown_tile", "No tile with id $tileId", null)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return result.success("unsupported")
        }
        requestAddTileApi33(ComponentName(activity, tile.service), tile.label, tile.icon, result)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun requestAddTileApi33(component: ComponentName, label: Int, icon: Int, result: MethodChannel.Result) {
        val statusBar = activity.getSystemService(StatusBarManager::class.java)
        statusBar.requestAddTileService(
            component,
            activity.getString(label),
            Icon.createWithResource(activity, icon),
            activity.mainExecutor,
        ) { code ->
            result.success(
                when (code) {
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED -> "added"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> "already_added"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> "not_added"
                    else -> "error" // Negative TILE_ADD_REQUEST_ERROR_* codes.
                },
            )
        }
    }

    private fun openSystemPanel(panel: String?): Boolean {
        val action = when (panel) {
            "internet" -> Settings.Panel.ACTION_INTERNET_CONNECTIVITY
            "developer_options" -> Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS
            else -> return false
        }
        return try {
            activity.startActivity(Intent(action))
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    companion object {
        const val NAME = "qs_toggles"
    }
}
