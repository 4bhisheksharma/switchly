package app.utils.switchly.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.utils.switchly.tiles.ReminderTile
import app.utils.switchly.tiles.TileRefresher

/**
 * Restores scheduled alarms after device reboot, package update, or time/timezone changes.
 * Also delivers any active one-time reminder that was missed while the device was powered off.
 */
class ReminderBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != Intent.ACTION_TIME_CHANGED &&
            action != Intent.ACTION_TIMEZONE_CHANGED
        ) {
            return
        }

        val appContext = context.applicationContext
        val now = System.currentTimeMillis()

        synchronized(Reminders) {
            val all = Reminders.all(appContext)
            if (all.isEmpty()) {
                TileRefresher.refresh(appContext, ReminderTile::class.java)
                return
            }

            var changed = false
            val updated = all.map { reminder ->
                if (!reminder.isUpcoming) {
                    reminder
                } else if (reminder.scheduledAtMillis <= now) {
                    if (reminder.repeat == ReminderRepeat.NONE) {
                        if (reminder.firedAtMillis == null) {
                            ReminderNotifier.show(appContext, reminder)
                        }
                        changed = true
                        reminder.copy(enabled = false, firedAtMillis = reminder.firedAtMillis ?: now)
                    } else {
                        val nextMillis = Reminders.nextOccurrenceAfter(reminder.scheduledAtMillis, reminder.repeat, now)
                        if (nextMillis != null) {
                            changed = true
                            reminder.copy(scheduledAtMillis = nextMillis)
                        } else {
                            reminder
                        }
                    }
                } else {
                    reminder
                }
            }

            if (changed) {
                Reminders.saveAll(appContext, updated)
            }
        }

        ReminderScheduler.syncAll(appContext)
    }
}
