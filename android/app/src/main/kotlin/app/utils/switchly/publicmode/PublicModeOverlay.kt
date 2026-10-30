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

            // Check if overlay permission is granted
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
                Toast.makeText(context, "$appLabel is restricted during Public Mode", Toast.LENGTH_LONG).show()
                return@post
            }

            if (overlayView != null) {
                return@post
            }

            try {
                val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return@post

                // Root full-screen container with sleek deep dark translucent backdrop
                val root = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    setBackgroundColor(Color.parseColor("#F5100F13"))
                    setPadding(dp(context, 24), dp(context, 24), dp(context, 24), dp(context, 24))
                }

                // Inner dialog card
                val card = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER_HORIZONTAL
                    setPadding(dp(context, 24), dp(context, 28), dp(context, 24), dp(context, 24))
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#FF1C1A22"))
                        cornerRadius = dp(context, 28).toFloat()
                        setStroke(dp(context, 1), Color.parseColor("#33FFFFFF"))
                    }
                }

                // Shield Icon Container
                val iconContainer = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER
                    setPadding(dp(context, 16), dp(context, 16), dp(context, 16), dp(context, 16))
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#33E53935"))
                        shape = GradientDrawable.OVAL
                    }
                }

                val shieldIcon = ImageView(context).apply {
                    setImageResource(R.drawable.ic_tile_public_mode)
                    setColorFilter(Color.parseColor("#FFFF5252"))
                }
                iconContainer.addView(shieldIcon, LinearLayout.LayoutParams(dp(context, 36), dp(context, 36)))
                card.addView(iconContainer)

                // Title
                val titleView = TextView(context).apply {
                    text = "App Restricted"
                    setTextColor(Color.WHITE)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                    setPadding(0, dp(context, 16), 0, dp(context, 8))
                }
                card.addView(titleView)

                // Message
                val messageView = TextView(context).apply {
                    text = "$appLabel is private and cannot be opened while Public Mode is active."
                    setTextColor(Color.parseColor("#B3FFFFFF"))
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    gravity = Gravity.CENTER
                    setLineSpacing(dp(context, 4).toFloat(), 1f)
                    setPadding(0, 0, 0, dp(context, 24))
                }
                card.addView(messageView)

                // Action Button: Return to Home
                val homeButton = Button(context).apply {
                    text = "Return to Home Screen"
                    isAllCaps = false
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    setTextColor(Color.WHITE)
                    typeface = Typeface.DEFAULT_BOLD
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#FF4F46E5")) // Vibrant primary indigo
                        cornerRadius = dp(context, 16).toFloat()
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
                    dp(context, 48)
                ).apply {
                    bottomMargin = dp(context, 10)
                }
                card.addView(homeButton, btnParams)

                // Action Button: Exit Public Mode
                val exitButton = Button(context).apply {
                    text = "Exit Public Mode"
                    isAllCaps = false
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setTextColor(Color.parseColor("#B3FFFFFF"))
                    background = GradientDrawable().apply {
                        setColor(Color.TRANSPARENT)
                        cornerRadius = dp(context, 16).toFloat()
                        setStroke(dp(context, 1), Color.parseColor("#33FFFFFF"))
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
                card.addView(exitButton, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(context, 44)
                ))

                val cardParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    leftMargin = dp(context, 16)
                    rightMargin = dp(context, 16)
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
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.CENTER
                }

                windowManager.addView(root, params)
                overlayView = root

                // Auto-dismiss after 7 seconds if the user does nothing
                mainHandler.postDelayed({
                    dismiss()
                }, 7000L)

            } catch (e: Exception) {
                Log.e(TAG, "Failed to display overlay", e)
                overlayView = null
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
