package app.utils.switchly.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.SizeF
import android.widget.RemoteViews
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R
import app.utils.switchly.calendar.BikramSambat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Standard Home Screen Widget displaying the current Bikram Sambat (BS) date.
 * Fully responsive: dynamically switches between standard and compact layouts on resize.
 */
class NepaliDateWidgetProvider : AppWidgetProvider() {

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
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_USER_PRESENT -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, NepaliDateWidgetProvider::class.java)
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
                val nepali = BikramSambat.useNepali(context)
                val today = LocalDate.now()
                val bs = BikramSambat.fromAd(today) ?: return

                val standardViews = buildStandardViews(context, appWidgetId, bs, today, nepali)
                val compactViews = buildCompactViews(context, appWidgetId, bs, today, nepali)

                val views: RemoteViews = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    // Responsive views on Android 12+: system auto-selects and smoothly transitions
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
                Log.w("NepaliDateWidget", "Failed to update widget $appWidgetId", e)
            }
        }

        private fun buildStandardViews(
            context: Context,
            appWidgetId: Int,
            bs: app.utils.switchly.calendar.BsDate,
            today: LocalDate,
            nepali: Boolean
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_nepali_date)
            val dayStr = BikramSambat.digits(bs.day, nepali)
            val monthName = BikramSambat.monthName(bs.month, nepali)
            val yearStr = BikramSambat.digits(bs.year, nepali)
            val weekdayStr = BikramSambat.weekday(today.dayOfWeek, nepali)
            val adStr = today.format(DateTimeFormatter.ofPattern("EEE, d MMM yyyy", Locale.ENGLISH))

            views.setTextViewText(R.id.widget_bs_day, dayStr)
            views.setTextViewText(R.id.widget_bs_month_year, "$monthName $yearStr")
            views.setTextViewText(R.id.widget_weekday, weekdayStr)
            views.setTextViewText(R.id.widget_ad_date, adStr)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("bs_date"))
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
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
            bs: app.utils.switchly.calendar.BsDate,
            today: LocalDate,
            nepali: Boolean
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_nepali_date_compact)
            val dayStr = BikramSambat.digits(bs.day, nepali)
            val monthName = BikramSambat.monthName(bs.month, nepali)
            val yearStr = BikramSambat.digits(bs.year, nepali)
            val weekdayStr = BikramSambat.weekday(today.dayOfWeek, nepali)
            val adStr = today.format(DateTimeFormatter.ofPattern("d MMM", Locale.ENGLISH))

            views.setTextViewText(R.id.widget_bs_month_year, "$monthName $yearStr")
            views.setTextViewText(R.id.widget_bs_day, dayStr)
            views.setTextViewText(R.id.widget_bs_subtitle, "$weekdayStr · $adStr")

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("bs_date"))
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
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
