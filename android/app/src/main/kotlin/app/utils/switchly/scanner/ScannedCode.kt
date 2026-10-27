package app.utils.switchly.scanner

import android.content.Intent
import android.net.Uri
import android.util.Patterns

/** What a scanned QR contains, and the action offered for it. */
sealed interface ScannedCode {
    val raw: String

    /** Something to open in another app (browser, dialer, mail, maps). */
    data class Openable(override val raw: String, val title: String, val action: String, val uri: Uri) : ScannedCode {
        fun intent() = Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    data class Wifi(override val raw: String, val ssid: String, val password: String?) : ScannedCode

    data class Text(override val raw: String) : ScannedCode

    companion object {
        fun parse(text: String): ScannedCode {
            val trimmed = text.trim()
            val lower = trimmed.lowercase()
            return when {
                lower.startsWith("http://") || lower.startsWith("https://") ->
                    Openable(trimmed, "Link", "Open link", Uri.parse(trimmed))
                // Bare domains like "example.com/menu".
                !trimmed.contains(' ') && Patterns.WEB_URL.matcher(trimmed).matches() && '.' in trimmed ->
                    Openable(trimmed, "Link", "Open link", Uri.parse("https://$trimmed"))
                lower.startsWith("tel:") -> Openable(trimmed, "Phone number", "Call", Uri.parse(trimmed))
                lower.startsWith("mailto:") -> Openable(trimmed, "Email address", "Email", Uri.parse(trimmed))
                lower.startsWith("geo:") -> Openable(trimmed, "Location", "Open map", Uri.parse(trimmed))
                lower.startsWith("wifi:") -> parseWifi(trimmed)
                else -> Text(trimmed)
            }
        }

        /** `WIFI:T:WPA;S:Cafe;P:secret;;` with `\` escaping `;`, `,`, `:` and `\`. */
        private fun parseWifi(text: String): ScannedCode {
            val fields = mutableMapOf<String, String>()
            val body = text.substring(5)
            var key = StringBuilder()
            var value = StringBuilder()
            var inValue = false
            var escaped = false
            for (c in body) {
                when {
                    escaped -> { (if (inValue) value else key).append(c); escaped = false }
                    c == '\\' -> escaped = true
                    !inValue && c == ':' -> inValue = true
                    c == ';' -> {
                        if (key.isNotEmpty()) fields[key.toString().uppercase()] = value.toString()
                        key = StringBuilder(); value = StringBuilder(); inValue = false
                    }
                    else -> (if (inValue) value else key).append(c)
                }
            }
            val ssid = fields["S"] ?: return Text(text)
            return Wifi(text, ssid, fields["P"]?.takeIf { it.isNotEmpty() })
        }
    }
}
