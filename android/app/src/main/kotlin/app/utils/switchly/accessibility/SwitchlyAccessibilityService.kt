package app.utils.switchly.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent

class SwitchlyAccessibilityService : AccessibilityService() {
    companion object {
        @Volatile
        var instance: SwitchlyAccessibilityService? = null
            private set

        fun isRunning(): Boolean = instance != null

        fun takeScreenshot(delayMs: Long = 350L, onComplete: ((Boolean) -> Unit)? = null): Boolean {
            val service = instance ?: return false
            Handler(Looper.getMainLooper()).postDelayed({
                val success = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    service.performGlobalAction(GLOBAL_ACTION_TAKE_SCREENSHOT)
                } else {
                    false
                }
                onComplete?.invoke(success)
            }, delayMs)
            return true
        }

        fun openSettings(context: Context) {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    override fun onDestroy() {
        if (instance == this) {
            instance = null
        }
        super.onDestroy()
    }
}

