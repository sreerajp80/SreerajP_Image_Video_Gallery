package `in`.sreerajp.imgvidgal.media

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Adds new files to the shared gallery through MediaStore.
 *
 * Shared by the MediaStore channel (`publishFile`) and the vault (restore),
 * so both write the same way: a pending row that no other app can see until
 * the bytes are complete, past Android 10's "ghost" rows, and never over an
 * existing file (MediaStore renames on a clash).
 *
 * Call from a worker thread: [rescanMissing] blocks.
 */
class MediaStoreWriter(private val context: Context) {

    private val resolver: ContentResolver get() = context.contentResolver

    /**
     * Inserts a new MediaStore row, getting past a ghost entry on Android 10.
     *
     * A ghost is a row whose file was deleted behind MediaStore's back, for
     * example by a file manager. Android 10 picks the new file's path by
     * looking only at the disk, so it picks the ghost's path, and then its
     * database refuses the duplicate path. Asking the scanner to look at that
     * missing path drops the ghost; if the insert is still refused, a
     * numbered name is tried, as Android itself does for a real clash.
     */
    fun insertWithGhostRecovery(
        collection: Uri,
        values: ContentValues,
        relativePath: String,
        displayName: String
    ): Uri {
        tryInsert(collection, values)?.let { return it }
        if (Build.VERSION.SDK_INT != Build.VERSION_CODES.Q) {
            throw IllegalStateException("MediaStore refused the insert")
        }

        @Suppress("DEPRECATION")
        val root = android.os.Environment.getExternalStorageDirectory()
        val target = File(File(root, relativePath), displayName)
        val missing = try {
            !target.exists()
        } catch (_: Exception) {
            false
        }
        if (missing) {
            rescanMissing(listOf(target.absolutePath))
            tryInsert(collection, values)?.let { return it }
        }

        val dot = displayName.lastIndexOf('.')
        val stem = if (dot > 0) displayName.substring(0, dot) else displayName
        val extension = if (dot > 0) displayName.substring(dot) else ""
        for (n in 1..GHOST_RENAME_TRIES) {
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, "$stem ($n)$extension")
            tryInsert(collection, values)?.let { return it }
        }
        throw IllegalStateException("MediaStore refused the insert")
    }

    /**
     * Inserts a pending (hidden) row for a new file in [relativePath], e.g.
     * `DCIM/Camera`. Android 10 (API 29) and later only.
     */
    fun insertPending(
        isVideo: Boolean,
        displayName: String,
        mimeType: String,
        relativePath: String
    ): Uri {
        val collection = if (isVideo) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        return insertWithGhostRecovery(collection, values, relativePath, displayName)
    }

    /** Makes a pending row visible: its bytes are complete. */
    fun finish(uri: Uri) {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.IS_PENDING, 0)
        }
        resolver.update(uri, values, null, null)
    }

    /** Removes a row whose write failed, so no half-file is left behind. */
    fun abort(uri: Uri) {
        try {
            resolver.delete(uri, null, null)
        } catch (_: Exception) {
            // Safe to ignore: a pending row is invisible to other apps, and
            // Android removes pending rows on its own after about a week.
        }
    }

    /**
     * Asks Android's scanner to look at [paths], each a file that is gone.
     *
     * For a missing single file, Android 10's scanner removes that path's
     * row (it never touches a file). Single files only, never a folder: a
     * folder scan matches rows by path prefix, so scanning `Camera` would
     * also drop rows in a sibling `Camera2` that it did not walk.
     *
     * Blocks until the scanner reports back or a timeout passes, so it must
     * run on a worker thread.
     */
    fun rescanMissing(paths: List<String>) {
        if (paths.isEmpty()) return
        val latch = CountDownLatch(paths.size)
        MediaScannerConnection.scanFile(context, paths.toTypedArray(), null) { _, _ ->
            latch.countDown()
        }
        val seconds = (10L + paths.size / 10L).coerceAtMost(120L)
        latch.await(seconds, TimeUnit.SECONDS)
    }

    /** Reads back the on-disk path MediaStore gave a newly written file. */
    fun resolvePath(uri: Uri): String? {
        return try {
            resolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns.DATA),
                null,
                null,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return@use null
                val index = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                if (index < 0 || cursor.isNull(index)) null else cursor.getString(index)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun tryInsert(collection: Uri, values: ContentValues): Uri? = try {
        resolver.insert(collection, values)
    } catch (e: SecurityException) {
        throw e
    } catch (_: Exception) {
        null
    }

    companion object {
        private const val GHOST_RENAME_TRIES = 5

        /**
         * Whether [relativePath] is a folder MediaStore lets this kind of
         * file go into: photos under DCIM or Pictures, videos under DCIM,
         * Movies or Pictures. At most four plain folder levels; no empty
         * part, no `.`/`..`, no hidden name, no character Android refuses.
         *
         * The vault restore checks this again here, after Dart, because the
         * path comes from a stored record.
         */
        fun isAllowedRelativePath(relativePath: String, isVideo: Boolean): Boolean {
            val parts = relativePath.split('/')
            if (parts.isEmpty() || parts.size > 4) return false
            val roots = if (isVideo) setOf("DCIM", "Movies", "Pictures") else setOf("DCIM", "Pictures")
            if (parts.first() !in roots) return false
            for (part in parts) {
                if (part.isEmpty() || part.length > 100) return false
                if (part.startsWith(".")) return false
                if (part.any { it.code < 0x20 || it.code == 0x7F || it in "\\:*?\"<>|" }) {
                    return false
                }
            }
            return true
        }
    }
}
