package `in`.sreerajp.imgvidgal.barcode

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.LuminanceSource
import com.google.zxing.MultiFormatReader
import com.google.zxing.NotFoundException
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.Result
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.multi.GenericMultipleBarcodeReader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.EnumMap
import java.util.concurrent.Executors

/**
 * Reads barcodes and QR codes with ZXing core (Apache-2.0).
 *
 * This replaced mobile_scanner, which used Google's closed-source ML Kit
 * (G47). ZXing is plain Java with no dependencies of its own and no network
 * code. Everything that arrives here is treated as untrusted: a file path is
 * checked before it is opened, and camera bytes are checked against the size
 * they claim before they are read.
 *
 * Decoding runs on one background thread. A failure is returned as an error
 * code, never thrown across the channel.
 */
class BarcodeChannelHandler(
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
            "decodeImageFile" -> decodeImageFile(call, result)
            "decodeLuminance" -> decodeLuminance(call, result)
            else -> result.notImplemented()
        }
    }

    /** Every code in a still picture, in any supported format. */
    private fun decodeImageFile(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path.isNullOrBlank()) {
            result.error(ERROR_INVALID_ARGUMENTS, "No path was given", null)
            return
        }

        worker.execute {
            try {
                val file = File(path)
                if (!file.isFile || !file.canRead()) {
                    reply(result, error = ERROR_UNREADABLE)
                    return@execute
                }
                if (file.length() > MAX_FILE_BYTES) {
                    reply(result, error = ERROR_TOO_LARGE)
                    return@execute
                }
                val bitmap = loadScaled(file)
                if (bitmap == null) {
                    reply(result, error = ERROR_UNREADABLE)
                    return@execute
                }
                val source = try {
                    rgbSource(bitmap)
                } finally {
                    bitmap.recycle()
                }
                reply(result, codes = decodeAll(source, ALL_FORMATS))
            } catch (error: OutOfMemoryError) {
                reply(result, error = ERROR_TOO_LARGE)
            } catch (error: Exception) {
                reply(result, error = ERROR_DECODE_FAILED)
            }
        }
    }

    /**
     * QR codes in one camera frame, given as its brightness (Y) plane only.
     *
     * The colour planes are never sent: a barcode reader needs light and
     * dark, nothing else.
     */
    private fun decodeLuminance(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val rowStride = call.argument<Int>("rowStride") ?: 0

        // Untrusted sizes: checked before a single byte is read.
        val valid = bytes != null &&
            width in 1..MAX_FRAME_SIDE &&
            height in 1..MAX_FRAME_SIDE &&
            rowStride >= width &&
            bytes.size.toLong() >= rowStride.toLong() * (height - 1) + width
        if (!valid) {
            result.error(ERROR_INVALID_ARGUMENTS, "Frame data does not match its size", null)
            return
        }

        worker.execute {
            try {
                val source = PlanarYUVLuminanceSource(
                    bytes, rowStride, height, 0, 0, width, height, false
                )
                reply(result, codes = decodeAll(source, QR_ONLY))
            } catch (error: Exception) {
                reply(result, error = ERROR_DECODE_FAILED)
            }
        }
    }

    private fun decodeAll(
        source: LuminanceSource,
        formats: Collection<BarcodeFormat>
    ): List<Map<String, String>> {
        val hints = EnumMap<DecodeHintType, Any>(DecodeHintType::class.java).apply {
            put(DecodeHintType.POSSIBLE_FORMATS, formats)
            put(DecodeHintType.TRY_HARDER, true)
        }
        val reader = MultiFormatReader().apply { setHints(hints) }
        val found: Array<Result> = try {
            GenericMultipleBarcodeReader(reader)
                .decodeMultiple(BinaryBitmap(HybridBinarizer(source)), hints)
        } catch (_: NotFoundException) {
            // Nothing in the picture is a normal answer, not a failure.
            emptyArray()
        }
        return found
            .filter { !it.text.isNullOrEmpty() }
            .map { mapOf("value" to it.text, "format" to it.barcodeFormat.name) }
    }

    /**
     * Loads [file] no larger than [MAX_DECODE_SIDE] on its longest side, so
     * a 50-megapixel photo is not decoded at full size just to find a code.
     */
    private fun loadScaled(file: File): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        if (longest <= 0) return null

        var sample = 1
        while (longest / (sample * 2) >= MAX_DECODE_SIDE) sample *= 2
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeFile(file.path, options)
    }

    private fun rgbSource(bitmap: Bitmap): LuminanceSource {
        val pixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        return RGBLuminanceSource(bitmap.width, bitmap.height, pixels)
    }

    private fun reply(
        result: MethodChannel.Result,
        codes: List<Map<String, String>>? = null,
        error: String? = null
    ) {
        mainHandler.post {
            if (error != null) {
                result.error(error, "The picture could not be scanned", null)
            } else {
                result.success(codes ?: emptyList<Map<String, String>>())
            }
        }
    }

    private companion object {
        const val CHANNEL_NAME = "in.sreerajp.imgvidgal/barcode"

        const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        const val ERROR_UNREADABLE = "unreadable"
        const val ERROR_TOO_LARGE = "too_large"
        const val ERROR_DECODE_FAILED = "decode_failed"

        /** Largest still picture opened at all. */
        const val MAX_FILE_BYTES = 64L * 1024 * 1024

        /** Longest side a still picture is decoded at. */
        const val MAX_DECODE_SIDE = 2000

        /** Largest camera frame side accepted. */
        const val MAX_FRAME_SIDE = 4096

        val QR_ONLY: List<BarcodeFormat> = listOf(BarcodeFormat.QR_CODE)

        val ALL_FORMATS: List<BarcodeFormat> = listOf(
            BarcodeFormat.QR_CODE,
            BarcodeFormat.DATA_MATRIX,
            BarcodeFormat.AZTEC,
            BarcodeFormat.PDF_417,
            BarcodeFormat.EAN_13,
            BarcodeFormat.EAN_8,
            BarcodeFormat.UPC_A,
            BarcodeFormat.UPC_E,
            BarcodeFormat.CODE_128,
            BarcodeFormat.CODE_39,
            BarcodeFormat.CODE_93,
            BarcodeFormat.CODABAR,
            BarcodeFormat.ITF
        )
    }
}
