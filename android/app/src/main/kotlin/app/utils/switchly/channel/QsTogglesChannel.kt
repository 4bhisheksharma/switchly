package app.utils.switchly.channel

import android.Manifest
import android.app.Activity
import android.app.KeyguardManager
import android.app.StatusBarManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import java.io.File
import app.utils.switchly.core.Permissions
import app.utils.switchly.display.AnimationScale
import app.utils.switchly.display.FontScale
import app.utils.switchly.display.Grayscale
import app.utils.switchly.dns.PrivateDns
import app.utils.switchly.network.KillSwitch
import app.utils.switchly.network.LaunchableApps
import app.utils.switchly.network.WirelessDebugging
import app.utils.switchly.power.BatteryInfo
import app.utils.switchly.power.Caffeine
import app.utils.switchly.profiles.Profiles
import app.utils.switchly.publicmode.PublicMode
import app.utils.switchly.scanner.ScannerActivity
import app.utils.switchly.screentime.AppScreenTime
import app.utils.switchly.tiles.AppScreenTimeTile
import app.utils.switchly.tiles.AppScreenTimeTile2
import app.utils.switchly.tiles.AppScreenTimeTile3
import app.utils.switchly.tiles.AppScreenTimeTile4
import app.utils.switchly.tiles.TileRefresher
import app.utils.switchly.tiles.TileRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import kotlin.concurrent.thread

/** Native side of the `qs_toggles` channel. Mirrored by lib/core/platform/qs_channel.dart. */
class QsTogglesChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME).also { it.setMethodCallHandler(this) }
    private val mainHandler = Handler(Looper.getMainLooper())

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
            "getPrivateDns" -> background(result) {
                val state = PrivateDns.read(activity)
                mapOf("mode" to state.mode, "host" to state.hostname)
            }
            "setPrivateDns" -> result.success(setPrivateDns(call.argument("mode"), call.argument("host")).alsoRefresh())
            "grantWithRoot" -> grantWithRoot(result)
            "getDisplayState" -> background(result) {
                val scales = AnimationScale.read(activity)
                mapOf(
                    "grayscale" to Grayscale.isOn(activity),
                    "windowScale" to scales.window.toDouble(),
                    "transitionScale" to scales.transition.toDouble(),
                    "animatorScale" to scales.animator.toDouble(),
                    "fontScale" to FontScale.read(activity).toDouble(),
                )
            }
            "setGrayscale" -> result.success(Grayscale.set(activity, call.argument<Boolean>("on") == true).alsoRefresh())
            "setAnimationScale" -> {
                val scale = call.argument<Double>("scale")
                result.success((scale != null && AnimationScale.set(activity, scale.toFloat())).alsoRefresh())
            }
            "setFontScale" -> {
                val scale = call.argument<Double>("scale")
                result.success((scale != null && FontScale.set(activity, scale.toFloat())).alsoRefresh())
            }
            "getCaffeine" -> result.success(caffeineState())
            "startCaffeine" -> {
                Caffeine.start(activity, call.argument<Int>("minutes") ?: 0)
                result.success(caffeineState())
            }
            "stopCaffeine" -> {
                Caffeine.stop(activity)
                result.success(caffeineState())
            }
            "getBatteryInfo" -> background(result) {
                val battery = BatteryInfo.read(activity)
                mapOf(
                    "level" to battery.level,
                    "plugged" to battery.plugged,
                    "full" to battery.full,
                    "temperature" to battery.temperatureC?.toDouble(),
                    "watts" to battery.chargingWatts?.toDouble(),
                )
            }
            // Off the main thread: the address lookup scans networks and runs `getprop`
            // (~25 ms on a mid-range phone), which would delay the app's first frame.
            "getNetworkState" -> background(result) {
                mapOf(
                    "wirelessSupported" to WirelessDebugging.supported,
                    "wirelessDebugging" to WirelessDebugging.isOn(activity),
                    "devOptions" to WirelessDebugging.devOptionsEnabled(activity),
                    "address" to WirelessDebugging.address(activity),
                    "killSwitch" to KillSwitch.isOn(),
                )
            }
            "setWirelessDebugging" -> result.success(
                WirelessDebugging.set(activity, call.argument<Boolean>("on") == true).alsoRefresh(),
            )
            "startKillSwitch" -> startKillSwitch(result)
            "stopKillSwitch" -> background(result) {
                KillSwitch.stop(activity).also { KillSwitch.awaitState(false) }.alsoRefresh()
            }
            // Re-applies the exception list if the VPN is running.
            "reloadKillSwitch" -> result.success(!KillSwitch.isOn() || KillSwitch.start(activity))
            "getLaunchableApps" -> background(result) { LaunchableApps.load(activity) }
            "getActiveProfile" -> result.success(Profiles.activeId(activity))
            "applyProfile" -> {
                val profile = Profiles.all(activity).firstOrNull { it.id == call.argument<String>("id") }
                if (profile == null) {
                    result.success(false)
                } else {
                    background(result) { Profiles.apply(activity, profile).alsoRefresh() }
                }
            }
            "restoreProfile" -> background(result) { Profiles.restore(activity).alsoRefresh() }
            "refreshTiles" -> result.success(true.alsoRefresh())
            "openQrScanner" -> {
                activity.startActivity(Intent(activity, ScannerActivity::class.java))
                result.success(true)
            }
            "getAppVersion" -> {
                val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    activity.packageManager.getPackageInfo(activity.packageName, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    activity.packageManager.getPackageInfo(activity.packageName, 0)
                }
                val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    pInfo.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    pInfo.versionCode.toLong()
                }
                result.success(mapOf("versionName" to (pInfo.versionName ?: "0.0.0"), "versionCode" to code))
            }
            "canInstallPackages" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    result.success(activity.packageManager.canRequestPackageInstalls())
                } else {
                    result.success(true)
                }
            }
            "openInstallPermissionSettings" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:${activity.packageName}")
                        }
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            }
            "installApk" -> {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("invalid_path", "APK path cannot be null or empty", null)
                } else {
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("file_not_found", "APK file does not exist at $path", null)
                    } else {
                        try {
                            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", file)
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            activity.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("install_failed", e.message, null)
                        }
                    }
                }
            }
            "hasUsageAccess" -> result.success(AppScreenTime.hasUsageAccess(activity))
            "openUsageAccessSettings" -> {
                AppScreenTime.openUsageAccessSettings(activity)
                result.success(true)
            }
            "getAppScreenTime" -> background(result) {
                val pkg = call.argument<String>("packageName") ?: ""
                val millis = AppScreenTime.getTodayForegroundTimeMillis(activity, pkg)
                mapOf(
                    "millis" to millis,
                    "formatted" to AppScreenTime.formatDuration(millis),
                )
            }
            "getTodayUsageStats" -> background(result) {
                AppScreenTime.getTodayAllUsageStats(activity)
            }
            "refreshAppScreenTimeTile" -> {
                TileRefresher.refresh(activity, AppScreenTimeTile::class.java)
                TileRefresher.refresh(activity, AppScreenTimeTile2::class.java)
                TileRefresher.refresh(activity, AppScreenTimeTile3::class.java)
                TileRefresher.refresh(activity, AppScreenTimeTile4::class.java)
                result.success(true)
            }
            "getPublicModeState" -> result.success(
                mapOf(
                    "active" to PublicMode.isActive(activity),
                    "endsAt" to PublicMode.endsAt(activity),
                    "hasUsageAccess" to PublicMode.hasUsageAccess(activity),
                    "canDrawOverlays" to PublicMode.canDrawOverlays(activity),
                    "hasDndAccess" to PublicMode.hasDndAccess(activity),
                    "isXiaomiDevice" to PublicMode.isXiaomiOrMiui(),
                    "hasMiuiPopupPermission" to PublicMode.hasMiuiBackgroundPopupPermission(activity),
                    "isIgnoringBattery" to PublicMode.isIgnoringBatteryOptimizations(activity),
                )
            )
            "activatePublicMode" -> background(result) {
                PublicMode.activate(activity).alsoRefresh()
            }
            "deactivatePublicMode" -> background(result) {
                PublicMode.deactivate(activity).alsoRefresh()
            }
            "canDrawOverlays" -> result.success(PublicMode.canDrawOverlays(activity))
            "openOverlayPermissionSettings" -> {
                PublicMode.openOverlaySettings(activity)
                result.success(true)
            }
            "hasDndAccess" -> result.success(PublicMode.hasDndAccess(activity))
            "openDndPermissionSettings" -> {
                PublicMode.openDndSettings(activity)
                result.success(true)
            }
            "openMiuiPermissions" -> {
                result.success(PublicMode.openMiuiPermissions(activity))
            }
            "openAutostartSettings" -> {
                result.success(PublicMode.openAutostartSettings(activity))
            }
            "isIgnoringBatteryOptimizations" -> {
                result.success(PublicMode.isIgnoringBatteryOptimizations(activity))
            }
            "requestIgnoreBatteryOptimizations" -> {
                result.success(PublicMode.requestIgnoreBatteryOptimizations(activity))
            }
            "isDeviceSecure" -> {
                val km = activity.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                val secure = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    km?.isDeviceSecure == true
                } else {
                    @Suppress("DEPRECATION")
                    km?.isKeyguardSecure == true
                }
                result.success(secure)
            }
            "authenticateDeviceOwner" -> {
                val km = activity.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                val isSecure = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    km?.isDeviceSecure == true
                } else {
                    @Suppress("DEPRECATION")
                    km?.isKeyguardSecure == true
                }

                if (km != null && isSecure) {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        @Suppress("DEPRECATION")
                        km.createConfirmDeviceCredentialIntent(
                            "Unlock Switchly Public Mode",
                            "Confirm device lock (fingerprint, face, PIN or pattern) to unlock"
                        )
                    } else null

                    if (intent != null) {
                        pendingDeviceAuth?.success(false)
                        pendingDeviceAuth = result
                        @Suppress("DEPRECATION")
                        activity.startActivityForResult(intent, REQUEST_DEVICE_CREDENTIAL)
                    } else {
                        result.success(false)
                    }
                } else {
                    // Device has no secure lock screen configured; cannot authenticate via device lock
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    /** `endsAt` is epoch millis, or 0 when there is no time limit. */
    private fun caffeineState() = mapOf("on" to Caffeine.isOn, "minutes" to Caffeine.minutes, "endsAt" to Caffeine.endsAt)

    /** Tiles are active tiles, so any state change must be pushed to them. */
    private fun <T> T.alsoRefresh(): T = also { TileRefresher.refreshAll(activity) }

    /** Runs [work] off the main thread and replies on it. */
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        thread(name = "qs-channel") {
            val value = try {
                work()
            } catch (e: Exception) {
                mainHandler.post { result.error("failed", e.message, null) }
                return@thread
            }
            mainHandler.post { result.success(value) }
        }
    }

    private var pendingVpnConsent: MethodChannel.Result? = null
    private var pendingDeviceAuth: MethodChannel.Result? = null

    /** Starts the kill switch, showing Android's one-time VPN consent dialog first if needed. */
    private fun startKillSwitch(result: MethodChannel.Result) {
        val consent = VpnService.prepare(activity)
        if (consent == null) {
            background(result) {
                KillSwitch.start(activity) && run {
                    KillSwitch.awaitState(true)
                    KillSwitch.isOn().alsoRefresh()
                }
            }
            return
        }
        pendingVpnConsent?.success(false)
        pendingVpnConsent = result
        @Suppress("DEPRECATION")
        activity.startActivityForResult(consent, REQUEST_VPN_CONSENT)
    }

    /** Forwarded from MainActivity. Returns true if the result was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode == REQUEST_DEVICE_CREDENTIAL) {
            val res = pendingDeviceAuth ?: return true
            pendingDeviceAuth = null
            res.success(resultCode == Activity.RESULT_OK)
            return true
        }
        if (requestCode != REQUEST_VPN_CONSENT) return false
        val result = pendingVpnConsent ?: return true
        pendingVpnConsent = null
        if (resultCode == Activity.RESULT_OK) startKillSwitch(result) else result.success(false)
        return true
    }

    private fun setPrivateDns(mode: String?, host: String?): Boolean = when (mode) {
        PrivateDns.MODE_OFF, PrivateDns.MODE_AUTOMATIC -> PrivateDns.setMode(activity, mode)
        PrivateDns.MODE_HOSTNAME -> !host.isNullOrBlank() && PrivateDns.setHostname(activity, host)
        else -> false
    }

    /**
     * Grants WRITE_SECURE_SETTINGS to ourselves via `su`. Runs off the main thread because
     * the root manager shows a prompt and `waitFor()` blocks until the user answers.
     */
    private fun grantWithRoot(result: MethodChannel.Result) {
        val command = "pm grant ${activity.packageName} ${Manifest.permission.WRITE_SECURE_SETTINGS}"
        thread(name = "root-grant") {
            val granted = try {
                Runtime.getRuntime().exec(arrayOf("su", "-c", command)).waitFor() == 0
            } catch (e: IOException) {
                false // No su binary: not rooted.
            } catch (e: InterruptedException) {
                false
            }
            mainHandler.post { result.success(granted && Permissions.hasWriteSecureSettings(activity)) }
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
        private const val REQUEST_VPN_CONSENT = 4711
        private const val REQUEST_DEVICE_CREDENTIAL = 4712
    }
}
