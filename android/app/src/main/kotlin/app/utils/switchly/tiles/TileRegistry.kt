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
    )

    fun byId(id: String?): TileInfo? = all.firstOrNull { it.id == id }

    fun byComponent(component: ComponentName?): TileInfo? =
        all.firstOrNull { it.service.name == component?.className }
}
