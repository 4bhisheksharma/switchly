package app.utils.switchly.reminders

import android.content.Context
import android.content.Intent
import android.text.format.DateFormat
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.util.Calendar
import java.util.Date

enum class ReminderRepeat(val key: String, val label: String) {
    NONE("none", "Once"),
    DAILY("daily", "Daily"),
    WEEKLY("weekly", "Weekly"),
    MONTHLY("monthly", "Monthly");

    companion object {
        fun fromKey(key: String?): ReminderRepeat =
            entries.firstOrNull { it.key == key } ?: NONE
    }
}

/** A scheduled reminder. Mirrors `Reminder` in lib/features/reminders/data/reminder_models.dart. */
data class Reminder(
    val id: String,
    val title: String,
    val note: String,
    val scheduledAtMillis: Long,
    val repeat: ReminderRepeat = ReminderRepeat.NONE,
    val enabled: Boolean = true,
    val completed: Boolean = false,
    val createdAtMillis: Long = 0L,
    val firedAtMillis: Long? = null,
    val completedAtMillis: Long? = null,
) {
    val isUpcoming: Boolean get() = enabled && !completed

    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("title", title)
        put("note", note)
        put("scheduledAtMillis", scheduledAtMillis)
        put("repeat", repeat.key)
        put("enabled", enabled)
        put("completed", completed)
        put("createdAtMillis", createdAtMillis)
        put("firedAtMillis", firedAtMillis ?: JSONObject.NULL)
        put("completedAtMillis", completedAtMillis ?: JSONObject.NULL)
    }

    companion object {
        fun fromJson(json: JSONObject): Reminder {
            val id = json.optString("id", "")
            val title = json.optString("title", "")
            return Reminder(
                id = id,
                title = title,
                note = json.optString("note", ""),
                scheduledAtMillis = json.optLong("scheduledAtMillis", 0L),
                repeat = ReminderRepeat.fromKey(json.optString("repeat", "none")),
                enabled = json.optBoolean("enabled", true),
                completed = json.optBoolean("completed", false),
                createdAtMillis = json.optLong("createdAtMillis", 0L),
                firedAtMillis = if (json.isNull("firedAtMillis")) null else json.optLong("firedAtMillis"),
                completedAtMillis = if (json.isNull("completedAtMillis")) null else json.optLong("completedAtMillis"),
            )
        }
    }
}

object Reminders {
    private const val TAG = "Reminders"
    private const val FLUTTER_PREFS_FILE = "FlutterSharedPreferences"
    private const val FLUTTER_PREFIX = "flutter."

    const val ACTION_REMINDERS_CHANGED = "app.utils.switchly.REMINDERS_CHANGED"
    const val TEST_NOTIFICATION_ID = 9999

    @Synchronized
    fun all(context: Context): List<Reminder> {
        val raw = SharedConfig.getString(context, PrefKeys.REMINDERS) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            buildList(array.length()) {
                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    val r = Reminder.fromJson(obj)
                    if (r.id.isNotBlank() && r.title.isNotBlank()) add(r)
                }
            }
        } catch (e: JSONException) {
            Log.w(TAG, "Invalid reminders JSON", e)
            emptyList()
        }
    }

    @Synchronized
    fun saveAll(context: Context, reminders: List<Reminder>) {
        val array = JSONArray()
        for (reminder in reminders) {
            array.put(reminder.toJson())
        }
        val prefs = context.getSharedPreferences(FLUTTER_PREFS_FILE, Context.MODE_PRIVATE)
        prefs.edit().putString(FLUTTER_PREFIX + PrefKeys.REMINDERS, array.toString()).commit()
    }

    fun upcoming(context: Context): List<Reminder> =
        all(context)
            .filter { it.isUpcoming }
            .sortedBy { it.scheduledAtMillis }

    fun nextUpcoming(context: Context): Reminder? = upcoming(context).firstOrNull()

    /**
     * Deterministic positive notification / PendingIntent ID derived from [id] via FNV-1a 32-bit.
     * Kept in [10_000, 1_000_009_999] so it never collides with Caffeine (7) or PublicMode (42).
     */
    fun notificationId(id: String): Int {
        var hash = 0x811c9dc5.toInt()
        for (ch in id) {
            hash = hash xor ch.code
            hash *= 0x01000193
        }
        val positive = hash and 0x7fffffff
        return 10_000 + (positive % 1_000_000_000)
    }

    fun snoozeRequestCode(id: String): Int = notificationId(id) xor 0x10000000

    /**
     * Computes the next occurrence strictly after [nowMillis] for repeating reminders,
     * preserving local wall-clock time across DST changes and clamping month-end dates cleanly.
     */
    fun nextOccurrenceAfter(baseMillis: Long, repeat: ReminderRepeat, nowMillis: Long): Long? {
        if (repeat == ReminderRepeat.NONE) return null
        val cal = Calendar.getInstance()
        if (repeat == ReminderRepeat.MONTHLY) {
            var steps = 1
            while (true) {
                cal.timeInMillis = baseMillis
                cal.add(Calendar.MONTH, steps)
                if (cal.timeInMillis > nowMillis) return cal.timeInMillis
                steps++
                if (steps > 1200) return null
            }
        } else {
            cal.timeInMillis = baseMillis
            val field = Calendar.DAY_OF_YEAR
            val step = if (repeat == ReminderRepeat.WEEKLY) 7 else 1
            while (cal.timeInMillis <= nowMillis) {
                cal.add(field, step)
            }
            return cal.timeInMillis
        }
    }

    fun formatDateTime(context: Context, millis: Long): String {
        val date = Date(millis)
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply { timeInMillis = millis }
        val tomorrow = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) }

        val timeText = DateFormat.getTimeFormat(context).format(date)
        return when {
            sameDay(now, target) -> "Today, $timeText"
            sameDay(tomorrow, target) -> "Tomorrow, $timeText"
            else -> "${DateFormat.getMediumDateFormat(context).format(date)} · $timeText"
        }
    }

    fun formatCompactTileTime(context: Context, millis: Long): String {
        val date = Date(millis)
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply { timeInMillis = millis }
        val timeText = DateFormat.getTimeFormat(context).format(date)
        return if (sameDay(now, target)) {
            timeText
        } else {
            val dayMonth = DateFormat.format("MMM d", date).toString()
            "$dayMonth, $timeText"
        }
    }

    private fun sameDay(a: Calendar, b: Calendar): Boolean =
        a.get(Calendar.YEAR) == b.get(Calendar.YEAR) &&
            a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)

    fun notifyChanged(context: Context) {
        val intent = Intent(ACTION_REMINDERS_CHANGED).setPackage(context.packageName)
        context.sendBroadcast(intent)
    }
}
