package app.utils.switchly.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import app.utils.switchly.R
import app.utils.switchly.payments.PaymentQrActivity
import app.utils.switchly.payments.PaymentQrs

/**
 * Fast one-tap home screen shortcut to open Payment QR code.
 * Freely resizable both horizontally and vertically.
 */
class PaymentQrWidgetProvider : AppWidgetProvider() {

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

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_payment_qr)
                val qrs = PaymentQrs.all(context)
                val subtitle = when {
                    qrs.isEmpty() -> "No QR added yet"
                    qrs.size == 1 -> qrs[0].name
                    else -> "${qrs[0].name} (+${qrs.size - 1})"
                }
                views.setTextViewText(R.id.widget_qr_subtitle, subtitle)

                val intent = Intent(context, PaymentQrActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.w("PaymentQrWidget", "Failed to update widget $appWidgetId", e)
            }
        }
    }
}
