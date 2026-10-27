package app.utils.switchly.power

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.text.format.DateFormat
import app.utils.switchly.R
import app.utils.switchly.tiles.CaffeineTile
import app.utils.switchly.tiles.TileRefresher

/**
 * Holds a screen wake lock while Caffeine is on. Stops itself when the time is up, when the
 * screen turns off (if the user wants that), or from the notification's "Turn off".
 */
class CaffeineService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val timeUp = Runnable { stopSelf() }
    private var wakeLock: PowerManager.WakeLock? = null
    private var screenOffRegistered = false

    private val screenOff = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            Caffeine.clear()
            stopSelf()
            return START_NOT_STICKY
        }
        val minutes = intent?.getIntExtra(EXTRA_MINUTES, 0) ?: 0
        // Must be called promptly after startForegroundService, even if we stop right away.
        startForegroundCompat(notification(minutes))

        handler.removeCallbacks(timeUp)
        if (minutes > 0) handler.postDelayed(timeUp, minutes * 60_000L)
        acquireWakeLock(minutes)

        val stopOnLock = Caffeine.config(this).stopOnLock
        if (stopOnLock && !screenOffRegistered) {
            registerReceiver(screenOff, IntentFilter(Intent.ACTION_SCREEN_OFF))
            screenOffRegistered = true
        } else if (!stopOnLock && screenOffRegistered) {
            unregisterReceiver(screenOff)
            screenOffRegistered = false
        }
        TileRefresher.refresh(this, CaffeineTile::class.java)
        // Not sticky: after a crash the screen should go back to normal, not stay on.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(timeUp)
        wakeLock?.takeIf { it.isHeld }?.release()
        if (screenOffRegistered) unregisterReceiver(screenOff)
        Caffeine.clear()
        TileRefresher.refresh(this, CaffeineTile::class.java)
        super.onDestroy()
    }

    // SCREEN_BRIGHT_WAKE_LOCK is deprecated, but FLAG_KEEP_SCREEN_ON needs a visible window.
    // No timeout for "no limit" is intended: it is released in onDestroy.
    @SuppressLint("WakelockTimeout")
    @Suppress("DEPRECATION")
    private fun acquireWakeLock(minutes: Int) {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ON_AFTER_RELEASE, "Switchly:Caffeine")
            .apply {
                setReferenceCounted(false)
                // The handler stops us on time; the timeout is a safety net if it doesn't.
                if (minutes > 0) acquire(minutes * 60_000L + 5_000) else acquire()
            }
    }

    private fun notification(minutes: Int): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, "Caffeine", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shown while Caffeine keeps the screen on"
                setShowBadge(false)
            },
        )
        val stop = PendingIntent.getService(
            this, 0, Intent(this, CaffeineService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val text = if (minutes > 0) {
            "Screen stays on until ${DateFormat.getTimeFormat(this).format(Caffeine.endsAt)}"
        } else {
            "Screen stays on until you turn it off"
        }
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_tile_coffee)
            .setContentTitle("Caffeine is on")
            .setContentText(text)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(Notification.Action.Builder(null, "Turn off", stop).build())
            .build()
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        const val EXTRA_MINUTES = "minutes"
        private const val ACTION_STOP = "app.utils.switchly.CAFFEINE_STOP"
        private const val CHANNEL = "caffeine"
        private const val NOTIFICATION_ID = 7
    }
}
