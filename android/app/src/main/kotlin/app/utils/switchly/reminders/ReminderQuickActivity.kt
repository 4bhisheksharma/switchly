package app.utils.switchly.reminders

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.ContextThemeWrapper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.Toast
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R
import app.utils.switchly.tiles.ReminderTile
import app.utils.switchly.tiles.TileRefresher

/**
 * Lightweight dialog activity opened by the Reminders Quick Settings tile.
 * Mirrors QuickTextsActivity for reliable rendering across MIUI / HyperOS / OneUI.
 */
class ReminderQuickActivity : Activity() {
    private var dialog: AlertDialog? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)
        showRemindersDialog()
    }

    private fun showRemindersDialog() {
        val upcoming = Reminders.upcoming(this)
        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight)
        val builder = AlertDialog.Builder(themed)
            .setTitle(getString(R.string.tile_reminders))
            .setNeutralButton("Manage") { _, _ -> openRemindersScreen() }
            .setOnCancelListener { finish() }

        if (upcoming.isEmpty()) {
            builder
                .setMessage("No upcoming reminders scheduled. Create one to get a notification at the exact date and time.")
                .setPositiveButton("New reminder") { _, _ -> openRemindersScreen() }
                .setNegativeButton("Close") { _, _ -> finish() }
        } else {
            builder
                .setAdapter(adapter(themed, upcoming)) { _, which ->
                    showItemActions(themed, upcoming[which])
                }
                .setPositiveButton("New reminder") { _, _ -> openRemindersScreen() }
        }

        dialog?.dismiss()
        dialog = builder.create().apply {
            setOnDismissListener {
                // Only finish if no follow-up action dialog replaced it.
                if (dialog === this) finish()
            }
            show()
        }
    }

    private fun showItemActions(themed: Context, reminder: Reminder) {
        val actions = arrayOf("Mark as done", "Snooze 10 min", "Open in Switchly")
        val actionDialog = AlertDialog.Builder(themed)
            .setTitle(reminder.title)
            .setItems(actions) { _, which ->
                when (which) {
                    0 -> sendAction(ReminderActionReceiver.ACTION_DONE, reminder.id, "Marked done")
                    1 -> sendAction(ReminderActionReceiver.ACTION_SNOOZE, reminder.id, "Snoozed for 10 min")
                    2 -> openRemindersScreen()
                }
                finish()
            }
            .setOnCancelListener { finish() }
            .setOnDismissListener { finish() }
            .create()

        val previous = dialog
        dialog = actionDialog
        previous?.dismiss()
        actionDialog.show()
    }

    private fun sendAction(action: String, id: String, toastMessage: String) {
        sendBroadcast(
            Intent(this, ReminderActionReceiver::class.java).apply {
                this.action = action
                putExtra(ReminderActionReceiver.EXTRA_REMINDER_ID, id)
            },
        )
        TileRefresher.refresh(this, ReminderTile::class.java)
        Toast.makeText(this, toastMessage, Toast.LENGTH_SHORT).show()
    }

    private fun openRemindersScreen() {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("reminders"))
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
        finish()
    }

    private fun adapter(context: Context, items: List<Reminder>) =
        object : ArrayAdapter<Reminder>(context, R.layout.item_quick_text, items) {
            private val inflater = LayoutInflater.from(context)

            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val view = convertView ?: inflater.inflate(R.layout.item_quick_text, parent, false)
                val item = items[position]
                view.findViewById<TextView>(R.id.title).text = item.title
                val timeLine = buildString {
                    append(Reminders.formatDateTime(context, item.scheduledAtMillis))
                    if (item.repeat != ReminderRepeat.NONE) {
                        append(" · ")
                        append(item.repeat.label)
                    }
                    if (item.note.isNotBlank()) {
                        append("\n")
                        append(item.note.trim())
                    }
                }
                view.findViewById<TextView>(R.id.preview).text = timeLine
                return view
            }
        }

    override fun onDestroy() {
        val current = dialog
        dialog = null
        current?.dismiss()
        super.onDestroy()
    }
}
