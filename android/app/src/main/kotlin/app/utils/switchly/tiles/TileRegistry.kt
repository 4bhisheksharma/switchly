package app.utils.switchly.tiles

import android.content.ComponentName
import android.service.quicksettings.TileService
import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import app.utils.switchly.R

/** A tile's stable id (shared with Flutter's tile catalog) and its manifest-facing resources. */
data class TileInfo(
    val id: String,
    val service: Class<out TileService>,
    @StringRes val label: Int,
    @DrawableRes val icon: Int,
)

/** Every tile the app ships. Ids must match lib/core/tiles/tile_catalog.dart. */
object TileRegistry {
    val all = listOf(
        TileInfo("private_dns", PrivateDnsTile::class.java, R.string.tile_private_dns, R.drawable.ic_tile_dns),
        TileInfo("grayscale", GrayscaleTile::class.java, R.string.tile_grayscale, R.drawable.ic_tile_grayscale),
        TileInfo("animation_speed", AnimationSpeedTile::class.java, R.string.tile_animation_speed, R.drawable.ic_tile_speed),
        TileInfo("wireless_debugging", WirelessDebuggingTile::class.java, R.string.tile_wireless_debugging, R.drawable.ic_tile_adb),
        TileInfo("kill_switch", KillSwitchTile::class.java, R.string.tile_kill_switch, R.drawable.ic_tile_block),
        TileInfo("profiles", ProfileTile::class.java, R.string.tile_profiles, R.drawable.ic_tile_profiles),
        TileInfo("quick_texts", QuickTextsTile::class.java, R.string.tile_quick_texts, R.drawable.ic_tile_texts),
        TileInfo("bs_date", BsDateTile::class.java, R.string.tile_bs_date, R.drawable.ic_tile_calendar),
        TileInfo("payment_qr", PaymentQrTile::class.java, R.string.tile_payment_qr, R.drawable.ic_tile_qr),
        TileInfo("battery", BatteryTile::class.java, R.string.tile_battery, R.drawable.ic_tile_battery),
        TileInfo("font_size", FontSizeTile::class.java, R.string.tile_font_size, R.drawable.ic_tile_font),
        TileInfo("caffeine", CaffeineTile::class.java, R.string.tile_caffeine, R.drawable.ic_tile_coffee),
        TileInfo("qr_scanner", QrScannerTile::class.java, R.string.tile_qr_scanner, R.drawable.ic_tile_scan),
    )

    fun byId(id: String?): TileInfo? = all.firstOrNull { it.id == id }

    fun byComponent(component: ComponentName?): TileInfo? =
        all.firstOrNull { it.service.name == component?.className }
}
