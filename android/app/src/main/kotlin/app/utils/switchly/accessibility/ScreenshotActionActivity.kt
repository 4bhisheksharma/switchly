package app.utils.switchly.accessibility

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager

/**
 * Trampoline activity to reliably collapse the Quick Settings notification shade
 * across all OEM skins, then capture a clean screenshot once the shade is dismissed.
 */
class ScreenshotActionActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
        )
        finish()
        overridePendingTransition(0, 0)
        SwitchlyAccessibilityService.takeScreenshot(delayMs = 300L)
    }
}

