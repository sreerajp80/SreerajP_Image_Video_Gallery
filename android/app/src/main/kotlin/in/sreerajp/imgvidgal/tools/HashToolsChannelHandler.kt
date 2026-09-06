package `in`.sreerajp.imgvidgal.tools

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Fingerprints a media file without ever holding the whole thing in memory.
 *
 * Both jobs here exist because doing them in Dart would be reckless. A
 * SHA-256 over a two gigabyte video read through the normal byte channel
 * would need the whole file resident; here it is streamed in blocks and only
 * the digest crosses back. Likewise, the perceptual hashes need nothing but a
 * 32x32 grayscale grid, so the decoder is asked to downsample on the way in
 * rather than building a full-size bitmap that is thrown away a moment later.
 *
 * Every call is wrapped: a duplicate scan walks thousands of files and will
 * meet unreadable and corrupt ones, and each of those has to be an error
 * result the scan can skip, never a crash.
 */
class HashToolsChannelHandler(
    private val context: Context,
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
            "sha256" -> sha256(call, result)
            "grayscale" -> grayscale(call, result)
            else -> result.notImplemented()
        }
    }

    /** Streams the file at `uri` through SHA-256 and returns lower-case hex. */
    private fun sha256(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        val blockSize = (call.argument<Int>("blockSize") ?: DEFAULT_BLOCK_SIZE)
            .coerceIn(MIN_BLOCK_SIZE, MAX_BLOCK_SIZE)

        if (uri.isNullOrEmpty()) {
            result.error(ERROR_INVALID_ARGUMENTS, "A uri is required", null)
            return
        }

        worker.execute {
            try {
                val digest = MessageDigest.getInstance("SHA-256")
                val buffer = ByteArray(blockSize)

                openStream(uri).use { stream ->
                    if (stream == null) {
                        replyError(result, ERROR_UNREADABLE, "Could not open $uri")
                        return@execute
                    }
                    while (true) {
                        val read = stream.read(buffer)
                        if (read <= 0) break
                        digest.update(buffer, 0, read)
                    }
                }

                val hex = digest.digest().joinToString("") { byte ->
                    "%02x".format(byte)
                }
                mainHandler.post { result.success(hex) }
            } catch (error: Throwable) {
                replyError(result, ERROR_UNREADABLE, error.message ?: "Digest failed")
            }
        }
    }

    /**
     * Returns a `size` by `size` grayscale grid of the picture, row by row.
     *
     * The bitmap is decoded twice on purpose: once with `inJustDecodeBounds`
     * to learn how big it is, and once for real with an `inSampleSize` chosen
     * from that. Without the first pass a 50 megapixel photo would be fully
     * decoded before being shrunk, which is exactly the out-of-memory this
     * whole path exists to avoid.
     */
    private fun grayscale(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        val size = (call.argument<Int>("size") ?: DEFAULT_GRID_SIZE)
            .coerceIn(MIN_GRID_SIZE, MAX_GRID_SIZE)

        if (uri.isNullOrEmpty()) {
            result.error(ERROR_INVALID_ARGUMENTS, "A uri is required", null)
            return
        }

        worker.execute {
            var source: Bitmap? = null
            var scaled: Bitmap? = null
            try {
                val bounds = BitmapFactory.Options().apply {
                    inJustDecodeBounds = true
                }
                openStream(uri).use { stream ->
                    if (stream == null) {
                        replyError(result, ERROR_UNREADABLE, "Could not open $uri")
                        return@execute
                    }
                    BitmapFactory.decodeStream(stream, null, bounds)
                }
                if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                    replyError(result, ERROR_NOT_AN_IMAGE, "Not a decodable picture")
                    return@execute
                }

                val options = BitmapFactory.Options().apply {
                    inSampleSize = sampleSizeFor(
                        bounds.outWidth,
                        bounds.outHeight,
                        size
                    )
                    inPreferredConfig = Bitmap.Config.ARGB_8888
                }
                source = openStream(uri).use { stream ->
                    if (stream == null) null
                    else BitmapFactory.decodeStream(stream, null, options)
                }
                if (source == null) {
                    replyError(result, ERROR_NOT_AN_IMAGE, "Decoding produced nothing")
                    return@execute
                }

                scaled = Bitmap.createScaledBitmap(source, size, size, true)

                val pixels = IntArray(size * size)
                scaled.getPixels(pixels, 0, size, 0, 0, size, size)

                val grid = ByteArray(size * size)
                for (i in pixels.indices) {
                    val pixel = pixels[i]
                    val red = (pixel shr 16) and 0xFF
                    val green = (pixel shr 8) and 0xFF
                    val blue = pixel and 0xFF
                    // Rec. 601 luma, in fixed point so no float maths is done
                    // per pixel. The Dart fallback uses the same weights, so
                    // the two paths give comparable hashes.
                    val luma = (red * 299 + green * 587 + blue * 114) / 1000
                    grid[i] = luma.coerceIn(0, 255).toByte()
                }

                mainHandler.post { result.success(grid) }
            } catch (error: Throwable) {
                // An out-of-memory on a very large picture is a real
                // possibility, so even Throwable is caught and reported.
                replyError(
                    result,
                    ERROR_NOT_AN_IMAGE,
                    error.message ?: "Grayscale decoding failed"
                )
            } finally {
                scaled?.recycle()
                source?.recycle()
            }
        }
    }

    /**
     * The largest power-of-two shrink that still leaves at least `target`
     * pixels on the short side.
     *
     * `inSampleSize` only honours powers of two, so stopping one step early
     * keeps the grid from being built out of a bitmap smaller than itself.
     */
    private fun sampleSizeFor(width: Int, height: Int, target: Int): Int {
        var sample = 1
        var shortest = minOf(width, height)
        while (shortest / 2 >= target) {
            shortest /= 2
            sample *= 2
        }
        return sample
    }

    private fun openStream(uri: String): InputStream? {
        return try {
            context.contentResolver.openInputStream(Uri.parse(uri))
        } catch (_: Throwable) {
            null
        }
    }

    private fun replyError(
        result: MethodChannel.Result,
        code: String,
        message: String
    ) {
        mainHandler.post { result.error(code, message, null) }
    }

    companion object {
        private const val CHANNEL_NAME = "in.sreerajp.imgvidgal/hashtools"
        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val ERROR_UNREADABLE = "unreadable"
        private const val ERROR_NOT_AN_IMAGE = "not_an_image"

        private const val DEFAULT_BLOCK_SIZE = 64 * 1024
        private const val MIN_BLOCK_SIZE = 4 * 1024
        private const val MAX_BLOCK_SIZE = 1024 * 1024

        private const val DEFAULT_GRID_SIZE = 32
        private const val MIN_GRID_SIZE = 8
        private const val MAX_GRID_SIZE = 128
    }
}
