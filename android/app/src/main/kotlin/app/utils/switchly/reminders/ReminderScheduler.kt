package app.utils.switchly.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import app.utils.switchly.core.SharedConfig
import app.utils.switchly.tiles.ReminderTile
import app.utils.switchly.tiles.TileRefresher

object ReminderScheduler {
    private const val TAG = "ReminderScheduler"
    private const val KEY_SCHEDULED_IDS = "reminder_scheduled_ids"
    private const val KEY_SNOOZED_IDS = "reminder_snoozed_ids"

    fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = context.getSystemService(AlarmManager::class.java) ?: return false
        return am.canScheduleExactAlarms()
    }

    fun syncAll(context: Context) {
        synchronized(Reminders) {
            val state = SharedConfig.nativeState(context)
            val prevIds = state.getStringSet(KEY_SCHEDULED_IDS, emptySet())?.toSet() ?: emptySet()
            val prevSnoozed = state.getStringSet(KEY_SNOOZED_IDS, emptySet())?.toSet() ?: emptySet()

            val reminders = Reminders.all(context)
            val byId = reminders.associateBy { it.id }

            // Cancel alarms for any previously scheduled reminder that is deleted, disabled, or completed.
            for (oldId in prevIds) {
                val current = byId[oldId]
                if (current == null || !current.isUpcoming) {
                    cancelAlarm(context, oldId)
                }
            }
            for (snoozedId in prevSnoozed) {
                val current = byId[snoozedId]
                if (current == null || current.completed) {
                    cancelSnooze(context, snoozedId)
                }
            }

            val now = System.currentTimeMillis()
            val newScheduledIds = mutableSetOf<String>()
            var modified = false
            val updatedList = reminders.map { r ->
                if (!r.isUpcoming) {
                    r
                } else if (r.scheduledAtMillis > now) {
                    scheduleAlarm(context, r.id, r.scheduledAtMillis)
                    newScheduledIds.add(r.id)
                    r
                } else if (r.repeat != ReminderRepeat.NONE) {
                    val nextMillis = Reminders.nextOccurrenceAfter(r.scheduledAtMillis, r.repeat, now)
                    if (nextMillis != null) {
                        scheduleAlarm(context, r.id, nextMillis)
                        newScheduledIds.add(r.id)
                        modified = true
                        r.copy(scheduledAtMillis = nextMillis)
                    } else {
                        r
                    }
                } else {
                    r
                }
            }

            if (modified) {
                Reminders.saveAll(context, updatedList)
                Reminders.notifyChanged(context)
            }

            val remainingSnoozed = prevSnoozed.filter { id ->
                val r = byId[id]
                r != null && !r.completed
            }.toSet()

            state.edit()
                .putStringSet(KEY_SCHEDULED_IDS, newScheduledIds)
                .putStringSet(KEY_SNOOZED_IDS, remainingSnoozed)
                .apply()
        }
        TileRefresher.refresh(context, ReminderTile::class.java)
    }

    fun scheduleAlarm(context: Context, id: String, triggerAtMillis: Long) {
        val pending = alarmPendingIntent(context, id, isSnooze = false)
        setAlarm(context, triggerAtMillis, pending)
        val state = SharedConfig.nativeState(context)
        val current = state.getStringSet(KEY_SCHEDULED_IDS, emptySet())?.toMutableSet() ?: mutableSetOf()
        current.add(id)
        state.edit().putStringSet(KEY_SCHEDULED_IDS, current).apply()
    }

    fun cancelAlarm(context: Context, id: String) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            action = ReminderReceiver.ACTION_TRIGGER
        }
        val pending = PendingIntent.getBroadcast(
            context,
            Reminders.notificationId(id),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (pending != null) {
            am.cancel(pending)
            pending.cancel()
        }
    }

    fun scheduleSnooze(context: Context, id: String, triggerAtMillis: Long) {
        val pending = alarmPendingIntent(context, id, isSnooze = true)
        setAlarm(context, triggerAtMillis, pending)
        val state = SharedConfig.nativeState(context)
        val current = state.getStringSet(KEY_SNOOZED_IDS, emptySet())?.toMutableSet() ?: mutableSetOf()
        current.add(id)
        state.edit().putStringSet(KEY_SNOOZED_IDS, current).apply()
    }

    fun cancelSnooze(context: Context, id: String) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            action = ReminderReceiver.ACTION_TRIGGER_SNOOZE
        }
        val pending = PendingIntent.getBroadcast(
            context,
            Reminders.snoozeRequestCode(id),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (pending != null) {
            am.cancel(pending)
            pending.cancel()
        }
    }

    private fun alarmPendingIntent(context: Context, id: String, isSnooze: Boolean): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            action = if (isSnooze) ReminderReceiver.ACTION_TRIGGER_SNOOZE else ReminderReceiver.ACTION_TRIGGER
            putExtra(ReminderReceiver.EXTRA_REMINDER_ID, id)
            putExtra(ReminderReceiver.EXTRA_IS_SNOOZE, isSnooze)
        }
        val requestCode = if (isSnooze) Reminders.snoozeRequestCode(id) else Reminders.notificationId(id)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun setAlarm(context: Context, triggerAtMillis: Long, pending: PendingIntent) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val target = triggerAtMillis.coerceAtLeast(System.currentTimeMillis() + 500L)
        if (canScheduleExactAlarms(context)) {
            try {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, target, pending)
                return
            } catch (e: SecurityException) {
                Log.w(TAG, "Exact alarm denied at runtime, falling back to inexact allowWhileIdle", e)
            }
        }
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, target, pending)
    }
}
