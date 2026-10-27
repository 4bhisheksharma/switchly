package app.utils.switchly.calendar

import android.content.Context
import android.util.Log
import app.utils.switchly.core.PrefKeys
import app.utils.switchly.core.SharedConfig
import org.json.JSONException
import org.json.JSONObject
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/** A Bikram Sambat date; [month] is 1..12 (Baishakh..Chaitra). */
data class BsDate(val year: Int, val month: Int, val day: Int)

/** AD → BS conversion and Nepali/English formatting. Matches `nepali_utils` in Flutter. */
object BikramSambat {
    /** BS 1970/01/01 is AD 1913-04-13. */
    private val EPOCH_AD = LocalDate.of(1913, 4, 13)
    private const val EPOCH_BS_YEAR = 1970

    private val MONTHS_EN = listOf(
        "Baishakh", "Jestha", "Ashadh", "Shrawan", "Bhadra", "Ashwin",
        "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra",
    )
    private val MONTHS_NE = listOf(
        "बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज",
        "कात्तिक", "मंसिर", "पुस", "माघ", "फागुन", "चैत",
    )
    private val WEEKDAYS_NE = mapOf(
        DayOfWeek.SUNDAY to "आइतबार", DayOfWeek.MONDAY to "सोमबार", DayOfWeek.TUESDAY to "मंगलबार",
        DayOfWeek.WEDNESDAY to "बुधबार", DayOfWeek.THURSDAY to "बिहीबार", DayOfWeek.FRIDAY to "शुक्रबार",
        DayOfWeek.SATURDAY to "शनिबार",
    )

    /** Null outside the supported range (AD 1913 to roughly 2193). */
    fun fromAd(date: LocalDate): BsDate? {
        var remaining = ChronoUnit.DAYS.between(EPOCH_AD, date)
        if (remaining < 0) return null
        var year = EPOCH_BS_YEAR
        while (true) {
            val months = monthsOf(year) ?: return null
            val yearDays = months.sum()
            if (remaining < yearDays) {
                var month = 0
                while (remaining >= months[month]) {
                    remaining -= months[month]
                    month++
                }
                return BsDate(year, month + 1, remaining.toInt() + 1)
            }
            remaining -= yearDays
            year++
        }
    }

    private fun monthsOf(year: Int): IntArray? = BsMonthData.MONTH_DAYS.getOrNull(year - BsMonthData.FIRST_YEAR)

    fun monthName(month: Int, nepali: Boolean): String = (if (nepali) MONTHS_NE else MONTHS_EN)[month - 1]

    fun weekday(day: DayOfWeek, nepali: Boolean): String =
        if (nepali) WEEKDAYS_NE.getValue(day) else day.name.lowercase().replaceFirstChar { it.uppercase() }

    /** Converts ASCII digits to Devanagari digits when [nepali]. */
    fun digits(value: Int, nepali: Boolean): String {
        val ascii = value.toString()
        return if (!nepali) ascii else ascii.map { '०' + (it - '0') }.joinToString("")
    }

    /** "कात्तिक ११, २०८३" / "Kartik 11, 2083". */
    fun format(date: BsDate, nepali: Boolean): String =
        "${monthName(date.month, nepali)} ${digits(date.day, nepali)}, ${digits(date.year, nepali)}"

    /** Whether to show Devanagari; set in the app, defaults to Nepali script. */
    fun useNepali(context: Context): Boolean {
        val json = SharedConfig.getString(context, PrefKeys.BS_CONFIG) ?: return true
        return try {
            JSONObject(json).optBoolean("nepali", true)
        } catch (e: JSONException) {
            Log.w("BikramSambat", "Invalid BS config", e)
            true
        }
    }
}
