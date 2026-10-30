package app.utils.switchly.publicmode

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.activity.ComponentActivity
import app.utils.switchly.LaunchRoutes
import app.utils.switchly.MainActivity
import app.utils.switchly.R

/**
 * Fullscreen transparent lock activity for Public Mode.
 *
 * Ensures bulletproof app interception across OEM ROMs (Xiaomi/MIUI/HyperOS,
 * Samsung OneUI, OnePlus/Oppo/Realme ColorOS, Vivo FuntouchOS) where WindowManager
 * overlays might be suppressed, floating-windowed, or killed during app transitions.
 */
class PublicModeBlockActivity : ComponentActivity() {

    private var blockedPackage: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        blockedPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: ""

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                redirectToHome()
            }
        })

        buildUi()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        blockedPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: ""
        buildUi()
    }

    @SuppressLint("SetTextI18n")
    private fun buildUi() {
        val pm = packageManager
        val appLabel = try {
            val info = pm.getApplicationInfo(blockedPackage, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            blockedPackage.ifBlank { "Private App" }
        }

        val appIcon = try {
            pm.getApplicationIcon(blockedPackage)
        } catch (_: Exception) {
            null
        }

        val endsAt = PublicMode.endsAt(this)
        val remainingMins = if (endsAt > 0) {
            ((endsAt - System.currentTimeMillis()) / 60_000L).coerceAtLeast(0)
        } else {
            0L
        }

        // Root scrim: deep obsidian translucent backdrop
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#EE09090C"))
            setPadding(dp(24), dp(24), dp(24), dp(24))
            // Consume touches
            setOnTouchListener { _, _ -> true }
        }

        // Floating minimal card
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(26), dp(24), dp(22))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#FF17171C"))
                cornerRadius = dp(24).toFloat()
                setStroke(dp(1), Color.parseColor("#1FFFFFFF"))
            }
            isClickable = true
        }

        // App Icon
        if (appIcon != null) {
            val iconView = ImageView(this).apply {
                setImageDrawable(appIcon)
                scaleType = ImageView.ScaleType.FIT_CENTER
            }
            card.addView(iconView, LinearLayout.LayoutParams(dp(52), dp(52)))
        } else {
            val iconContainer = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                setPadding(dp(12), dp(12), dp(12), dp(12))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#1AFFFFFF"))
                    shape = GradientDrawable.OVAL
                }
            }
            val shieldIcon = ImageView(this).apply {
                setImageResource(R.drawable.ic_tile_public_mode)
                setColorFilter(Color.WHITE)
            }
            iconContainer.addView(shieldIcon, LinearLayout.LayoutParams(dp(28), dp(28)))
            card.addView(iconContainer)
        }

        // App title
        val titleView = TextView(this).apply {
            text = appLabel
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, dp(12), 0, dp(2))
        }
        card.addView(titleView)

        // Subtitle
        val subtitleView = TextView(this).apply {
            text = "Locked in Public Mode"
            setTextColor(Color.parseColor("#8E8D96"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, if (remainingMins > 0) dp(8) else dp(20))
        }
        card.addView(subtitleView)

        // Remaining time pill
        if (remainingMins > 0) {
            val pillView = TextView(this).apply {
                text = "Auto-unlocks in ~${remainingMins}m"
                setTextColor(Color.parseColor("#A1A1AA"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                gravity = Gravity.CENTER
                setPadding(dp(10), dp(4), dp(10), dp(4))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#1E1E26"))
                    cornerRadius = dp(99).toFloat()
                    setStroke(dp(1), Color.parseColor("#15FFFFFF"))
                }
            }
            val pillParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(20)
            }
            card.addView(pillView, pillParams)
        }

        // Action Button: Back to Home
        val homeButton = Button(this).apply {
            text = "Back to Home"
            isAllCaps = false
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(Color.parseColor("#09090B"))
            typeface = Typeface.DEFAULT_BOLD
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#F4F4F5"))
                cornerRadius = dp(99).toFloat()
            }
            setOnClickListener {
                redirectToHome()
            }
        }
        val btnParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            dp(44)
        ).apply {
            bottomMargin = dp(8)
        }
        card.addView(homeButton, btnParams)

        // Action Button: Unlock with PIN
        val unlockButton = Button(this).apply {
            text = "Unlock with PIN"
            isAllCaps = false
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTextColor(Color.parseColor("#A1A1AA"))
            background = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
                cornerRadius = dp(99).toFloat()
            }
            setOnClickListener {
                val mainIntent = Intent(this@PublicModeBlockActivity, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra(LaunchRoutes.EXTRA_ROUTE, LaunchRoutes.tile("public_mode"))
                }
                try {
                    startActivity(mainIntent)
                } catch (_: Exception) {}
                finish()
            }
        }
        card.addView(unlockButton, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            dp(38)
        ))

        val cardParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            leftMargin = dp(20)
            rightMargin = dp(20)
        }
        root.addView(card, cardParams)

        setContentView(root)
    }

    private fun redirectToHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        try {
            startActivity(homeIntent)
        } catch (_: Exception) {}
        finish()
    }

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()

    companion object {
        const val EXTRA_BLOCKED_PACKAGE = "extra_blocked_package"

        fun start(context: Context, packageName: String) {
            val intent = Intent(context, PublicModeBlockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(EXTRA_BLOCKED_PACKAGE, packageName)
            }
            try {
                context.startActivity(intent)
            } catch (_: Exception) {}
        }
    }
}
