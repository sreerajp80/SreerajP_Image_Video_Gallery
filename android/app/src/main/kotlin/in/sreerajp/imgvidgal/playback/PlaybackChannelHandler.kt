package `in`.sreerajp.imgvidgal.playback

import android.app.Activity
import android.content.Context
import android.media.AudioManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Screen brightness, media volume, and keep-awake for the fullscreen viewer.
 *
 * Brightness is set on the activity window only, so it never changes the
 * device-wide setting and Android restores it when the app leaves the
 * foreground. Volume goes to the music stream. None of this needs an extra
 * Android permission.
 */
class PlaybackChannelHandler(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL_NAME).also {
        it.setMethodCallHandler(this)
    }

    private val audioManager: AudioManager? =
        activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getBrightness" -> result.success(currentBrightness())
            "setBrightness" -> {
                val value = call.argument<Double>("value")
                if (value == null) {
                    result.error(ERROR_INVALID_ARGUMENTS, "value is required", null)
                } else {
                    applyBrightness(value.toFloat().coerceIn(0f, 1f))
                    result.success(null)
                }
            }
            "resetBrightness" -> {
                applyBrightness(WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE)
                result.success(null)
            }
            "getVolume" -> result.success(currentVolume())
            "setVolume" -> {
                val value = call.argument<Double>("value")
                if (value == null) {
                    result.error(ERROR_INVALID_ARGUMENTS, "value is required", null)
                } else {
                    applyVolume(value.toFloat().coerceIn(0f, 1f))
                    result.success(null)
                }
            }
            "setKeepScreenOn" -> {
                applyKeepScreenOn(call.argument<Boolean>("keepOn") ?: false)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Window brightness, or the device setting while the window still follows
     * the system (which is what a negative override value means).
     */
    private fun currentBrightness(): Double {
        val override = activity.window.attributes.screenBrightness
        if (override >= 0f) return override.toDouble()

        return try {
            val level = Settings.System.getInt(
                activity.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS
            )
            (level / 255.0).coerceIn(0.0, 1.0)
        } catch (e: Settings.SettingNotFoundException) {
            DEFAULT_BRIGHTNESS
        }
    }

    private fun applyBrightness(value: Float) {
        activity.runOnUiThread {
            val attributes = activity.window.attributes
            attributes.screenBrightness = value
            activity.window.attributes = attributes
        }
    }

    private fun currentVolume(): Double {
        val manager = audioManager ?: return DEFAULT_VOLUME
        val max = manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (max <= 0) return DEFAULT_VOLUME
        val current = manager.getStreamVolume(AudioManager.STREAM_MUSIC)
        return (current.toDouble() / max).coerceIn(0.0, 1.0)
    }

    private fun applyVolume(value: Float) {
        val manager = audioManager ?: return
        val max = manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (max <= 0) return
        val target = Math.round(value * max).coerceIn(0, max)
        try {
            manager.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
        } catch (e: SecurityException) {
            // Some devices block volume changes while Do Not Disturb is on.
            // Playback carries on without the gesture.
        }
    }

    private fun applyKeepScreenOn(keepOn: Boolean) {
        activity.runOnUiThread {
            if (keepOn) {
                activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    companion object {
        const val CHANNEL_NAME = "in.sreerajp.imgvidgal/playback"

        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val DEFAULT_BRIGHTNESS = 0.5
        private const val DEFAULT_VOLUME = 1.0
    }
}
