package app.utils.switchly.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R
import app.utils.switchly.volume.VolumeController

/**
 * Compact 2x1 / 2x2 Home Screen Widget displaying current Volume loudness badge.
 */
class VolumeCompactWidgetProvider : AppWidgetProvider() {

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
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            VolumeWidgetProvider.ACTION_SET_PRESET,
            "android.media.VOLUME_CHANGED_ACTION",
            AudioManager.RINGER_MODE_CHANGED_ACTION,
            Intent.ACTION_USER_PRESENT -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, VolumeCompactWidgetProvider::class.java)
                )
                for (id in ids) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_volume_compact)
                val media = VolumeController.getStreamInfo(context, AudioManager.STREAM_MUSIC)
                val ringerMode = VolumeController.getRingerMode(context)

                views.setTextViewText(R.id.widget_volume_percent, "${media.percent}%")
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
                    appWidgetId * 10 + 3,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.w("VolumeCompactWidget", "Failed to update widget $appWidgetId", e)
            }
        }
    }
}
