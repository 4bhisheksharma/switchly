package app.utils.switchly.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.utils.switchly.tiles.ReminderTile
import app.utils.switchly.tiles.TileRefresher

/** Handles notification action buttons ("Done" and "Snooze 10m"). */
class ReminderActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(EXTRA_REMINDER_ID) ?: return
        val appContext = context.applicationContext

        when (intent.action) {
            ACTION_DONE -> handleDone(appContext, id)
            ACTION_SNOOZE -> handleSnooze(appContext, id)
        }
    }

    private fun handleDone(context: Context, id: String) {
        ReminderNotifier.cancel(context, id)
        ReminderScheduler.cancelSnooze(context, id)

        synchronized(Reminders) {
            val all = Reminders.all(context)
            val index = all.indexOfFirst { it.id == id }
            if (index != -1) {
                val r = all[index]
                val now = System.currentTimeMillis()
                val updated = if (r.repeat == ReminderRepeat.NONE) {
                    ReminderScheduler.cancelAlarm(context, id)
                    r.copy(enabled = false, completed = true, completedAtMillis = now)
                } else {
                    val nextMillis = if (r.scheduledAtMillis <= now) {
                        Reminders.nextOccurrenceAfter(r.scheduledAtMillis, r.repeat, now) ?: r.scheduledAtMillis
                    } else {
                        r.scheduledAtMillis
                    }
                    ReminderScheduler.scheduleAlarm(context, id, nextMillis)
                    r.copy(scheduledAtMillis = nextMillis, enabled = true)
                }
                val mutable = all.toMutableList()
                mutable[index] = updated
                Reminders.saveAll(context, mutable)
            }
        }

        TileRefresher.refresh(context, ReminderTile::class.java)
        Reminders.notifyChanged(context)
    }

    private fun handleSnooze(context: Context, id: String) {
        ReminderNotifier.cancel(context, id)
        val snoozeAt = System.currentTimeMillis() + SNOOZE_MINUTES * 60_000L

        synchronized(Reminders) {
            val all = Reminders.all(context)
            val index = all.indexOfFirst { it.id == id }
            if (index != -1) {
                val r = all[index]
                ReminderScheduler.scheduleSnooze(context, id, snoozeAt)
                if (r.repeat == ReminderRepeat.NONE) {
                    val mutable = all.toMutableList()
                    mutable[index] = r.copy(
                        scheduledAtMillis = snoozeAt,
                        enabled = true,
                        completed = false,
                        firedAtMillis = null,
                    )
                    Reminders.saveAll(context, mutable)
                }
            }
        }

        TileRefresher.refresh(context, ReminderTile::class.java)
        Reminders.notifyChanged(context)
    }

    companion object {
        const val ACTION_DONE = "app.utils.switchly.REMINDER_ACTION_DONE"
        const val ACTION_SNOOZE = "app.utils.switchly.REMINDER_ACTION_SNOOZE"
        const val EXTRA_REMINDER_ID = "reminder_id"
        private const val SNOOZE_MINUTES = 10L
    }
}
