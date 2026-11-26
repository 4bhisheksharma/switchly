package app.utils.switchly.reminders

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log
import app.utils.switchly.tiles.ReminderTile
import app.utils.switchly.tiles.TileRefresher

/** Fires when a scheduled reminder (or snooze) alarm triggers. */
class ReminderReceiver : BroadcastReceiver() {

    @SuppressLint("WakelockTimeout")
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(EXTRA_REMINDER_ID) ?: return
        val isSnooze = intent.getBooleanExtra(EXTRA_IS_SNOOZE, false)

        val pm = context.getSystemService(PowerManager::class.java)
        val wakeLock = pm?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Switchly:ReminderReceiver")
        try {
            wakeLock?.acquire(5_000L)
            handleTrigger(context.applicationContext, id, isSnooze)
        } catch (e: Exception) {
            Log.e(TAG, "Failed handling reminder trigger $id", e)
        } finally {
            if (wakeLock?.isHeld == true) {
                try {
                    wakeLock.release()
                } catch (_: Exception) {}
            }
        }
    }

    private fun handleTrigger(context: Context, id: String, isSnooze: Boolean) {
        synchronized(Reminders) {
            val all = Reminders.all(context)
            val index = all.indexOfFirst { it.id == id }
            if (index == -1) return

            val reminder = all[index]
            if (reminder.completed) return
            if (!isSnooze && !reminder.enabled) return

            ReminderNotifier.show(context, reminder, isSnooze = isSnooze)

            val now = System.currentTimeMillis()
            val updated = when {
                isSnooze && reminder.repeat != ReminderRepeat.NONE -> {
                    // Snooze fired for a repeating reminder; keep its main schedule untouched.
                    reminder.copy(firedAtMillis = now)
                }
                reminder.repeat == ReminderRepeat.NONE -> {
                    reminder.copy(enabled = false, firedAtMillis = now)
                }
                else -> {
                    val nextMillis = Reminders.nextOccurrenceAfter(reminder.scheduledAtMillis, reminder.repeat, now)
                    if (nextMillis != null) {
                        ReminderScheduler.scheduleAlarm(context, reminder.id, nextMillis)
                        reminder.copy(scheduledAtMillis = nextMillis, firedAtMillis = now, enabled = true)
                    } else {
                        reminder.copy(enabled = false, firedAtMillis = now)
                    }
                }
            }

            val mutable = all.toMutableList()
            mutable[index] = updated
            Reminders.saveAll(context, mutable)
        }

        TileRefresher.refresh(context, ReminderTile::class.java)
        Reminders.notifyChanged(context)
    }

    companion object {
        private const val TAG = "ReminderReceiver"
        const val ACTION_TRIGGER = "app.utils.switchly.REMINDER_TRIGGER"
        const val ACTION_TRIGGER_SNOOZE = "app.utils.switchly.REMINDER_TRIGGER_SNOOZE"
        const val EXTRA_REMINDER_ID = "reminder_id"
        const val EXTRA_IS_SNOOZE = "is_snooze"
    }
}
