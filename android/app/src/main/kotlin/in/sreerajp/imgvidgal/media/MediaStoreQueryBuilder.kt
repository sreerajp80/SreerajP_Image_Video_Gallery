package `in`.sreerajp.imgvidgal.media

import android.os.Build
import android.provider.MediaStore

/**
 * Builds the projection, selection and sort order used to page over the
 * MediaStore. Kept separate from the channel handler so the query shape is easy
 * to read and change.
 */
object MediaStoreQueryBuilder {

    const val COLUMN_ORIENTATION = MediaStore.Files.FileColumns.ORIENTATION

    /** Columns read for every media row. */
    fun projection(): Array<String> {
        val columns = mutableListOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DATA,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.DATE_ADDED,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.WIDTH,
            MediaStore.Files.FileColumns.HEIGHT
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            columns.add(MediaStore.Files.FileColumns.DURATION)
            columns.add(MediaStore.Files.FileColumns.ORIENTATION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            columns.add(MediaStore.Files.FileColumns.DATE_TAKEN)
        }
        return columns.toTypedArray()
    }

    /**
     * Restricts results to images and videos, optionally only those modified at
     * or after [sinceDateModifiedSeconds] (MediaStore stores seconds).
     */
    fun selection(sinceDateModifiedSeconds: Long?): Pair<String, Array<String>> {
        val base = "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (?, ?)"
        val baseArgs = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString()
        )

        if (sinceDateModifiedSeconds == null) {
            return base to baseArgs
        }

        val withDate = "$base AND ${MediaStore.Files.FileColumns.DATE_MODIFIED} >= ?"
        return withDate to (baseArgs + sinceDateModifiedSeconds.toString())
    }

    /** Newest modification first, so recent media is indexed early. */
    fun sortOrder(): String =
        "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC, " +
            "${MediaStore.Files.FileColumns._ID} DESC"
}
