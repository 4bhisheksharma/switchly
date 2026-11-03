package app.utils.switchly.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * Triggers refresh for all Switchly home screen widgets when settings or states change.
 */
object WidgetRefresher {
    fun refreshAll(context: Context) {
        refreshNepaliDate(context)
        refreshPaymentQr(context)
        refreshQuickActions(context)
    }

    fun refreshNepaliDate(context: Context) {
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
    }

    fun refreshPaymentQr(context: Context) {
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
    }

    fun refreshQuickActions(context: Context) {
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
    }
}

