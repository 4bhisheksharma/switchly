package app.utils.switchly.audio

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import app.utils.switchly.core.SharedConfig
import app.utils.switchly.tiles.MicSwitcherTile
import app.utils.switchly.tiles.TileRefresher
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Manages microphone routing between Phone Built-in Mic, Bluetooth Earbuds, Wired Earphones,
 * and Auto (System Default).
 */
object MicRouter {
    private const val TAG = "MicRouter"
    private const val PREF_MIC_MODE = "mic_mode"

    const val MODE_AUTO = "auto"
    const val MODE_PHONE = "phone"
    const val MODE_EARBUDS = "earbuds"
    const val MODE_EARPHONES = "earphones"

    private val mainHandler = Handler(Looper.getMainLooper())
    private var isCallbackRegistered = false
    private var isModeListenerRegistered = false

    /** Listener callback for Flutter channel when mode changes. */
    var onModeChangedListener: ((String) -> Unit)? = null

    // Mic testing state
    private val isTesting = AtomicBoolean(false)
    private var testAudioRecord: AudioRecord? = null
    private var testThread: Thread? = null
    private var onLevelListener: ((Double) -> Unit)? = null

    /**
     * Initializes callbacks using the Application context so that connected/disconnected
     * devices immediately update the tile, and when a phone call or meeting starts,
     * preferred routing is automatically asserted without leaking Activity or Service instances.
     */
    fun ensureListeners(context: Context) {
        val appContext = context.applicationContext
        val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return

        if (!isCallbackRegistered) {
            audioManager.registerAudioDeviceCallback(object : AudioDeviceCallback() {
                override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
                    TileRefresher.refresh(appContext, MicSwitcherTile::class.java)
                    // If current mode is disconnected, re-evaluate
                    mainHandler.post { apply(appContext) }
                }

                override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
                    TileRefresher.refresh(appContext, MicSwitcherTile::class.java)
                    mainHandler.post { apply(appContext) }
                }
            }, mainHandler)
            isCallbackRegistered = true
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !isModeListenerRegistered) {
            val executor = Executors.newSingleThreadExecutor()
            audioManager.addOnModeChangedListener(executor) { mode ->
                if (mode == AudioManager.MODE_IN_CALL || mode == AudioManager.MODE_IN_COMMUNICATION) {
                    mainHandler.post { apply(appContext) }
                }
            }
            isModeListenerRegistered = true
        }
    }

    /**
     * Returns all available modes based on connected hardware:
     * - "auto" (always available)
     * - "phone" (always available)
     * - "earbuds" (if Bluetooth SCO/BLE headset is connected)
     * - "earphones" (if Wired or USB headset is connected)
     */
    fun getAvailableModes(context: Context): List<String> {
        val modes = mutableListOf(MODE_AUTO, MODE_PHONE)
        val audioManager = context.applicationContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return modes

        val inputDevices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
        val hasBluetooth = inputDevices.any { isBluetooth(it.type) }
        val hasWired = inputDevices.any { isWiredOrUsb(it.type) }

        if (hasBluetooth) modes.add(MODE_EARBUDS)
        if (hasWired) modes.add(MODE_EARPHONES)

        return modes
    }

    /** Current selected mode from preferences. Defaults to "auto". */
    fun getCurrentMode(context: Context): String {
        val appContext = context.applicationContext
        val saved = SharedConfig.nativeState(appContext).getString(PREF_MIC_MODE, MODE_AUTO) ?: MODE_AUTO
        val available = getAvailableModes(appContext)
        return if (available.contains(saved)) saved else MODE_AUTO
    }

    /** Saves and immediately asserts the microphone routing mode. */
    fun setMode(context: Context, mode: String, refreshTile: Boolean = true) {
        val appContext = context.applicationContext
        SharedConfig.nativeState(appContext).edit().putString(PREF_MIC_MODE, mode).apply()
        apply(appContext)

        if (refreshTile) {
            TileRefresher.refresh(appContext, MicSwitcherTile::class.java)
        }

        mainHandler.post {
            onModeChangedListener?.invoke(mode)
        }
    }

    /**
     * Cycles to the next available microphone mode and applies it.
     * Note: refreshTile is false here because BaseTile.runToggle() manages its own
     * in-place tile refresh without triggering an external SystemUI re-bind.
     */
    fun cycleNextMode(context: Context): String {
        val appContext = context.applicationContext
        val available = getAvailableModes(appContext)
        val current = getCurrentMode(appContext)
        val currentIndex = available.indexOf(current)
        val nextMode = if (currentIndex == -1) available.first() else available[(currentIndex + 1) % available.size]
        setMode(appContext, nextMode, refreshTile = false)
        return nextMode
    }

    /**
     * Applies routing to AudioManager.
     * On Android 12+, uses setCommunicationDevice with no-op check to avoid redundant re-routing.
     * On legacy Android, controls Bluetooth SCO state.
     */
    @Synchronized
    fun apply(context: Context) {
        val appContext = context.applicationContext
        val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        val mode = getCurrentMode(appContext)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                applyApi31(audioManager, mode)
            } else {
                applyLegacy(audioManager, mode)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to apply mic routing for mode $mode", e)
        }
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.S)
    private fun applyApi31(audioManager: AudioManager, mode: String) {
        if (mode == MODE_AUTO) {
            if (audioManager.communicationDevice != null) {
                audioManager.clearCommunicationDevice()
            }
            return
        }

        val available = audioManager.availableCommunicationDevices
        val target = when (mode) {
            MODE_PHONE -> {
                // Prefer handset earpiece (standard voice call), then speakerphone
                available.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
                    ?: available.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            }
            MODE_EARBUDS -> {
                available.firstOrNull { isBluetooth(it.type) }
            }
            MODE_EARPHONES -> {
                available.firstOrNull { isWiredOrUsb(it.type) }
            }
            else -> null
        }

        if (target != null) {
            // Avoid redundant re-routing if the desired device is already active
            if (audioManager.communicationDevice?.id == target.id) {
                return
            }
            val success = audioManager.setCommunicationDevice(target)
            Log.d(TAG, "setCommunicationDevice(${target.productName}, ${target.type}) result: $success")
        } else {
            if (audioManager.communicationDevice != null) {
                audioManager.clearCommunicationDevice()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun applyLegacy(audioManager: AudioManager, mode: String) {
        when (mode) {
            MODE_EARBUDS -> {
                if (!audioManager.isBluetoothScoOn) {
                    audioManager.startBluetoothSco()
                    audioManager.isBluetoothScoOn = true
                }
            }
            MODE_PHONE, MODE_EARPHONES, MODE_AUTO -> {
                if (audioManager.isBluetoothScoOn) {
                    audioManager.stopBluetoothSco()
                    audioManager.isBluetoothScoOn = false
                }
            }
        }
    }

    /**
     * Returns human-readable label and subtitle for a mode.
     */
    fun modeLabel(context: Context, mode: String): Pair<String, String> {
        val appContext = context.applicationContext
        val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val inputDevices = audioManager?.getDevices(AudioManager.GET_DEVICES_INPUTS) ?: emptyArray()

        return when (mode) {
            MODE_PHONE -> Pair("Phone Mic", "Built-in")
            MODE_EARBUDS -> {
                val btDevice = inputDevices.firstOrNull { isBluetooth(it.type) }
                val name = btDevice?.productName?.toString()?.takeIf { it.isNotBlank() } ?: "Earbuds Mic"
                Pair(name, "Bluetooth")
            }
            MODE_EARPHONES -> {
                val wiredDevice = inputDevices.firstOrNull { isWiredOrUsb(it.type) }
                val name = wiredDevice?.productName?.toString()?.takeIf { it.isNotBlank() } ?: "Earphones"
                Pair(name, "Wired / USB")
            }
            else -> Pair("Mic: Auto", "Auto (System)")
        }
    }

    /**
     * Lists connected input devices with details for Flutter UI.
     */
    fun getConnectedDevicesInfo(context: Context): List<Map<String, Any?>> {
        val appContext = context.applicationContext
        val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return emptyList()
        val currentMode = getCurrentMode(appContext)
        val inputDevices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)

        val result = mutableListOf<Map<String, Any?>>()

        // Phone Built-in Mic (always present)
        result.add(
            mapOf(
                "id" to "builtin_phone",
                "mode" to MODE_PHONE,
                "name" to "Phone Microphone",
                "type" to "builtin",
                "isConnected" to true,
                "isActive" to (currentMode == MODE_PHONE),
            )
        )

        // Bluetooth devices
        val btDevices = inputDevices.filter { isBluetooth(it.type) }
        if (btDevices.isNotEmpty()) {
            for (dev in btDevices) {
                val devName = dev.productName?.toString()?.takeIf { it.isNotBlank() } ?: "Bluetooth Earbuds"
                result.add(
                    mapOf(
                        "id" to "bt_${dev.id}",
                        "mode" to MODE_EARBUDS,
                        "name" to devName,
                        "type" to "bluetooth",
                        "isConnected" to true,
                        "isActive" to (currentMode == MODE_EARBUDS),
                    )
                )
            }
        } else {
            result.add(
                mapOf(
                    "id" to "bt_disconnected",
                    "mode" to MODE_EARBUDS,
                    "name" to "Bluetooth Earbuds",
                    "type" to "bluetooth",
                    "isConnected" to false,
                    "isActive" to false,
                )
            )
        }

        // Wired / USB devices
        val wiredDevices = inputDevices.filter { isWiredOrUsb(it.type) }
        if (wiredDevices.isNotEmpty()) {
            for (dev in wiredDevices) {
                val devName = dev.productName?.toString()?.takeIf { it.isNotBlank() } ?: "Wired Earphones"
                result.add(
                    mapOf(
                        "id" to "wired_${dev.id}",
                        "mode" to MODE_EARPHONES,
                        "name" to devName,
                        "type" to "wired",
                        "isConnected" to true,
                        "isActive" to (currentMode == MODE_EARPHONES),
                    )
                )
            }
        } else {
            result.add(
                mapOf(
                    "id" to "wired_disconnected",
                    "mode" to MODE_EARPHONES,
                    "name" to "Wired Earphones",
                    "type" to "wired",
                    "isConnected" to false,
                    "isActive" to false,
                )
            )
        }

        return result
    }

    /**
     * Starts listening to audio input samples to provide real-time decibel/amplitude
     * feedback in Flutter so the user can test their microphone.
     * Uses MediaRecorder.AudioSource.MIC to avoid interfering with telephony or VoIP state.
     */
    @Synchronized
    fun startMicTest(context: Context, onLevel: (Double) -> Unit): Boolean {
        if (isTesting.getAndSet(true)) {
            onLevelListener = onLevel
            return true
        }

        onLevelListener = onLevel
        val appContext = context.applicationContext
        val sampleRate = 44100
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat).coerceAtLeast(2048)

        try {
            val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val currentMode = getCurrentMode(appContext)

            val record = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize,
            )

            if (record.state != AudioRecord.STATE_INITIALIZED) {
                Log.w(TAG, "AudioRecord failed to initialize")
                record.release()
                stopMicTest()
                return false
            }

            // If API 23+, set preferred device on the AudioRecord if not in Auto
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && audioManager != null) {
                val inputs = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
                val preferred = when (currentMode) {
                    MODE_PHONE -> inputs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_MIC }
                    MODE_EARBUDS -> inputs.firstOrNull { isBluetooth(it.type) }
                    MODE_EARPHONES -> inputs.firstOrNull { isWiredOrUsb(it.type) }
                    else -> null
                }
                if (preferred != null) {
                    record.preferredDevice = preferred
                }
            }

            record.startRecording()
            testAudioRecord = record

            testThread = Thread({
                val buffer = ShortArray(bufferSize)
                while (isTesting.get()) {
                    val read = record.read(buffer, 0, buffer.size)
                    if (read > 0) {
                        var sum = 0.0
                        for (i in 0 until read) {
                            sum += (buffer[i] * buffer[i]).toDouble()
                        }
                        val rms = Math.sqrt(sum / read) / 32767.0
                        val level = (rms * 3.5).coerceIn(0.0, 1.0)
                        mainHandler.post { onLevelListener?.invoke(level) }
                    }
                    try {
                        Thread.sleep(60)
                    } catch (ignored: InterruptedException) {
                        break
                    }
                }
            }, "mic-test-thread").apply { start() }

            return true
        } catch (e: SecurityException) {
            Log.e(TAG, "Record permission missing for mic test", e)
            stopMicTest()
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start mic test", e)
            stopMicTest()
            return false
        }
    }

    /** Stops audio input monitoring for the test. */
    @Synchronized
    fun stopMicTest() {
        isTesting.set(false)
        onLevelListener = null
        try {
            testAudioRecord?.stop()
            testAudioRecord?.release()
        } catch (ignored: Exception) {}
        testAudioRecord = null
        testThread?.interrupt()
        testThread = null
    }

    private fun isBluetooth(type: Int): Boolean =
        type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && type == AudioDeviceInfo.TYPE_BLE_HEADSET) ||
            type == AudioDeviceInfo.TYPE_HEARING_AID

    private fun isWiredOrUsb(type: Int): Boolean =
        type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
            type == AudioDeviceInfo.TYPE_USB_HEADSET ||
            type == AudioDeviceInfo.TYPE_USB_DEVICE
}
