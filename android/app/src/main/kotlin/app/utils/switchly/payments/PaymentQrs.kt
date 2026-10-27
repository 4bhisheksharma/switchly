package app.utils.switchly.payments

import android.content.Context
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import org.json.JSONArray
import org.json.JSONException
import java.io.File

/** A saved payment QR image. Mirrors `PaymentQr` in lib/features/payment_qr/data/payment_qr.dart. */
data class PaymentQr(val id: String, val name: String, val path: String)

object PaymentQrs {
    /** Saved QRs whose image file still exists. */
    fun all(context: Context): List<PaymentQr> {
        val json = SharedConfig.getString(context, PrefKeys.PAYMENT_QRS) ?: return emptyList()
        return try {
            val array = JSONArray(json)
            (0 until array.length())
                .map { array.getJSONObject(it) }
                .map { PaymentQr(it.optString("id"), it.optString("name"), it.optString("path")) }
                .filter { File(it.path).isFile }
        } catch (e: JSONException) {
            Log.w("PaymentQrs", "Invalid payment QR list", e)
            emptyList()
        }
    }
}
