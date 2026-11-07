package `in`.sreerajp.imgvidgal.media

import android.Manifest
import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.util.Size
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * Reads images and videos from the Android MediaStore for the Flutter layer.
 *
 * Only granular media permissions are used. Every call is wrapped so that a
 * missing file, a revoked permission, or a corrupt image is reported as a
 * typed error or a null result instead of crashing the app.
 */
class MediaStoreChannelHandler(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {

    companion object {
        const val CHANNEL_NAME = "in.sreerajp.imgvidgal/mediastore"
        private const val PERMISSION_REQUEST_CODE = 4711
        private const val DELETE_REQUEST_CODE = 4712
        private const val WRITE_REQUEST_CODE = 4713
        private const val SECURE_DELETE_REQUEST_CODE = 4714
        private const val LEGACY_WRITE_PERMISSION_CODE = 4715

        private const val OUTCOME_OVERWRITTEN = "overwritten"
        private const val OUTCOME_DELETED = "deleted"
        private const val OUTCOME_FAILED = "failed"

        private const val STATUS_GRANTED = "granted"
        private const val STATUS_PARTIAL = "partial"
        private const val STATUS_DENIED = "denied"
        private const val STATUS_PERMANENTLY_DENIED = "permanentlyDenied"

        private const val PREFS_NAME = "gallery_permissions"
        private const val KEY_REQUESTED = "media_permissions_requested"

        private const val ERROR_QUERY_FAILED = "query_failed"
        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"

        private const val JPEG_QUALITY = 85
        private const val DEFAULT_MAX_BYTES = 24 * 1024 * 1024
    }

    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingDeleteResult: MethodChannel.Result? = null
    private var pendingSecureDelete: SecureDeleteJob? = null
    private var pendingLegacyWrite: ((Boolean) -> Unit)? = null

    init {
        channel.setMethodCallHandler(this)
    }

    /** Detaches the channel; called when the activity goes away. */
    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingPermissionResult = null
        pendingDeleteResult = null
        pendingSecureDelete = null
        pendingLegacyWrite = null
        worker.shutdown()
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == DELETE_REQUEST_CODE) {
            val res = pendingDeleteResult
            pendingDeleteResult = null
            if (res != null) {
                mainHandler.post {
                    res.success(resultCode == Activity.RESULT_OK)
                }
            }
            return true
        }
        if (requestCode == WRITE_REQUEST_CODE) {
            val job = pendingSecureDelete ?: return true
            val granted = resultCode == Activity.RESULT_OK
            if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
                if (granted) {
                    worker.execute { continueOnQ(job) }
                } else {
                    // Cancelling one prompt stops the rest; asking again for
                    // every remaining file would only nag.
                    finishSecureDelete(job)
                }
            } else if (granted) {
                worker.execute { overwriteAndDelete(job) }
            } else {
                // No write access means no overwrite. Deleting anyway would
                // quietly break the promise the user switched on.
                finishSecureDelete(job)
            }
            return true
        }
        if (requestCode == SECURE_DELETE_REQUEST_CODE) {
            val job = pendingSecureDelete ?: return true
            if (resultCode == Activity.RESULT_OK) {
                for (target in job.leftovers) {
                    target.outcome =
                        if (target.overwritten) OUTCOME_OVERWRITTEN else OUTCOME_DELETED
                }
            }
            finishSecureDelete(job)
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermissions" -> result.success(currentPermissionStatus())
            "requestPermissions" -> requestPermissions(result)
            "getMediaCount" -> runInBackground(result) { getMediaCount() }
            "queryMedia" -> handleQueryMedia(call, result)
            "loadThumbnail" -> handleLoadThumbnail(call, result)
            "readBytes" -> handleReadBytes(call, result)
            "publishFile" -> handlePublishFile(call, result)
            "deleteMedia" -> handleDeleteMedia(call, result)
            "secureDeleteMedia" -> handleSecureDeleteMedia(call, result)
            "openAppSettings" -> {
                openAppSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ----------------------------------------------------------------- permissions

    private fun requiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            )
        } else {
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
    }

    private fun isGranted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(activity, permission) ==
            PackageManager.PERMISSION_GRANTED

    private fun currentPermissionStatus(): String {
        if (requiredPermissions().all { isGranted(it) }) {
            return STATUS_GRANTED
        }

        // Android 14+ can grant access to a user-selected subset only.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            isGranted(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)
        ) {
            return STATUS_PARTIAL
        }

        // On Android, shouldShowRequestPermissionRationale returns false before
        // the user has ever been prompted for the permission. We only report
        // permanently denied if permission was already requested at least once.
        val prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hasRequested = prefs.getBoolean(KEY_REQUESTED, false)
        if (!hasRequested) {
            return STATUS_DENIED
        }

        val permanentlyDenied = requiredPermissions().any { permission ->
            !isGranted(permission) &&
                !ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
        }
        return if (permanentlyDenied) STATUS_PERMANENTLY_DENIED else STATUS_DENIED
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val status = currentPermissionStatus()
        if (status == STATUS_GRANTED) {
            result.success(status)
            return
        }
        if (pendingPermissionResult != null) {
            result.success(STATUS_DENIED)
            return
        }

        // Record that permissions have now been requested.
        activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_REQUESTED, true)
            .apply()

        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            requiredPermissions() + Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
        } else if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            // Android 9 and older need this to delete or overwrite a file the
            // app did not create. Same permission group as read, so the user
            // sees one prompt, not two.
            requiredPermissions() + Manifest.permission.WRITE_EXTERNAL_STORAGE
        } else {
            requiredPermissions()
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(activity, permissions, PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == LEGACY_WRITE_PERMISSION_CODE) {
            val callback = pendingLegacyWrite ?: return true
            pendingLegacyWrite = null
            callback(isGranted(Manifest.permission.WRITE_EXTERNAL_STORAGE))
            return true
        }
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        result.success(currentPermissionStatus())
        return true
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", activity.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
        } catch (e: Exception) {
            // Opening settings is a convenience; failure must not crash the app.
        }
    }

    // ---------------------------------------------------------------------- query

    private fun handleQueryMedia(call: MethodCall, result: MethodChannel.Result) {
        val offset = (call.argument<Int>("offset") ?: 0).coerceAtLeast(0)
        val limit = (call.argument<Int>("limit") ?: 0).coerceAtLeast(0)
        if (limit <= 0) {
            result.error(ERROR_INVALID_ARGUMENTS, "limit must be positive", null)
            return
        }
        val sinceMs = call.argument<Number>("sinceDateModified")?.toLong()

        runInBackground(result) { queryMedia(offset, limit, sinceMs) }
    }

    private fun queryMedia(
        offset: Int,
        limit: Int,
        sinceDateModifiedMs: Long?
    ): List<Map<String, Any?>> {
        val (selection, selectionArgs) =
            MediaStoreQueryBuilder.selection(sinceDateModifiedMs?.let { it / 1000 })
        val rows = mutableListOf<Map<String, Any?>>()

        openCursor(selection, selectionArgs, offset, limit)?.use { cursor ->
            if (!supportsQueryArgs() && !cursor.moveToPosition(offset)) {
                return rows
            }
            if (supportsQueryArgs() && !cursor.moveToFirst()) {
                return rows
            }

            var taken = 0
            do {
                if (taken >= limit) break
                readRow(cursor)?.let {
                    rows.add(it)
                    taken++
                }
            } while (cursor.moveToNext())
        }
        return rows
    }

    private fun openCursor(
        selection: String,
        selectionArgs: Array<String>,
        offset: Int,
        limit: Int
    ): Cursor? {
        val uri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = MediaStoreQueryBuilder.projection()
        val sortOrder = MediaStoreQueryBuilder.sortOrder()

        return if (supportsQueryArgs()) {
            val args = Bundle().apply {
                putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
                putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, selectionArgs)
                putString(ContentResolver.QUERY_ARG_SQL_SORT_ORDER, sortOrder)
                putInt(ContentResolver.QUERY_ARG_LIMIT, limit)
                putInt(ContentResolver.QUERY_ARG_OFFSET, offset)
            }
            resolver().query(uri, projection, args, null)
        } else {
            // API 24-25 has no query-argument bundle; page by cursor position.
            resolver().query(uri, projection, selection, selectionArgs, sortOrder)
        }
    }

    private fun supportsQueryArgs(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O

    private fun readRow(cursor: Cursor): Map<String, Any?>? {
        return try {
            val id = cursor.getLong(
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            )
            val mediaType = cursor.getIntOrNull(MediaStore.Files.FileColumns.MEDIA_TYPE)
            val isVideo = mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
            val contentUri = ContentUris.withAppendedId(
                if (isVideo) {
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                } else {
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                },
                id
            )

            mapOf(
                "id" to id.toString(),
                "uri" to contentUri.toString(),
                "path" to (cursor.getStringOrNull(MediaStore.Files.FileColumns.DATA) ?: ""),
                "displayName" to (
                    cursor.getStringOrNull(MediaStore.Files.FileColumns.DISPLAY_NAME) ?: ""
                    ),
                "mimeType" to (
                    cursor.getStringOrNull(MediaStore.Files.FileColumns.MIME_TYPE) ?: ""
                    ),
                "size" to (cursor.getLongOrNull(MediaStore.Files.FileColumns.SIZE) ?: 0L),
                // MediaStore stores these two in seconds.
                "dateAdded" to secondsToMillis(
                    cursor.getLongOrNull(MediaStore.Files.FileColumns.DATE_ADDED)
                ),
                "dateModified" to secondsToMillis(
                    cursor.getLongOrNull(MediaStore.Files.FileColumns.DATE_MODIFIED)
                ),
                // DATE_TAKEN is already in milliseconds.
                "dateTaken" to cursor.getLongOrNull(MediaStore.Files.FileColumns.DATE_TAKEN),
                "duration" to cursor.getLongOrNull(MediaStore.Files.FileColumns.DURATION),
                "width" to cursor.getIntOrNull(MediaStore.Files.FileColumns.WIDTH),
                "height" to cursor.getIntOrNull(MediaStore.Files.FileColumns.HEIGHT),
                "orientation" to (
                    cursor.getIntOrNull(MediaStoreQueryBuilder.COLUMN_ORIENTATION) ?: 0
                    )
            )
        } catch (e: Exception) {
            // Skip this single unreadable row.
            null
        }
    }

    private fun getMediaCount(): Int {
        val (selection, selectionArgs) = MediaStoreQueryBuilder.selection(null)
        val uri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        resolver().query(
            uri,
            arrayOf(MediaStore.Files.FileColumns._ID),
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            return cursor.count
        }
        return 0
    }

    // ----------------------------------------------------------------- thumbnails

    private fun handleLoadThumbnail(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        val width = call.argument<Int>("width") ?: 256
        val height = call.argument<Int>("height") ?: 256
        if (uriString.isNullOrEmpty()) {
            result.error(ERROR_INVALID_ARGUMENTS, "uri is required", null)
            return
        }

        worker.execute {
            val bytes = try {
                val uri = Uri.parse(uriString)
                if (IncomingUriRules.isAllowed(activity, uri)) {
                    loadThumbnail(uri, width, height)
                } else {
                    null
                }
            } catch (e: Throwable) {
                null
            }
            // A missing thumbnail is a normal outcome, so null is a success value.
            mainHandler.post { result.success(bytes) }
        }
    }

    private fun loadThumbnail(uri: Uri, width: Int, height: Int): ByteArray? {
        val bitmap: Bitmap? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                resolver().loadThumbnail(uri, Size(width, height), null)
            } catch (e: Exception) {
                null
            }
        } else {
            legacyThumbnail(uri, width, height)
        }

        if (bitmap == null) return null
        return try {
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, stream)
                stream.toByteArray()
            }
        } catch (e: Exception) {
            null
        } finally {
            bitmap.recycle()
        }
    }

    @Suppress("DEPRECATION")
    private fun legacyThumbnail(uri: Uri, width: Int, height: Int): Bitmap? {
        return try {
            val id = ContentUris.parseId(uri)
            val isVideo = uri.toString()
                .startsWith(MediaStore.Video.Media.EXTERNAL_CONTENT_URI.toString())
            if (isVideo) {
                MediaStore.Video.Thumbnails.getThumbnail(
                    resolver(),
                    id,
                    MediaStore.Video.Thumbnails.MINI_KIND,
                    null
                )
            } else {
                MediaStore.Images.Thumbnails.getThumbnail(
                    resolver(),
                    id,
                    MediaStore.Images.Thumbnails.MINI_KIND,
                    null
                )
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun handleReadBytes(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        val maxBytes = call.argument<Int>("maxBytes") ?: DEFAULT_MAX_BYTES
        if (uriString.isNullOrEmpty()) {
            result.error(ERROR_INVALID_ARGUMENTS, "uri is required", null)
            return
        }

        worker.execute {
            val bytes = try {
                val uri = Uri.parse(uriString)
                if (IncomingUriRules.isAllowed(activity, uri)) {
                    readBytes(uri, maxBytes)
                } else {
                    null
                }
            } catch (e: Throwable) {
                null
            }
            mainHandler.post { result.success(bytes) }
        }
    }

    private fun readBytes(uri: Uri, maxBytes: Int): ByteArray? {
        return try {
            resolver().openInputStream(uri)?.use { input ->
                val buffer = ByteArrayOutputStream()
                val chunk = ByteArray(64 * 1024)
                var total = 0
                while (true) {
                    val read = input.read(chunk)
                    if (read <= 0) break
                    total += read
                    // Refuse oversized originals rather than risk an OOM.
                    if (total > maxBytes) return null
                    buffer.write(chunk, 0, read)
                }
                buffer.toByteArray()
            }
        } catch (e: Exception) {
            null
        }
    }

    // --------------------------------------------------------------------- helpers

    private fun resolver(): ContentResolver = activity.contentResolver

    private fun <T> runInBackground(
        result: MethodChannel.Result,
        block: () -> T
    ) {
        worker.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: SecurityException) {
                mainHandler.post {
                    result.error(
                        "permission_denied",
                        "Media permission is not granted",
                        null
                    )
                }
            } catch (e: Throwable) {
                mainHandler.post {
                    result.error(ERROR_QUERY_FAILED, e.message, null)
                }
            }
        }
    }

    /**
     * Publishes a received file into the shared gallery.
     *
     * This is how a photo that arrived over the local transfer becomes a
     * photo the user can actually see. It writes through MediaStore rather
     * than to a path, which is what keeps hard rule 3 intact: the app gets to
     * add one file to the user's pictures without ever holding a permission
     * over the rest of their storage.
     *
     * On Android 10 and up the file goes to `Pictures/<relativeDir>` with
     * IS_PENDING set until the bytes are all written, so nothing else on the
     * device sees a half-copied photo. Below 10 there is no RELATIVE_PATH and
     * no way to write to shared storage without the broad legacy permission,
     * so the file stays in the app's own external directory and the returned
     * path says where it went. That is the honest trade: a slightly less
     * convenient place, rather than asking for a key to everything.
     *
     * Nothing is ever overwritten. MediaStore gives the file a new name if
     * one is taken, and the fallback path checks before it writes.
     */
    private fun handlePublishFile(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val displayName = call.argument<String>("displayName")
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
        val relativeDir = call.argument<String>("relativeDir") ?: "Gallery Transfers"
        val isVideo = call.argument<Boolean>("isVideo") ?: false

        if (sourcePath.isNullOrEmpty() || displayName.isNullOrEmpty()) {
            result.error(
                ERROR_INVALID_ARGUMENTS,
                "A source path and a display name are required",
                null
            )
            return
        }

        worker.execute {
            try {
                val source = java.io.File(sourcePath)
                if (!source.isFile) {
                    mainHandler.post {
                        result.error(ERROR_QUERY_FAILED, "The staged file is gone", null)
                    }
                    return@execute
                }

                val published = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    publishThroughMediaStore(
                        source,
                        displayName,
                        mimeType,
                        relativeDir,
                        isVideo
                    )
                } else {
                    publishToAppDirectory(source, displayName, relativeDir)
                }

                mainHandler.post { result.success(published) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error(ERROR_QUERY_FAILED, e.javaClass.simpleName, null)
                }
            }
        }
    }

    private fun publishThroughMediaStore(
        source: java.io.File,
        displayName: String,
        mimeType: String,
        relativeDir: String,
        isVideo: Boolean
    ): Map<String, Any?> {
        val collection = if (isVideo) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
        val base = if (isVideo) {
            android.os.Environment.DIRECTORY_MOVIES
        } else {
            android.os.Environment.DIRECTORY_PICTURES
        }

        val values = android.content.ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, "$base/$relativeDir")
            // Hidden from every other app until the bytes are all there, so
            // nothing ever sees a half-copied photo.
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val resolver = activity.contentResolver
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore refused the insert")

        try {
            resolver.openOutputStream(uri, "w").use { output ->
                if (output == null) {
                    throw IllegalStateException("Could not open the new file")
                }
                source.inputStream().use { input -> input.copyTo(output, 64 * 1024) }
            }
        } catch (error: Exception) {
            // Never leave a pending row nothing will ever finish writing.
            resolver.delete(uri, null, null)
            throw error
        }

        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)

        return mapOf(
            "uri" to uri.toString(),
            "path" to resolvePath(uri),
            "usedMediaStore" to true
        )
    }

    private fun publishToAppDirectory(
        source: java.io.File,
        displayName: String,
        relativeDir: String
    ): Map<String, Any?> {
        val directory = java.io.File(
            activity.getExternalFilesDir(android.os.Environment.DIRECTORY_PICTURES),
            relativeDir
        )
        directory.mkdirs()

        // Never overwrite. A clash gets a numbered name, the same rule the
        // rest of the app follows for a saved copy.
        val dot = displayName.lastIndexOf('.')
        val stem = if (dot > 0) displayName.substring(0, dot) else displayName
        val extension = if (dot > 0) displayName.substring(dot) else ""

        var target = java.io.File(directory, displayName)
        var version = 1
        while (target.exists() && version < 1000) {
            target = java.io.File(directory, "$stem($version)$extension")
            version++
        }

        source.inputStream().use { input ->
            target.outputStream().use { output -> input.copyTo(output, 64 * 1024) }
        }

        return mapOf(
            "uri" to Uri.fromFile(target).toString(),
            "path" to target.absolutePath,
            "usedMediaStore" to false
        )
    }

    /** Reads back the on-disk path MediaStore gave a newly written file. */
    private fun resolvePath(uri: Uri): String? {
        return try {
            activity.contentResolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns.DATA),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getStringOrNull(MediaStore.MediaColumns.DATA)
                } else {
                    null
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun secondsToMillis(seconds: Long?): Long =
        if (seconds == null || seconds <= 0L) 0L else seconds * 1000L

    private fun Cursor.getStringOrNull(column: String): String? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getString(index)
    }

    private fun Cursor.getLongOrNull(column: String): Long? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getLong(index)
    }

    private fun Cursor.getIntOrNull(column: String): Int? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getInt(index)
    }

    private fun handleDeleteMedia(call: MethodCall, result: MethodChannel.Result) {
        val uris = call.argument<List<String>>("uris") ?: emptyList()
        val paths = call.argument<List<String>>("paths") ?: emptyList()

        if (uris.isEmpty() && paths.isEmpty()) {
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val contentUris = uris.filter { it.isNotEmpty() }.map { Uri.parse(it) }
            if (contentUris.isNotEmpty()) {
                try {
                    val pendingIntent = MediaStore.createDeleteRequest(activity.contentResolver, contentUris)
                    pendingDeleteResult = result
                    activity.startIntentSenderForResult(
                        pendingIntent.intentSender,
                        DELETE_REQUEST_CODE,
                        null,
                        0,
                        0,
                        0
                    )
                    return
                } catch (_: Exception) {
                    // Fall back to direct delete
                }
            }
            worker.execute {
                var success = true
                for (u in contentUris) {
                    try {
                        val deleted = activity.contentResolver.delete(u, null, null)
                        if (deleted <= 0) success = false
                    } catch (_: Exception) {
                        success = false
                    }
                }
                for (p in paths) {
                    try {
                        val f = java.io.File(p)
                        if (f.exists()) f.delete()
                    } catch (_: Exception) {}
                }
                mainHandler.post { result.success(success) }
            }
        } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
            worker.execute {
                val contentUris = uris.filter { it.isNotEmpty() }.map { Uri.parse(it) }
                var secException: RecoverableSecurityException? = null
                for (u in contentUris) {
                    try {
                        activity.contentResolver.delete(u, null, null)
                    } catch (sec: RecoverableSecurityException) {
                        if (secException == null) secException = sec
                    } catch (_: Exception) {}
                }
                for (p in paths) {
                    try {
                        val f = java.io.File(p)
                        if (f.exists()) f.delete()
                    } catch (_: Exception) {}
                }
                if (secException != null) {
                    pendingDeleteResult = result
                    mainHandler.post {
                        try {
                            activity.startIntentSenderForResult(
                                secException.userAction.actionIntent.intentSender,
                                DELETE_REQUEST_CODE,
                                null,
                                0,
                                0,
                                0
                            )
                        } catch (_: Exception) {
                            pendingDeleteResult = null
                            result.success(false)
                        }
                    }
                } else {
                    mainHandler.post { result.success(true) }
                }
            }
        } else {
            ensureLegacyWrite { granted ->
                if (!granted) {
                    result.success(false)
                    return@ensureLegacyWrite
                }
                worker.execute {
                    for (u in uris) {
                        try {
                            activity.contentResolver.delete(Uri.parse(u), null, null)
                        } catch (_: Exception) {}
                    }
                    for (p in paths) {
                        try {
                            val f = java.io.File(p)
                            if (f.exists()) f.delete()
                        } catch (_: Exception) {}
                    }
                    // Report what really happened. This used to say true
                    // whatever the outcome, so a refused delete looked done.
                    val allGone = paths.none { p ->
                        try {
                            java.io.File(p).exists()
                        } catch (_: Exception) {
                            false
                        }
                    }
                    mainHandler.post { result.success(allGone) }
                }
            }
        }
    }

    /**
     * Makes sure Android 9 and older let the app write to shared storage.
     *
     * Users who granted read access before write was declared still need the
     * write grant. Android gives it without a prompt when read is already
     * held, because both are in the same permission group.
     */
    private fun ensureLegacyWrite(then: (Boolean) -> Unit) {
        val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        if (isGranted(permission)) {
            then(true)
            return
        }
        if (pendingLegacyWrite != null) {
            then(false)
            return
        }
        pendingLegacyWrite = then
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(permission),
            LEGACY_WRITE_PERMISSION_CODE
        )
    }

    // -------------------------------------------------------------- secure delete

    /** One file the user asked to delete securely, and what happened to it. */
    private class SecureTarget(val uri: Uri?, val path: String) {
        var outcome: String = OUTCOME_FAILED
        var overwritten: Boolean = false
    }

    /** A secure delete in progress, kept while Android shows its prompts. */
    private class SecureDeleteJob(
        val targets: List<SecureTarget>,
        val passes: Int,
        val result: MethodChannel.Result
    ) {
        /** Files written over but not yet deleted (Android 11+). */
        var leftovers: List<SecureTarget> = emptyList()

        /** Android 10: the file being worked on, and whether we asked for it. */
        var index = 0
        var askedForCurrent = false
    }

    /**
     * Writes over each file, then deletes it. Returns one outcome per item,
     * in order: "overwritten", "deleted" (gone, but not written over) or
     * "failed" (still there).
     *
     * Android 11+: one "allow modify" prompt for the whole batch, then a
     * delete prompt only for files Android would not let us delete.
     * Android 10: Android asks once per file; it has no batch prompt.
     * Android 9 and older: needs WRITE_EXTERNAL_STORAGE (declared up to 28).
     */
    private fun handleSecureDeleteMedia(call: MethodCall, result: MethodChannel.Result) {
        val items = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
        val passes = (call.argument<Int>("passes") ?: 2)
            .coerceIn(SecureOverwrite.MIN_PASSES, SecureOverwrite.MAX_PASSES)

        if (items.isEmpty()) {
            result.success(emptyList<String>())
            return
        }
        if (pendingSecureDelete != null || pendingDeleteResult != null) {
            result.error("busy", "A delete is already running", null)
            return
        }

        val targets = items.map { item ->
            val uri = (item["uri"] as? String)
                ?.takeIf { it.isNotEmpty() }
                ?.let { Uri.parse(it) }
            SecureTarget(uri, (item["path"] as? String) ?: "")
        }
        val job = SecureDeleteJob(targets, passes, result)
        pendingSecureDelete = job

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> startWriteRequest(job)
            Build.VERSION.SDK_INT == Build.VERSION_CODES.Q ->
                worker.execute { continueOnQ(job) }
            else -> ensureLegacyWrite { granted ->
                if (granted) {
                    worker.execute { overwriteAndDelete(job) }
                } else {
                    finishSecureDelete(job)
                }
            }
        }
    }

    /** Android 11+: one prompt asking to modify every selected file. */
    private fun startWriteRequest(job: SecureDeleteJob) {
        val uris = job.targets.mapNotNull { it.uri }
        if (uris.isEmpty()) {
            worker.execute { overwriteAndDelete(job) }
            return
        }
        try {
            val pendingIntent = MediaStore.createWriteRequest(activity.contentResolver, uris)
            activity.startIntentSenderForResult(
                pendingIntent.intentSender,
                WRITE_REQUEST_CODE,
                null,
                0,
                0,
                0
            )
        } catch (_: Exception) {
            finishSecureDelete(job)
        }
    }

    /** Runs on the worker once the app is allowed to write. */
    private fun overwriteAndDelete(job: SecureDeleteJob) {
        val leftovers = mutableListOf<SecureTarget>()
        for (target in job.targets) {
            target.overwritten = try {
                overwriteTarget(target, job.passes)
            } catch (_: Exception) {
                false
            }
            if (deleteTarget(target)) {
                target.outcome =
                    if (target.overwritten) OUTCOME_OVERWRITTEN else OUTCOME_DELETED
            } else if (target.uri != null) {
                leftovers.add(target)
            }
        }

        if (leftovers.isEmpty() || Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            finishSecureDelete(job)
            return
        }

        // A write grant usually lets the delete through. When it does not,
        // ask once more, for those files only.
        job.leftovers = leftovers
        mainHandler.post {
            try {
                val pendingIntent = MediaStore.createDeleteRequest(
                    activity.contentResolver,
                    leftovers.mapNotNull { it.uri }
                )
                activity.startIntentSenderForResult(
                    pendingIntent.intentSender,
                    SECURE_DELETE_REQUEST_CODE,
                    null,
                    0,
                    0,
                    0
                )
            } catch (_: Exception) {
                finishSecureDelete(job)
            }
        }
    }

    /** Android 10: one file at a time, asking whenever Android requires it. */
    private fun continueOnQ(job: SecureDeleteJob) {
        while (job.index < job.targets.size) {
            val target = job.targets[job.index]
            try {
                target.overwritten = overwriteTarget(target, job.passes)
            } catch (sec: RecoverableSecurityException) {
                if (!job.askedForCurrent) {
                    job.askedForCurrent = true
                    mainHandler.post {
                        try {
                            activity.startIntentSenderForResult(
                                sec.userAction.actionIntent.intentSender,
                                WRITE_REQUEST_CODE,
                                null,
                                0,
                                0,
                                0
                            )
                        } catch (_: Exception) {
                            finishSecureDelete(job)
                        }
                    }
                    return
                }
                // Asked already and still refused: leave this one alone.
                job.index++
                job.askedForCurrent = false
                continue
            } catch (_: Exception) {
                target.overwritten = false
            }

            if (deleteTarget(target)) {
                target.outcome =
                    if (target.overwritten) OUTCOME_OVERWRITTEN else OUTCOME_DELETED
            }
            job.index++
            job.askedForCurrent = false
        }
        finishSecureDelete(job)
    }

    /**
     * Writes over one file. Returns false when it could not be written.
     *
     * Rethrows [RecoverableSecurityException] so Android 10 can ask the user.
     */
    private fun overwriteTarget(target: SecureTarget, passes: Int): Boolean {
        val uri = target.uri
        if (uri != null) {
            try {
                val pfd = activity.contentResolver.openFileDescriptor(uri, "rw")
                    ?: return false
                pfd.use {
                    val length = it.statSize
                    if (length < 0) return false
                    SecureOverwrite.overwriteDescriptor(it.fileDescriptor, length, passes)
                }
                return true
            } catch (sec: RecoverableSecurityException) {
                throw sec
            } catch (_: Exception) {
                // Fall through to the path, which works on Android 9 and older.
            }
        }
        if (target.path.isEmpty()) return false
        return try {
            val file = java.io.File(target.path)
            if (!file.isFile) return false
            SecureOverwrite.overwriteFile(file, passes)
            true
        } catch (_: Exception) {
            false
        }
    }

    /** Deletes one file. Returns true when it is gone afterwards. */
    private fun deleteTarget(target: SecureTarget): Boolean {
        val uri = target.uri
        if (uri != null) {
            try {
                if (activity.contentResolver.delete(uri, null, null) > 0) return true
            } catch (_: Exception) {
                // Try the path below; if that fails too, the caller asks.
            }
        }
        if (target.path.isEmpty()) return false
        return try {
            val file = java.io.File(target.path)
            val gone = !file.exists() || file.delete()
            if (!gone) return false
            // The file is gone; make sure no MediaStore row still claims it.
            uri == null || !rowExists(uri)
        } catch (_: Exception) {
            false
        }
    }

    private fun rowExists(uri: Uri): Boolean {
        return try {
            activity.contentResolver
                .query(uri, arrayOf(MediaStore.MediaColumns._ID), null, null, null)
                ?.use { it.moveToFirst() } ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun finishSecureDelete(job: SecureDeleteJob) {
        mainHandler.post {
            if (pendingSecureDelete === job) pendingSecureDelete = null
            job.result.success(job.targets.map { it.outcome })
        }
    }
}
