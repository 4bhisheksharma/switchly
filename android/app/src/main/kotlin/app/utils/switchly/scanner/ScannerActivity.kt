package app.utils.switchly.scanner

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.method.ScrollingMovementMethod
import android.util.Size
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import app.utils.switchly.R
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.MultiFormatReader
import com.google.zxing.NotFoundException
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.ReaderException
import com.google.zxing.common.HybridBinarizer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Full-screen QR scanner opened by the Scan QR tile. Decodes on the device with ZXing; nothing
 * leaves the phone. Links are shown in full and only opened when the user taps "Open link".
 */
class ScannerActivity : ComponentActivity() {
    private lateinit var analysisExecutor: ExecutorService
    private val reader = MultiFormatReader().apply {
        setHints(
            mapOf(
                DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE),
                DecodeHintType.TRY_HARDER to true,
                DecodeHintType.ALSO_INVERTED to true,
            ),
        )
    }

    /** False while a result is on screen, so frames are dropped instead of decoded. */
    @Volatile
    private var scanning = true
    private var camera: Camera? = null
    private var torchOn = false

    private lateinit var root: FrameLayout
    private lateinit var preview: PreviewView
    private lateinit var hint: TextView
    private lateinit var torch: ImageButton
    private lateinit var resultCard: LinearLayout

    private val requestCamera = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) startCamera() else showPermissionNeeded()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        analysisExecutor = Executors.newSingleThreadExecutor()
        buildLayout()
        setContentView(root)
        if (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            startCamera()
        } else {
            requestCamera.launch(Manifest.permission.CAMERA)
        }
    }

    override fun onDestroy() {
        analysisExecutor.shutdown()
        super.onDestroy()
    }

    private fun startCamera() {
        hint.text = "Point your camera at a QR code"
        val providerFuture = ProcessCameraProvider.getInstance(this)
        providerFuture.addListener({
            val provider = providerFuture.get()
            val previewUseCase = Preview.Builder().build().also { it.surfaceProvider = preview.surfaceProvider }
            val analysis = ImageAnalysis.Builder()
                .setResolutionSelector(
                    ResolutionSelector.Builder()
                        .setResolutionStrategy(
                            ResolutionStrategy(Size(1280, 720), ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER),
                        )
                        .build(),
                )
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also { it.setAnalyzer(analysisExecutor, ::analyze) }
            try {
                provider.unbindAll()
                camera = provider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, previewUseCase, analysis)
                torch.visibility = if (camera?.cameraInfo?.hasFlashUnit() == true) View.VISIBLE else View.GONE
            } catch (e: IllegalArgumentException) {
                hint.text = "No camera available" // No back camera on this device.
            }
        }, mainExecutor)
    }

    /** Runs on [analysisExecutor]. QR finder patterns work at any rotation, so frames aren't rotated. */
    private fun analyze(image: ImageProxy) {
        image.use {
            if (!scanning) return
            val plane = it.planes[0]
            val buffer = plane.buffer
            // The last row can be shorter than rowStride, so pad to a full rowStride * height.
            val data = ByteArray(plane.rowStride * it.height)
            buffer.get(data, 0, minOf(buffer.remaining(), data.size))
            val source = PlanarYUVLuminanceSource(data, plane.rowStride, it.height, 0, 0, it.width, it.height, false)
            val text = try {
                reader.decodeWithState(BinaryBitmap(HybridBinarizer(source))).text
            } catch (e: NotFoundException) {
                null
            } catch (e: ReaderException) {
                null // Found but unreadable (checksum/format); keep trying.
            } finally {
                reader.reset()
            }
            if (text != null && scanning) {
                scanning = false
                runOnUiThread { showResult(ScannedCode.parse(text)) }
            }
        }
    }

    private fun showResult(code: ScannedCode) {
        root.performHapticFeedback(
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY,
        )
        resultCard.removeAllViews()
        val (title, body) = when (code) {
            is ScannedCode.Openable -> code.title to code.raw.removePrefix("tel:").removePrefix("mailto:")
            is ScannedCode.Wifi -> "Wi-Fi network" to listOfNotNull(code.ssid, code.password?.let { "Password: $it" }).joinToString("\n")
            is ScannedCode.Text -> "Text" to code.raw
        }
        resultCard.addView(text(title, 13f, Color.argb(170, 255, 255, 255), bold = true))
        resultCard.addView(
            text(body, 17f, Color.WHITE).apply {
                maxLines = 8
                movementMethod = ScrollingMovementMethod()
                setTextIsSelectable(true)
            },
            LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(6f) },
        )
        val buttons = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        when (code) {
            is ScannedCode.Openable -> buttons.addView(button(code.action, primary = true) { open(code) })
            is ScannedCode.Wifi -> code.password?.let { pw ->
                buttons.addView(button("Copy password", primary = true) { copy(pw, "Wi-Fi password") })
            }
            is ScannedCode.Text -> Unit
        }
        if (code !is ScannedCode.Wifi || code.password == null) {
            buttons.addView(button("Copy", primary = code is ScannedCode.Text) { copy(code.raw, "QR code") })
        }
        buttons.addView(button("Scan again", primary = false) { resumeScanning() })
        resultCard.addView(
            HorizontalScrollView(this).apply {
                isHorizontalScrollBarEnabled = false
                addView(buttons)
            },
            LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(18f) },
        )
        resultCard.visibility = View.VISIBLE
        hint.visibility = View.INVISIBLE
    }

    private fun resumeScanning() {
        resultCard.visibility = View.GONE
        hint.visibility = View.VISIBLE
        scanning = true
    }

    private fun open(code: ScannedCode.Openable) {
        try {
            startActivity(code.intent())
            finish()
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(this, "No app can open this", Toast.LENGTH_SHORT).show()
        }
    }

    private fun copy(value: String, label: String) {
        getSystemService(ClipboardManager::class.java).setPrimaryClip(ClipData.newPlainText(label, value))
        // Android 13+ shows its own clipboard confirmation.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Toast.makeText(this, "Copied", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showPermissionNeeded() {
        hint.text = "Switchly needs camera access to scan QR codes. The camera is only used while this screen is open."
        resultCard.removeAllViews()
        val canAskAgain = shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)
        resultCard.addView(
            button(if (canAskAgain) "Allow camera" else "Open settings", primary = true) {
                if (canAskAgain) {
                    requestCamera.launch(Manifest.permission.CAMERA)
                } else {
                    startActivity(
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null)),
                    )
                    finish()
                }
            },
        )
        resultCard.visibility = View.VISIBLE
    }

    private fun toggleTorch() {
        torchOn = !torchOn
        camera?.cameraControl?.enableTorch(torchOn)
        torch.alpha = if (torchOn) 1f else 0.6f
    }

    private fun buildLayout() {
        root = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
        preview = PreviewView(this).apply { scaleType = PreviewView.ScaleType.FILL_CENTER }
        root.addView(preview, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))

        val frameSize = dp(260f)
        root.addView(
            View(this).apply {
                background = GradientDrawable().apply {
                    setStroke(dp(3f), Color.WHITE)
                    cornerRadius = dp(28f).toFloat()
                }
            },
            FrameLayout.LayoutParams(frameSize, frameSize, Gravity.CENTER),
        )
        hint = text("", 15f, Color.WHITE).apply {
            gravity = Gravity.CENTER
            setShadowLayer(8f, 0f, 0f, Color.BLACK)
        }
        root.addView(
            hint,
            FrameLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT, Gravity.CENTER).apply {
                topMargin = frameSize / 2 + dp(40f)
                leftMargin = dp(32f)
                rightMargin = dp(32f)
            },
        )

        root.addView(
            iconButton(R.drawable.ic_close, "Close") { finish() },
            FrameLayout.LayoutParams(dp(48f), dp(48f), Gravity.TOP or Gravity.START).apply {
                topMargin = dp(40f)
                leftMargin = dp(16f)
            },
        )
        torch = iconButton(R.drawable.ic_flash, "Flashlight") { toggleTorch() }.apply {
            alpha = 0.6f
            visibility = View.GONE
        }
        root.addView(
            torch,
            FrameLayout.LayoutParams(dp(48f), dp(48f), Gravity.TOP or Gravity.END).apply {
                topMargin = dp(40f)
                rightMargin = dp(16f)
            },
        )

        resultCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val pad = dp(24f)
            setPadding(pad, pad, pad, pad + dp(16f))
            background = GradientDrawable().apply {
                setColor(Color.rgb(28, 29, 34))
                cornerRadii = FloatArray(8) { i -> if (i < 4) dp(28f).toFloat() else 0f }
            }
            isClickable = true
            visibility = View.GONE
        }
        root.addView(resultCard, FrameLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT, Gravity.BOTTOM))
    }

    private fun text(value: String, sizeSp: Float, color: Int, bold: Boolean = false) = TextView(this).apply {
        text = value
        setTextColor(color)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
        if (bold) typeface = Typeface.DEFAULT_BOLD
    }

    private fun button(label: String, primary: Boolean, onClick: () -> Unit) = TextView(this).apply {
        text = label
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        typeface = Typeface.DEFAULT_BOLD
        setTextColor(if (primary) Color.BLACK else Color.WHITE)
        val h = dp(20f)
        val v = dp(12f)
        setPadding(h, v, h, v)
        background = GradientDrawable().apply {
            cornerRadius = dp(99f).toFloat()
            setColor(if (primary) Color.WHITE else Color.argb(40, 255, 255, 255))
        }
        layoutParams = LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { marginEnd = dp(10f) }
        setOnClickListener { onClick() }
    }

    private fun iconButton(icon: Int, description: String, onClick: () -> Unit) = ImageButton(this).apply {
        setImageResource(icon)
        setColorFilter(Color.WHITE)
        contentDescription = description
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.argb(90, 0, 0, 0))
        }
        setOnClickListener { onClick() }
    }

    private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()
}
