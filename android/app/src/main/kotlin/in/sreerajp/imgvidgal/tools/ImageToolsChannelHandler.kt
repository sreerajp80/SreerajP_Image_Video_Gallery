package `in`.sreerajp.imgvidgal.tools

import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * The WEBP encoder Dart does not have.
 *
 * The `image` package can read WEBP but cannot write it, while Android has
 * had a WEBP encoder built into `Bitmap.compress` since API 14. Dart sends
 * plain RGBA pixels here and gets encoded bytes back; nothing else about the
 * conversion happens on this side.
 */
class ImageToolsChannelHandler(
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL_NAME).also {
        it.setMethodCallHandler(this)
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "encodeWebp" -> encodeWebp(call, result)
            else -> result.notImplemented()
        }
    }

    private fun encodeWebp(call: MethodCall, result: MethodChannel.Result) {
        val pixels = call.argument<ByteArray>("pixels")
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val quality = (call.argument<Int>("quality") ?: 85).coerceIn(0, 100)
        val lossless = call.argument<Boolean>("lossless") ?: false

        if (pixels == null || width <= 0 || height <= 0) {
            result.error(ERROR_INVALID_ARGUMENTS, "Pixel data and size are required", null)
            return
        }
        if (pixels.size != width * height * BYTES_PER_PIXEL) {
            result.error(
                ERROR_INVALID_ARGUMENTS,
                "Pixel data does not match the given size",
                null
            )
            return
        }

        // Encoding a large picture takes long enough to drop frames, so it
        // never runs on the main thread.
        worker.execute {
            var bitmap: Bitmap? = null
            try {
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(pixels))

                val stream = ByteArrayOutputStream(pixels.size / 4)
                val ok = bitmap.compress(webpFormat(lossless), quality, stream)
                val bytes = stream.toByteArray()

                if (!ok || bytes.isEmpty()) {
                    replyError(result, ERROR_ENCODE_FAILED, "The WEBP encoder produced nothing")
                } else {
                    mainHandler.post { result.success(bytes) }
                }
            } catch (error: Throwable) {
                // An out-of-memory on a very large picture is a real
                // possibility, so even Throwable is caught and reported.
                replyError(result, ERROR_ENCODE_FAILED, error.message ?: "WEBP encoding failed")
            } finally {
                bitmap?.recycle()
            }
        }
    }

    /**
     * The WEBP format constant this device understands.
     *
     * `WEBP_LOSSY` and `WEBP_LOSSLESS` arrived in API 30. On older devices
     * the single deprecated `WEBP` constant is the only choice, and it
     * follows the quality value in the same way.
     */
    @Suppress("DEPRECATION")
    private fun webpFormat(lossless: Boolean): Bitmap.CompressFormat {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (lossless) Bitmap.CompressFormat.WEBP_LOSSLESS
            else Bitmap.CompressFormat.WEBP_LOSSY
        } else {
            Bitmap.CompressFormat.WEBP
        }
    }

    private fun replyError(result: MethodChannel.Result, code: String, message: String) {
        mainHandler.post { result.error(code, message, null) }
    }

    companion object {
        private const val CHANNEL_NAME = "in.sreerajp.imgvidgal/imagetools"
        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val ERROR_ENCODE_FAILED = "encode_failed"
        private const val BYTES_PER_PIXEL = 4
    }
}
