package app.utils.switchly.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Triggers refresh for all Switchly home screen widgets when settings or states change.
 */
object WidgetRefresher {
    fun refreshAll(context: Context) {
        try {
            refreshNepaliDate(context)
            refreshPaymentQr(context)
            refreshQuickActions(context)
            refreshVolume(context)
        } catch (e: Exception) {
            Log.d("WidgetRefresher", "Failed to refresh widgets", e)
        }
    }

    fun refreshNepaliDate(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            // Standard widget
            val standardComponent = ComponentName(context, NepaliDateWidgetProvider::class.java)
            val standardIds = appWidgetManager.getAppWidgetIds(standardComponent)
            if (standardIds.isNotEmpty()) {
                val intent = Intent(context, NepaliDateWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, standardIds)
                }
                context.sendBroadcast(intent)
            }

            // Compact widget
            val compactComponent = ComponentName(context, NepaliDateCompactWidgetProvider::class.java)
            val compactIds = appWidgetManager.getAppWidgetIds(compactComponent)
            if (compactIds.isNotEmpty()) {
                val intent = Intent(context, NepaliDateCompactWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, compactIds)
                }
                context.sendBroadcast(intent)
            }
        } catch (e: Exception) {
            Log.d("WidgetRefresher", "Failed to refresh Nepali date widgets", e)
        }
    }

    fun refreshPaymentQr(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, PaymentQrWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                val intent = Intent(context, PaymentQrWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        } catch (e: Exception) {
            Log.d("WidgetRefresher", "Failed to refresh Payment QR widgets", e)
        }
    }

    fun refreshQuickActions(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, QuickActionsWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                val intent = Intent(context, QuickActionsWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        } catch (e: Exception) {
            Log.d("WidgetRefresher", "Failed to refresh Quick Actions widgets", e)
        }
    }

    fun refreshVolume(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            // Standard Volume widget
            val standardComponent = ComponentName(context, VolumeWidgetProvider::class.java)
            val standardIds = appWidgetManager.getAppWidgetIds(standardComponent)
            if (standardIds.isNotEmpty()) {
                val intent = Intent(context, VolumeWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, standardIds)
                }
                context.sendBroadcast(intent)
            }

            // Compact Volume widget
            val compactComponent = ComponentName(context, VolumeCompactWidgetProvider::class.java)
            val compactIds = appWidgetManager.getAppWidgetIds(compactComponent)
            if (compactIds.isNotEmpty()) {
                val intent = Intent(context, VolumeCompactWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, compactIds)
                }
                context.sendBroadcast(intent)
            }
        } catch (e: Exception) {
            Log.d("WidgetRefresher", "Failed to refresh Volume widgets", e)
        }
    }
}

