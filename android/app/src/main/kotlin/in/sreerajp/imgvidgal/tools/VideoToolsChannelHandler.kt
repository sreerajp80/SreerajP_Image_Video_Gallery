package `in`.sreerajp.imgvidgal.tools

import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Clip facts, single frames, and lossless trimming.
 *
 * All three jobs use Android's own media APIs, so the app needs no video
 * processing library and no extra permission:
 *
 *  - `MediaMetadataRetriever` reports the length, size, and rotation of a
 *    clip, and hands back a single frame as a bitmap.
 *  - `MediaExtractor` plus `MediaMuxer` copy the compressed packets of a
 *    chosen range straight into a new file. Nothing is decoded and nothing
 *    is re-encoded, so a trim loses no quality and runs at roughly the speed
 *    of a file copy.
 *
 * Every call runs on a background thread and answers on the main thread. A
 * damaged or unsupported file always comes back as an error result, never as
 * a crash.
 */
class VideoToolsChannelHandler(
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
            "readClipInfo" -> onBackground(result) { readClipInfo(call) }
            "grabFrame" -> onBackground(result) { grabFrame(call) }
            "trim" -> onBackground(result) { trim(call) }
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- info

    private fun readClipInfo(call: MethodCall): Map<String, Any> {
        val path = requirePath(call, "path")

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)

            val duration = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0L
            val width = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                ?.toIntOrNull() ?: 0
            val height = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                ?.toIntOrNull() ?: 0
            val rotation = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                ?.toIntOrNull() ?: 0
            val hasAudio = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO) == "yes"

            return mapOf(
                "durationMs" to duration,
                "width" to width,
                "height" to height,
                "rotationDegrees" to rotation,
                "frameRate" to readFrameRate(path),
                "hasAudio" to hasAudio
            )
        } finally {
            releaseQuietly(retriever)
        }
    }

    /**
     * Frame rate as the video track itself declares it.
     *
     * `MediaMetadataRetriever` only reports a capture frame rate, which most
     * clips leave empty, so the track format is asked instead. A clip that
     * says nothing gives 0, and callers treat that as unknown.
     */
    private fun readFrameRate(path: String): Double {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(path)
            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (!mime.startsWith("video/")) continue
                if (format.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                    return try {
                        format.getInteger(MediaFormat.KEY_FRAME_RATE).toDouble()
                    } catch (_: ClassCastException) {
                        format.getFloat(MediaFormat.KEY_FRAME_RATE).toDouble()
                    }
                }
            }
            return 0.0
        } catch (_: Throwable) {
            return 0.0
        } finally {
            releaseQuietly(extractor)
        }
    }

    // --------------------------------------------------------------- frame

    private fun grabFrame(call: MethodCall): ByteArray {
        val path = requirePath(call, "path")
        val positionMs = max(0L, (call.argument<Number>("positionMs")?.toLong() ?: 0L))
        val maxSide = call.argument<Int>("maxSide") ?: 0

        val retriever = MediaMetadataRetriever()
        var bitmap: Bitmap? = null
        try {
            retriever.setDataSource(path)
            val timeUs = positionMs * 1000L

            bitmap = scaledFrame(retriever, timeUs, maxSide)
                ?: retriever.getFrameAtTime(
                    timeUs,
                    MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                )
                ?: throw ToolsException(
                    ERROR_NO_FRAME,
                    "No frame could be read at that point"
                )

            val scaled = if (maxSide > 0) fitWithin(bitmap, maxSide) else bitmap
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, FRAME_JPEG_QUALITY, stream)
            if (scaled !== bitmap) scaled.recycle()

            val bytes = stream.toByteArray()
            if (bytes.isEmpty()) {
                throw ToolsException(ERROR_NO_FRAME, "The frame came out empty")
            }
            return bytes
        } finally {
            bitmap?.recycle()
            releaseQuietly(retriever)
        }
    }

    /**
     * Asks the device to scale the frame while it decodes it.
     *
     * Available from API 27 and much cheaper than decoding a 4K frame and
     * shrinking it afterwards, which matters when a GIF export pulls a
     * hundred of them. Returns null when the device cannot do it, and the
     * caller then falls back to the plain path.
     */
    private fun scaledFrame(
        retriever: MediaMetadataRetriever,
        timeUs: Long,
        maxSide: Int
    ): Bitmap? {
        if (maxSide <= 0 || Build.VERSION.SDK_INT < Build.VERSION_CODES.O_MR1) return null
        return try {
            retriever.getScaledFrameAtTime(
                timeUs,
                MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                maxSide,
                maxSide
            )
        } catch (_: Throwable) {
            null
        }
    }

    /** Shrinks a bitmap so its longest side is no more than [maxSide]. */
    private fun fitWithin(bitmap: Bitmap, maxSide: Int): Bitmap {
        val longest = max(bitmap.width, bitmap.height)
        if (longest <= maxSide || longest == 0) return bitmap

        val scale = maxSide.toDouble() / longest
        val width = max(1, (bitmap.width * scale).roundToInt())
        val height = max(1, (bitmap.height * scale).roundToInt())
        return Bitmap.createScaledBitmap(bitmap, width, height, true)
    }

    // ---------------------------------------------------------------- trim

    /**
     * Copies the packets between two times into a new container.
     *
     * The extractor is seeked to the last sync frame at or before the start,
     * because a video packet that is not a key frame cannot be decoded on
     * its own. That is why the trimmed clip may begin a fraction earlier
     * than the moment the user picked: it is the price of not re-encoding.
     */
    private fun trim(call: MethodCall): Long {
        val sourcePath = requirePath(call, "sourcePath")
        val targetPath = call.argument<String>("targetPath")
            ?: throw ToolsException(ERROR_INVALID_ARGUMENTS, "targetPath is required")
        val startMs = max(0L, call.argument<Number>("startMs")?.toLong() ?: 0L)
        val endMs = call.argument<Number>("endMs")?.toLong() ?: 0L

        if (endMs <= startMs) {
            throw ToolsException(ERROR_INVALID_ARGUMENTS, "The chosen range is empty")
        }

        val startUs = startMs * 1000L
        val endUs = endMs * 1000L

        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var started = false

        try {
            extractor.setDataSource(sourcePath)

            val trackMap = HashMap<Int, Int>()
            var bufferSize = DEFAULT_BUFFER_BYTES

            muxer = MediaMuxer(targetPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (!mime.startsWith("video/") && !mime.startsWith("audio/")) continue

                extractor.selectTrack(index)
                trackMap[index] = muxer.addTrack(format)

                if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                    bufferSize = max(
                        bufferSize,
                        format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
                    )
                }
            }

            if (trackMap.isEmpty()) {
                throw ToolsException(
                    ERROR_UNSUPPORTED,
                    "This clip has no track that can be copied"
                )
            }

            readRotation(sourcePath)?.let { muxer.setOrientationHint(it) }

            muxer.start()
            started = true

            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            val buffer = ByteBuffer.allocate(bufferSize)
            val info = MediaCodec.BufferInfo()
            var baseTimeUs = -1L
            var written = 0

            while (true) {
                val size = extractor.readSampleData(buffer, 0)
                if (size < 0) break

                val sampleTimeUs = extractor.sampleTime
                if (sampleTimeUs < 0) break
                if (sampleTimeUs > endUs) break

                // Every kept packet is shifted so the new clip starts at
                // zero. The same shift is used for audio and video, so they
                // stay in step with each other.
                if (baseTimeUs < 0) baseTimeUs = sampleTimeUs

                val trackIndex = trackMap[extractor.sampleTrackIndex]
                if (trackIndex != null) {
                    info.offset = 0
                    info.size = size
                    info.presentationTimeUs = max(0L, sampleTimeUs - baseTimeUs)
                    info.flags =
                        if (extractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) {
                            MediaCodec.BUFFER_FLAG_KEY_FRAME
                        } else {
                            0
                        }
                    muxer.writeSampleData(trackIndex, buffer, info)
                    written++
                }

                if (!extractor.advance()) break
            }

            if (written == 0) {
                throw ToolsException(
                    ERROR_NO_FRAME,
                    "Nothing was found in the chosen part of the clip"
                )
            }

            muxer.stop()
            started = false
            muxer.release()
            muxer = null

            return File(targetPath).length()
        } catch (error: Throwable) {
            // A half-written clip is worse than none, so it is removed.
            deleteQuietly(targetPath)
            if (error is ToolsException) throw error
            throw ToolsException(
                ERROR_TRIM_FAILED,
                error.message ?: "The clip could not be trimmed"
            )
        } finally {
            if (muxer != null) {
                if (started) {
                    try {
                        muxer.stop()
                    } catch (_: Throwable) {
                    }
                }
                try {
                    muxer.release()
                } catch (_: Throwable) {
                }
            }
            releaseQuietly(extractor)
        }
    }

    private fun readRotation(path: String): Int? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                ?.toIntOrNull()
        } catch (_: Throwable) {
            null
        } finally {
            releaseQuietly(retriever)
        }
    }

    // --------------------------------------------------------------- plumbing

    /**
     * Runs [work] off the main thread and answers on it.
     *
     * Every failure, including one thrown deep inside a platform decoder,
     * becomes an error result. The app must never crash because of a file it
     * was handed.
     */
    private fun <T> onBackground(result: MethodChannel.Result, work: () -> T) {
        worker.execute {
            try {
                val value = work()
                mainHandler.post { result.success(value) }
            } catch (error: ToolsException) {
                mainHandler.post { result.error(error.code, error.message, null) }
            } catch (error: Throwable) {
                mainHandler.post {
                    result.error(
                        ERROR_UNSUPPORTED,
                        error.message ?: "This clip could not be read",
                        null
                    )
                }
            }
        }
    }

    private fun requirePath(call: MethodCall, name: String): String {
        val path = call.argument<String>(name)
        if (path.isNullOrEmpty()) {
            throw ToolsException(ERROR_INVALID_ARGUMENTS, "$name is required")
        }
        if (!File(path).exists()) {
            throw ToolsException(ERROR_NOT_FOUND, "That file is no longer on the device")
        }
        return path
    }

    private fun releaseQuietly(retriever: MediaMetadataRetriever) {
        try {
            retriever.release()
        } catch (_: Throwable) {
        }
    }

    private fun releaseQuietly(extractor: MediaExtractor) {
        try {
            extractor.release()
        } catch (_: Throwable) {
        }
    }

    private fun deleteQuietly(path: String) {
        try {
            File(path).delete()
        } catch (_: Throwable) {
        }
    }

    /** A failure with a code Dart can tell apart. */
    private class ToolsException(
        val code: String,
        override val message: String
    ) : Exception(message)

    companion object {
        private const val CHANNEL_NAME = "in.sreerajp.imgvidgal/videotools"
        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val ERROR_NOT_FOUND = "not_found"
        private const val ERROR_NO_FRAME = "no_frame"
        private const val ERROR_UNSUPPORTED = "unsupported"
        private const val ERROR_TRIM_FAILED = "trim_failed"
        private const val FRAME_JPEG_QUALITY = 92
        private const val DEFAULT_BUFFER_BYTES = 1024 * 1024
    }
}
