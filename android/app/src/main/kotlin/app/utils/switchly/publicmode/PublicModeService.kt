package app.utils.switchly.publicmode

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import app.utils.switchly.MainActivity
import app.utils.switchly.R
import app.utils.switchly.tiles.TileRefresher

class PublicModeService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var isMonitoring = false
    private var isScreenOn = true
    private var screenReceiverRegistered = false
    private var lastBlockedPackageTriggered: String? = null
    private var lastBlockedTime = 0L

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOn = false
                    handler.removeCallbacks(monitorRunnable)
                }
                Intent.ACTION_SCREEN_ON -> {
                    isScreenOn = true
                    if (isMonitoring) {
                        handler.post(monitorRunnable)
                    }
                }
            }
        }
    }

    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (!isMonitoring || !isScreenOn) return

            checkForegroundApp()
            checkTimeout()

            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            PublicMode.deactivate(this)
            stopSelf()
            return START_NOT_STICKY
        }

        startForegroundCompat(createNotification())

        if (!screenReceiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            registerReceiver(screenReceiver, filter)
            screenReceiverRegistered = true
        }

        isMonitoring = true
        isScreenOn = true
        handler.removeCallbacks(monitorRunnable)
        handler.post(monitorRunnable)

        return START_STICKY
    }

    override fun onDestroy() {
        isMonitoring = false
        handler.removeCallbacks(monitorRunnable)
        if (screenReceiverRegistered) {
            try {
                unregisterReceiver(screenReceiver)
            } catch (_: Exception) {}
            screenReceiverRegistered = false
        }
        PublicModeOverlay.dismiss()
        TileRefresher.refreshAll(this)
        super.onDestroy()
    }

    private fun checkForegroundApp() {
        if (!PublicMode.hasUsageAccess(this)) return

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
        val config = PublicMode.config(this)
        if (config.blockedPackages.isEmpty()) return

        val endTime = System.currentTimeMillis()
        val startTime = endTime - 2500L

        try {
            val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()
            var currentForegroundPackage: String? = null

            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                val isResume = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    event.eventType == UsageEvents.Event.ACTIVITY_RESUMED
                } else {
                    @Suppress("DEPRECATION")
                    event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
                }
                if (isResume) {
                    currentForegroundPackage = event.packageName
                }
            }

            if (currentForegroundPackage != null &&
                currentForegroundPackage != packageName &&
                config.blockedPackages.contains(currentForegroundPackage)
            ) {
                // Debounce rapid continuous detections of the same package
                val now = System.currentTimeMillis()
                if (currentForegroundPackage != lastBlockedPackageTriggered || (now - lastBlockedTime > 2000L)) {
                    lastBlockedPackageTriggered = currentForegroundPackage
                    lastBlockedTime = now
                    PublicModeOverlay.show(this, currentForegroundPackage)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error checking foreground app", e)
        }
    }

    private fun checkTimeout() {
        val endsAt = PublicMode.endsAt(this)
        if (endsAt > 0 && System.currentTimeMillis() >= endsAt) {
            Log.i(TAG, "Public Mode timeout reached, auto-deactivating")
            PublicMode.deactivate(this)
            stopSelf()
        }
    }

    private fun createNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Public Mode",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shown while Public Mode is preparing your device for someone else"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }

        val endsAt = PublicMode.endsAt(this)
        val text = if (endsAt > 0) {
            val remainingMillis = endsAt - System.currentTimeMillis()
            val remainingMinutes = (remainingMillis / 60_000L).coerceAtLeast(0)
            if (remainingMinutes > 0) {
                "Protecting your private apps · Restores in ~$remainingMinutes min"
            } else {
                "Protecting your private apps · Ending shortly"
            }
        } else {
            "Protecting your private apps · Active until turned off"
        }

        // Tap notification to open Switchly Public Mode screen
        val contentIntent = PendingIntent.getActivity(
            this,
            1,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra(app.utils.switchly.LaunchRoutes.EXTRA_ROUTE, app.utils.switchly.LaunchRoutes.tile("public_mode"))
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Exit action button
        val exitIntent = PendingIntent.getService(
            this,
            2,
            Intent(this, PublicModeService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(R.drawable.ic_tile_public_mode)
            .setContentTitle("Public Mode is Active")
            .setContentText(text)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(Notification.Action.Builder(null, "Exit Public Mode", exitIntent).build())
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
        private const val TAG = "PublicModeService"
        const val ACTION_START = "app.utils.switchly.PUBLIC_MODE_START"
        const val ACTION_STOP = "app.utils.switchly.PUBLIC_MODE_STOP"
        const val EXTRA_ENDS_AT = "ends_at"
        private const val CHANNEL_ID = "public_mode_channel"
        private const val NOTIFICATION_ID = 42
        private const val POLL_INTERVAL_MS = 350L
    }
}
