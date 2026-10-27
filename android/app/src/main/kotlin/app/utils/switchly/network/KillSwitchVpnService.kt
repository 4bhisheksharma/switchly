package app.utils.switchly.network

import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

/**
 * The kill switch's VPN. It claims every IPv4 and IPv6 route and never reads the tunnel, so
 * packets are dropped. No traffic is inspected or forwarded anywhere.
 *
 * Once established, the system keeps the service bound (and shows the key icon) until
 * [ACTION_STOP], the user disconnects it, or another VPN takes over ([onRevoke]).
 */
class KillSwitchVpnService : VpnService() {
    private var tunnel: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopTunnel()
            return START_NOT_STICKY
        }
        startTunnel()
        return START_STICKY
    }

    private fun startTunnel() {
        val builder = Builder()
            .setSession("Switchly kill switch")
            .addAddress("10.111.0.1", 32)
            .addRoute("0.0.0.0", 0)
            .addAddress("fd00:5717::1", 128)
            .addRoute("::", 0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false)
        for (pkg in KillSwitch.allowedApps(this)) {
            try {
                builder.addDisallowedApplication(pkg) // "Disallowed" from the VPN = stays online.
            } catch (e: PackageManager.NameNotFoundException) {
                Log.i(TAG, "Allowed app $pkg is no longer installed")
            }
        }
        // Returns null if consent was revoked. Re-establishing replaces the old interface.
        val next = builder.establish()
        if (next == null) {
            stopTunnel()
            return
        }
        tunnel?.close()
        tunnel = next
        running = true
    }

    private fun stopTunnel() {
        tunnel?.close()
        tunnel = null
        running = false
        stopSelf()
    }

    override fun onRevoke() {
        stopTunnel()
        super.onRevoke()
    }

    override fun onDestroy() {
        tunnel?.close()
        tunnel = null
        running = false
        super.onDestroy()
    }

    companion object {
        private const val TAG = "KillSwitchVpn"
        const val ACTION_STOP = "app.utils.switchly.KILL_SWITCH_STOP"

        @Volatile
        var running = false
            private set
    }
}
