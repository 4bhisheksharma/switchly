package app.utils.switchly.core

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager

object Permissions {
    /** WRITE_SECURE_SETTINGS can only be granted over ADB: `pm grant <pkg> <perm>`. */
    fun hasWriteSecureSettings(context: Context): Boolean =
        context.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) ==
            PackageManager.PERMISSION_GRANTED
}
