package app.utils.switchly.publicmode

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import app.utils.switchly.MainActivity
import app.utils.switchly.R

object PublicModeOverlay {
    private const val TAG = "PublicModeOverlay"
    private var overlayView: View? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    @SuppressLint("SetTextI18n")
    fun show(context: Context, blockedPackage: String) {
        mainHandler.post {
            val pm = context.packageManager
            val appLabel = try {
                val info = pm.getApplicationInfo(blockedPackage, 0)
                pm.getApplicationLabel(info).toString()
            } catch (_: Exception) {
                blockedPackage
            }

            // Always redirect immediately to Home screen to minimize the restricted app
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            try {
                context.startActivity(homeIntent)
            } catch (e: Exception) {
                Log.w(TAG, "Cannot launch home intent", e)
            }

            // If overlay permission is not granted, launch transparent block activity
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
                PublicModeBlockActivity.start(context, blockedPackage)
                return@post
            }

            if (overlayView != null) {
                return@post
            }

            try {
                val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: run {
                    PublicModeBlockActivity.start(context, blockedPackage)
                    return@post
                }

                val appIcon = try {
                    pm.getApplicationIcon(blockedPackage)
                } catch (_: Exception) {
                    null
                }

                val endsAt = PublicMode.endsAt(context)
                val remainingMins = if (endsAt > 0) {
                    ((endsAt - System.currentTimeMillis()) / 60_000L).coerceAtLeast(0)
                } else {
                    0L
                }

                // Root scrim: deep obsidian translucent backdrop that consumes all touches
                val root = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    setBackgroundColor(Color.parseColor("#EE09090C"))
                    setPadding(dp(context, 24), dp(context, 24), dp(context, 24), dp(context, 24))
                    setOnTouchListener { _, _ -> true }
                }

                // Floating minimal card
                val card = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER_HORIZONTAL
                    setPadding(dp(context, 24), dp(context, 26), dp(context, 24), dp(context, 22))
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#FF17171C"))
                        cornerRadius = dp(context, 24).toFloat()
                        setStroke(dp(context, 1), Color.parseColor("#1FFFFFFF"))
                    }
                    // Prevent clicking inside card from triggering root dismiss
                    isClickable = true
                }

                // App Icon with subtle rounded background
                if (appIcon != null) {
                    val iconView = ImageView(context).apply {
                        setImageDrawable(appIcon)
                        scaleType = ImageView.ScaleType.FIT_CENTER
                    }
                    card.addView(iconView, LinearLayout.LayoutParams(dp(context, 52), dp(context, 52)))
                } else {
                    val iconContainer = LinearLayout(context).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER
                        setPadding(dp(context, 12), dp(context, 12), dp(context, 12), dp(context, 12))
                        background = GradientDrawable().apply {
                            setColor(Color.parseColor("#1AFFFFFF"))
                            shape = GradientDrawable.OVAL
                        }
                    }
                    val shieldIcon = ImageView(context).apply {
                        setImageResource(R.drawable.ic_tile_public_mode)
                        setColorFilter(Color.WHITE)
                    }
                    iconContainer.addView(shieldIcon, LinearLayout.LayoutParams(dp(context, 28), dp(context, 28)))
                    card.addView(iconContainer)
                }

                // App title
                val titleView = TextView(context).apply {
                    text = appLabel
                    setTextColor(Color.WHITE)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                    setPadding(0, dp(context, 12), 0, dp(context, 2))
                }
                card.addView(titleView)

                // Subtitle: Locked in Public Mode
                val subtitleView = TextView(context).apply {
                    text = "Locked in Public Mode"
                    setTextColor(Color.parseColor("#8E8D96"))
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    gravity = Gravity.CENTER
                    setPadding(0, 0, 0, if (remainingMins > 0) dp(context, 8) else dp(context, 20))
                }
                card.addView(subtitleView)

                // Remaining time pill (if timeout active)
                if (remainingMins > 0) {
                    val pillView = TextView(context).apply {
                        text = "Auto-unlocks in ~${remainingMins}m"
                        setTextColor(Color.parseColor("#A1A1AA"))
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                        gravity = Gravity.CENTER
                        setPadding(dp(context, 10), dp(context, 4), dp(context, 10), dp(context, 4))
                        background = GradientDrawable().apply {
                            setColor(Color.parseColor("#1E1E26"))
                            cornerRadius = dp(context, 99).toFloat()
                            setStroke(dp(context, 1), Color.parseColor("#15FFFFFF"))
                        }
                    }
                    val pillParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        bottomMargin = dp(context, 20)
                    }
                    card.addView(pillView, pillParams)
                }

                // Action Button: Back to Home (Clean minimal pill)
                val homeButton = Button(context).apply {
                    text = "Back to Home"
                    isAllCaps = false
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setTextColor(Color.parseColor("#09090B"))
                    typeface = Typeface.DEFAULT_BOLD
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#F4F4F5"))
                        cornerRadius = dp(context, 99).toFloat()
                    }
                    setOnClickListener {
                        dismiss()
                        try {
                            context.startActivity(homeIntent)
                        } catch (_: Exception) {}
                    }
                }
                val btnParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(context, 44)
                ).apply {
                    bottomMargin = dp(context, 8)
                }
                card.addView(homeButton, btnParams)

                // Action Button: Unlock with PIN (Subtle text button)
                val unlockButton = Button(context).apply {
                    text = "Unlock with PIN"
                    isAllCaps = false
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setTextColor(Color.parseColor("#A1A1AA"))
                    background = GradientDrawable().apply {
                        setColor(Color.TRANSPARENT)
                        cornerRadius = dp(context, 99).toFloat()
                    }
                    setOnClickListener {
                        dismiss()
                        val mainIntent = Intent(context, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            putExtra(app.utils.switchly.LaunchRoutes.EXTRA_ROUTE, app.utils.switchly.LaunchRoutes.tile("public_mode"))
                        }
                        try {
                            context.startActivity(mainIntent)
                        } catch (_: Exception) {}
                    }
                }
                card.addView(unlockButton, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(context, 38)
                ))

                val cardParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    leftMargin = dp(context, 20)
                    rightMargin = dp(context, 20)
                }
                root.addView(card, cardParams)

                val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.CENTER
                }

                windowManager.addView(root, params)
                overlayView = root

            } catch (e: Exception) {
                Log.e(TAG, "Failed to display WindowManager overlay, launching block activity fallback", e)
                overlayView = null
                PublicModeBlockActivity.start(context, blockedPackage)
            }
        }
    }

    fun dismiss() {
        mainHandler.post {
            val view = overlayView ?: return@post
            try {
                val windowManager = view.context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
                windowManager?.removeView(view)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove overlay view", e)
            } finally {
                overlayView = null
            }
        }
    }

    private fun dp(context: Context, value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            context.resources.displayMetrics
        ).toInt()
}
