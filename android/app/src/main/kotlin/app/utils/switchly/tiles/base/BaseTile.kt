package app.utils.switchly.tiles.base

import android.app.Dialog
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.view.Window
import android.view.WindowManager
import android.widget.TextView
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.core.Permissions
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import app.utils.switchly.tiles.TileRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Common behaviour for every Switchly tile:
 * - refreshes state each time the Quick Settings panel opens
 * - when WRITE_SECURE_SETTINGS is missing, shows "Tap to set up" and opens onboarding on tap.
 *   STATE_UNAVAILABLE is not used for this because unavailable tiles can't be tapped.
 * - shows the predicted state instantly ([predict]), runs [toggle] off the main thread, then
 *   redraws with the real state; taps during a toggle are ignored so a double tap can't undo it
 * - optionally asks for unlock first ([requiresUnlock])
 * - after a toggle, shows the result in a small message at the top of the screen
 *   ([announcement]), unless turned off in the app. Toasts appear behind the open panel, so
 *   this is a tile dialog, the only window allowed above it; showing one makes SystemUI close
 *   the panel, hence the setting. It isn't guaranteed (see PaymentQrActivity), so [render]
 *   also puts the current value in the label ("AdGuard", "Font 130%") for small tiles
 */
abstract class BaseTile : TileService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var toggling = false
    private val handler = Handler(Looper.getMainLooper())
    private var notice: Dialog? = null
    private var noticeText: TextView? = null
    private val hideNotice = Runnable { dismissNotice() }

    /** Set to false for tiles that don't touch Settings (e.g. the VPN kill switch). */
    protected open val requiresSecureSettings: Boolean = true

    /** Ask for unlock before acting from the lock screen. Off for harmless display tweaks. */
    protected open val requiresUnlock: Boolean = true

    /** Draws the tile's state, label and subtitle. Called on the main thread. */
    protected abstract fun render(tile: Tile)

    /** Applies the next state. Called on [Dispatchers.IO]. */
    protected open fun toggle() {}

    /** Optional instant feedback: set the state the tile is about to reach. */
    protected open fun predict(tile: Tile) {}

    /** The message shown after a toggle, or null for none. Default: "Tile name: subtitle". */
    protected open fun announcement(tile: Tile): String? = "${defaultLabel()}: ${tile.subtitle}"

    /** The tile's name from the registry, e.g. "Grayscale". */
    protected fun defaultLabel(): String =
        TileRegistry.all.first { it.service == javaClass }.let { getString(it.label) }

    /** Tiles that open UI instead of toggling (dialogs, pickers) override this. */
    protected open fun onTap() {
        runToggle()
    }

    override fun onStartListening() {
        super.onStartListening()
        refresh()
    }

    override fun onClick() {
        super.onClick()
        if (toggling) return
        if (requiresSecureSettings && !Permissions.hasWriteSecureSettings(this)) {
            launchApp(LaunchRoutes.SETUP)
            return
        }
        if (requiresUnlock && isLocked) unlockAndRun(::onTap) else onTap()
    }

    override fun onDestroy() {
        dismissNotice()
        scope.cancel()
        super.onDestroy()
    }

    private fun runToggle() {
        toggling = true
        qsTile?.let {
            predict(it)
            it.updateTile()
        }
        scope.launch {
            try {
                withContext(Dispatchers.IO) { toggle() }
            } catch (e: kotlinx.coroutines.CancellationException) {
                // Normal lifecycle cancellation when the tile unbinds or closes; not an error.
            } catch (e: Exception) {
                Log.e(javaClass.simpleName, "Toggle failed", e)
            } finally {
                toggling = false
            }
            refresh()
            if (SharedConfig.getBoolean(this@BaseTile, PrefKeys.SHOW_TILE_MESSAGE, false)) {
                qsTile?.let(::announcement)?.let(::announce)
            }
        }
    }

    /**
     * A pill at the top of the screen that lets touches through and hides itself. Rapid taps
     * update the text in place instead of stacking messages.
     */
    private fun announce(text: String) {
        handler.removeCallbacks(hideNotice)
        val existing = noticeText
        if (notice?.isShowing == true && existing != null) {
            existing.text = text
        } else {
            val label = TextView(this).apply {
                this.text = text
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                val h = dp(20f)
                val v = dp(12f)
                setPadding(h, v, h, v)
                background = GradientDrawable().apply {
                    setColor(Color.argb(240, 32, 33, 38))
                    cornerRadius = dp(99f).toFloat()
                }
            }
            val dialog = Dialog(this).apply {
                requestWindowFeature(Window.FEATURE_NO_TITLE)
                setContentView(label)
                window?.apply {
                    setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
                    clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
                    // Purely informational: never takes focus or touches from the panel below.
                    addFlags(
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                    )
                    setLayout(WRAP_CONTENT, WRAP_CONTENT)
                    setGravity(Gravity.TOP or Gravity.CENTER_HORIZONTAL)
                    attributes = attributes.apply { y = dp(48f) }
                }
            }
            try {
                showDialog(dialog)
            } catch (e: RuntimeException) {
                // The panel closed or the system refused the window; the label still shows the value.
                Log.d(javaClass.simpleName, "Couldn't show notice", e)
                return
            }
            notice = dialog
            noticeText = label
        }
        handler.postDelayed(hideNotice, NOTICE_MS)
    }

    private fun dismissNotice() {
        handler.removeCallbacks(hideNotice)
        notice?.dismiss()
        notice = null
        noticeText = null
    }

    private fun dp(value: Float) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    protected fun refresh() {
        // qsTile is null when the panel has already closed; it is redrawn on next open.
        val tile = qsTile ?: return
        // SystemUI caches the icon across app updates; setting it here keeps it correct. The
        // label is reset too, so a value-in-label from an earlier render can't go stale.
        TileRegistry.all.firstOrNull { it.service == javaClass }?.let {
            tile.icon = Icon.createWithResource(this, it.icon)
            tile.label = getString(it.label)
        }
        if (requiresSecureSettings && !Permissions.hasWriteSecureSettings(this)) {
            tile.state = Tile.STATE_INACTIVE
            tile.subtitle = "Tap to set up"
        } else {
            render(tile)
        }
        tile.updateTile()
    }

    /** Opens the Flutter app at [route] and collapses the shade. */
    protected fun launchApp(route: String) {
        startActivityAndCollapseCompat(
            Intent(this, MainActivity::class.java).putExtra(LaunchRoutes.EXTRA_ROUTE, route),
        )
    }

    protected fun startActivityAndCollapseCompat(intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this, intent.component.hashCode(), intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            // The Intent overload throws on API 34+ when targetSdk >= 34.
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private companion object {
        const val NOTICE_MS = 1_500L
    }
}
