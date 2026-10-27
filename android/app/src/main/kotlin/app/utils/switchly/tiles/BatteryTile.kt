package app.utils.switchly.tiles

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.service.quicksettings.Tile
import app.utils.switchly.power.BatteryInfo
import app.utils.switchly.tiles.base.BaseTile
import java.util.Locale

/**
 * Battery level, temperature and charging power. Active (highlighted) while plugged in.
 *
 * Not an active tile: it re-reads whenever the panel opens and updates live while it is
 * open (charging current changes without a broadcast, so it is also polled).
 */
class BatteryTile : BaseTile() {
    override val requiresSecureSettings = false

    private val handler = Handler(Looper.getMainLooper())
    private val poll = object : Runnable {
        override fun run() {
            refresh()
            handler.postDelayed(this, POLL_MS)
        }
    }
    private val batteryChanged = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = refresh()
    }

    override fun onStartListening() {
        super.onStartListening()
        registerReceiver(batteryChanged, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        handler.postDelayed(poll, POLL_MS)
    }

    override fun onStopListening() {
        handler.removeCallbacks(poll)
        unregisterReceiver(batteryChanged)
        super.onStopListening()
    }

    override fun render(tile: Tile) {
        val battery = BatteryInfo.read(this)
        val temp = battery.temperatureC?.let { String.format(Locale.US, "%.1f°C", it) }
        val power = battery.chargingWatts?.let { String.format(Locale.US, "%.1f W", it) }
        tile.state = if (battery.plugged) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        // Small tiles only show the label, so it carries the most useful reading:
        // charging power while charging, temperature otherwise.
        val charging = battery.plugged && !battery.full
        tile.label = "${battery.level}% · ${(if (charging) power else temp) ?: "Battery"}"
        tile.subtitle = when {
            battery.plugged && battery.full -> listOfNotNull("Full", temp).joinToString(" · ")
            charging -> temp ?: "Charging"
            else -> "Battery"
        }
    }

    override fun onTap() {
        startActivityAndCollapseCompat(Intent(Intent.ACTION_POWER_USAGE_SUMMARY))
    }

    private companion object {
        const val POLL_MS = 2_000L
    }
}
