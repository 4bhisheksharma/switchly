package app.utils.switchly.reminders

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R

object ReminderNotifier {
    private const val TAG = "ReminderNotifier"
    const val CHANNEL_ID = "reminders_channel"

    fun areNotificationsAllowed(context: Context): Boolean {
        val nm = context.getSystemService(NotificationManager::class.java) ?: return false
        if (!nm.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    fun ensureChannel(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audioAttrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Reminders",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Scheduled Switchly reminder notifications"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(soundUri, audioAttrs)
        }
        manager.createNotificationChannel(channel)
    }

    fun show(context: Context, reminder: Reminder, isSnooze: Boolean = false) {
        if (!areNotificationsAllowed(context)) {
            Log.w(TAG, "Cannot post reminder notification: permission/notifications disabled")
            return
        }
        ensureChannel(context)
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val notifId = Reminders.notificationId(reminder.id)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("reminders"))
        }
        val contentPending = PendingIntent.getActivity(
            context,
            notifId,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val doneIntent = Intent(context, ReminderActionReceiver::class.java).apply {
            action = ReminderActionReceiver.ACTION_DONE
            putExtra(ReminderActionReceiver.EXTRA_REMINDER_ID, reminder.id)
        }
        val donePending = PendingIntent.getBroadcast(
            context,
            notifId xor 0x20000000,
            doneIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val snoozeIntent = Intent(context, ReminderActionReceiver::class.java).apply {
            action = ReminderActionReceiver.ACTION_SNOOZE
            putExtra(ReminderActionReceiver.EXTRA_REMINDER_ID, reminder.id)
        }
        val snoozePending = PendingIntent.getBroadcast(
            context,
            notifId xor 0x30000000,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val trimmedNote = reminder.note.trim()
        val bodyText = when {
            trimmedNote.isNotEmpty() -> trimmedNote
            isSnooze -> "Snoozed reminder"
            else -> "Scheduled for ${Reminders.formatDateTime(context, reminder.scheduledAtMillis)}"
        }

        val subText = when {
            isSnooze -> "Snoozed"
            reminder.repeat != ReminderRepeat.NONE -> reminder.repeat.label
            else -> "Reminder"
        }

        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_reminder)
            .setContentTitle(reminder.title)
            .setContentText(bodyText)
            .setSubText(subText)
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(contentPending)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(Notification.Action.Builder(null, "Done", donePending).build())
            .addAction(Notification.Action.Builder(null, "Snooze 10m", snoozePending).build())

        if (trimmedNote.isNotEmpty()) {
            builder.style = Notification.BigTextStyle().bigText(trimmedNote)
        }

        try {
            manager.notify(notifId, builder.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification permission denied while notifying", e)
        }
    }

    fun showTest(context: Context): Boolean {
        if (!areNotificationsAllowed(context)) return false
        ensureChannel(context)
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false

        val openIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("reminders"))
        }
        val contentPending = PendingIntent.getActivity(
            context,
            Reminders.TEST_NOTIFICATION_ID,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_reminder)
            .setContentTitle("Switchly Reminders ready")
            .setContentText("Your scheduled reminders will alert you just like this at the exact time you set.")
            .setSubText("Test")
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(contentPending)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()

        return try {
            manager.notify(Reminders.TEST_NOTIFICATION_ID, notification)
            true
        } catch (e: SecurityException) {
            Log.w(TAG, "Test notification failed", e)
            false
        }
    }

    fun cancel(context: Context, id: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.cancel(Reminders.notificationId(id))
    }
}
