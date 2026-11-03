package app.utils.switchly.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.SizeF
import android.widget.RemoteViews
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R
import app.utils.switchly.volume.VolumeController

/**
 * Standard Home Screen Widget displaying current Volume loudness.
 * Fully responsive: dynamically adjusts between detailed and compact layouts on resize.
 */
class VolumeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_SET_PRESET -> {
                val percent = intent.getIntExtra(EXTRA_PRESET_PERCENT, -1)
                if (percent in 0..100) {
                    VolumeController.setStreamPercent(context, AudioManager.STREAM_MUSIC, percent)
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, VolumeWidgetProvider::class.java)
                    )
                    for (id in ids) {
                        updateAppWidget(context, appWidgetManager, id)
                    }
                    val compactIds = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, VolumeCompactWidgetProvider::class.java)
                    )
                    for (id in compactIds) {
                        VolumeCompactWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                    }
                }
            }
            "android.media.VOLUME_CHANGED_ACTION",
            AudioManager.RINGER_MODE_CHANGED_ACTION,
            Intent.ACTION_USER_PRESENT -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, VolumeWidgetProvider::class.java)
                )
                for (id in ids) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        }
    }

    companion object {
        const val ACTION_SET_PRESET = "app.utils.switchly.action.SET_VOLUME_PRESET"
        const val EXTRA_PRESET_PERCENT = "extra_preset_percent"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null
        ) {
            try {
                val media = VolumeController.getStreamInfo(context, AudioManager.STREAM_MUSIC)
                val ringerMode = VolumeController.getRingerMode(context)

                val standardViews = buildStandardViews(context, appWidgetId, media.percent, ringerMode)
                val compactViews = buildCompactViews(context, appWidgetId, media.percent, ringerMode)

                val views: RemoteViews = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    RemoteViews(
                        mapOf(
                            SizeF(60f, 60f) to compactViews,
                            SizeF(180f, 60f) to standardViews
                        )
                    )
                } else {
                    val opt = options ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
                    val minWidth = opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 200)
                    val minHeight = opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 100)
                    if (minWidth < 170 || minHeight < 65) compactViews else standardViews
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.w("VolumeWidget", "Failed to update widget $appWidgetId", e)
            }
        }

        private fun buildStandardViews(
            context: Context,
            appWidgetId: Int,
            percent: Int,
            ringerMode: Int
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_volume)

            views.setTextViewText(R.id.widget_volume_percent, "$percent%")
            views.setTextViewText(
                R.id.widget_volume_mode,
                when (ringerMode) {
                    AudioManager.RINGER_MODE_SILENT -> "Silent"
                    AudioManager.RINGER_MODE_VIBRATE -> "Vibrate"
                    else -> "Sound On"
                }
            )

            // Preset chips PendingIntents
            val presets = listOf(
                R.id.widget_volume_preset_mute to 0,
                R.id.widget_volume_preset_30 to 30,
                R.id.widget_volume_preset_70 to 70,
                R.id.widget_volume_preset_100 to 100
            )
            for ((viewId, targetPercent) in presets) {
                val presetIntent = Intent(context, VolumeWidgetProvider::class.java).apply {
                    action = ACTION_SET_PRESET
                    putExtra(EXTRA_PRESET_PERCENT, targetPercent)
                }
                val presetPendingIntent = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 100 + targetPercent,
                    presetIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(viewId, presetPendingIntent)
            }

            // Clicking widget body opens Volume screen in app
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("volume"))
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10 + 1,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            return views
        }

        private fun buildCompactViews(
            context: Context,
            appWidgetId: Int,
            percent: Int,
            ringerMode: Int
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_volume_compact)

            views.setTextViewText(R.id.widget_volume_percent, "$percent%")
            views.setTextViewText(
                R.id.widget_volume_status,
                when (ringerMode) {
                    AudioManager.RINGER_MODE_SILENT -> "Silent"
                    AudioManager.RINGER_MODE_VIBRATE -> "Vibrate"
                    else -> "Sound On"
                }
            )

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("volume"))
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10 + 2,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            return views
        }
    }
}
