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
                            SizeF(60f, 50f) to compactViews,
                            SizeF(170f, 60f) to standardViews
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

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", LaunchRoutes.tile("volume"))
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
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
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", LaunchRoutes.tile("volume"))
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            return views
        }
    }
}

