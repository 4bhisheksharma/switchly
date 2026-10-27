package app.utils.switchly.power

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import kotlin.math.abs

/** A snapshot of the battery, read from the sticky ACTION_BATTERY_CHANGED broadcast. */
data class BatteryReading(
    val level: Int,
    val plugged: Boolean,
    val full: Boolean,
    val temperatureC: Float?,
    /** Charging power, only while plugged in and when the device reports current. */
    val chargingWatts: Float?,
)

object BatteryInfo {
    fun read(context: Context): BatteryReading {
        // A null receiver just returns the sticky intent; no registration happens.
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
        val plugged = (intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0) != 0
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE) ?: Int.MIN_VALUE
        val voltageMv = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        return BatteryReading(
            level = if (level >= 0 && scale > 0) level * 100 / scale else 0,
            plugged = plugged,
            full = status == BatteryManager.BATTERY_STATUS_FULL,
            temperatureC = if (temp == Int.MIN_VALUE) null else temp / 10f,
            chargingWatts = if (plugged) watts(context, voltageMv) else null,
        )
    }

    private fun watts(context: Context, voltageMv: Int): Float? {
        val raw = context.getSystemService(BatteryManager::class.java)
            .getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        if (raw == 0 || raw == Int.MIN_VALUE || voltageMv <= 0) return null // Not reported.
        // Should be µA, but some OEMs report mA (and some flip the sign). While charging,
        // anything under 20 000 can only be mA: 20 mA of charge current would be meaningless.
        val amps = abs(raw).let { if (it < 20_000) it / 1_000f else it / 1_000_000f }
        return amps * voltageMv / 1_000f
    }
}
