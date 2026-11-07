package `in`.sreerajp.imgvidgal.backup

import android.app.Activity
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Lets the user pick where a backup goes and which one comes back.
 *
 * This is the Storage Access Framework, and choosing it is what keeps hard
 * rule 3 intact. The alternative — asking for a broad storage permission and
 * writing wherever the app liked — would mean holding a key to the user's
 * whole file system in order to save one file they were about to choose the
 * location of anyway.
 *
 * With SAF the app asks for nothing. Android shows its own picker, the user
 * points at a folder or a file, and the app gets back a URI good for that one
 * document. No permission is requested, none is held afterwards, and the app
 * cannot see anything the user did not point at.
 *
 * The read side is deliberately not persisted. A one-shot URI is enough to
 * restore an archive once, and taking a long-lived grant for a file the user
 * only meant to open today would be quietly keeping more access than the job
 * needs.
 */
class DocumentPickerChannelHandler(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL_NAME).also {
        it.setMethodCallHandler(this)
    }

    /**
     * The call waiting on the picker, if any.
     *
     * Only one at a time. A second request while a picker is open is refused
     * rather than queued: two dialogs cannot both be on screen, so a queue
     * would only ever hold a call whose user has already gone.
     */
    private var pending: MethodChannel.Result? = null

    fun dispose() {
        channel.setMethodCallHandler(null)
        // Anything still waiting will never get an answer from a dead
        // activity, so it is told now rather than left hanging forever.
        pending?.error(ERROR_CANCELLED, "The screen closed", null)
        pending = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "createDocument" -> createDocument(call, result)
            "openDocument" -> openDocument(call, result)
            "documentInfo" -> documentInfo(call, result)
            "readPrefix" -> readPrefix(call, result)
            "copyToCache" -> copyToCache(call, result)
            "openFolder" -> openFolder(result)
            "writeToFolder" -> writeToFolder(call, result)
            else -> result.notImplemented()
        }
    }

    /** Asks the user where to save a new file, and under what name. */
    private fun createDocument(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: DEFAULT_MIME

        if (name.isNullOrBlank()) {
            result.error(ERROR_INVALID_ARGUMENTS, "A file name is required", null)
            return
        }
        if (!claim(result)) return

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, name)
        }

        launch(intent, REQUEST_CREATE, result)
    }

    /** Asks the user to point at an existing file. */
    private fun openDocument(call: MethodCall, result: MethodChannel.Result) {
        // The archive has no MIME type Android knows, so the picker is opened
        // wide rather than filtered to a type no file would ever carry. The
        // magic-marker check in Dart is what actually rejects a wrong file,
        // and it gives a better message than an empty picker would.
        val mimeType = call.argument<String>("mimeType") ?: "*/*"

        if (!claim(result)) return

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
        }

        launch(intent, REQUEST_OPEN, result)
    }

    /**
     * Reports a document's name and size without opening it.
     *
     * The restore screen uses it to refuse an absurdly large file before it
     * asks for a password, so nobody types one in for a file that was never
     * going to be read.
     */
    private fun documentInfo(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        if (uri.isNullOrEmpty()) {
            result.error(ERROR_INVALID_ARGUMENTS, "A uri is required", null)
            return
        }

        try {
            activity.contentResolver.query(
                Uri.parse(uri),
                arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                null,
                null,
                null
            ).use { cursor ->
                if (cursor == null || !cursor.moveToFirst()) {
                    result.error(ERROR_UNREADABLE, "The file could not be read", null)
                    return
                }
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                result.success(
                    mapOf(
                        "name" to if (nameIndex >= 0) cursor.getString(nameIndex) else "",
                        "sizeBytes" to
                            if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                                cursor.getLong(sizeIndex)
                            } else {
                                -1L
                            }
                    )
                )
            }
        } catch (error: Exception) {
            result.error(ERROR_UNREADABLE, error.javaClass.simpleName, null)
        }
    }

    /**
     * Reads the first `length` bytes of a document.
     *
     * The archive's header sits in the clear at the front of the file and has
     * to be parsed before anything can be decrypted, because it carries the
     * salt and the iteration count the password is stretched with. A content
     * URI cannot be opened at an offset from Dart, so the prefix is fetched
     * here and parsed by the pure Dart format class that owns the layout.
     *
     * Reads no more than asked and returns fewer bytes for a shorter file,
     * which is how a truncated archive is caught before a password is typed.
     */
    private fun readPrefix(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        val length = call.argument<Int>("length") ?: 0

        if (uri.isNullOrEmpty()) {
            result.error(ERROR_INVALID_ARGUMENTS, "A uri is required", null)
            return
        }
        if (length <= 0 || length > MAX_PREFIX_BYTES) {
            result.error(ERROR_INVALID_ARGUMENTS, "length is out of range", null)
            return
        }

        try {
            activity.contentResolver.openInputStream(Uri.parse(uri)).use { input ->
                if (input == null) {
                    result.error(ERROR_UNREADABLE, "The file could not be opened", null)
                    return
                }

                val buffer = ByteArray(length)
                var filled = 0
                while (filled < length) {
                    val read = input.read(buffer, filled, length - filled)
                    if (read <= 0) break
                    filled += read
                }
                result.success(buffer.copyOf(filled))
            }
        } catch (error: Exception) {
            result.error(ERROR_UNREADABLE, error.javaClass.simpleName, null)
        }
    }

    /**
     * Copies a picked document into app-private cache and returns the path.
     *
     * The PDF image extractor works on bytes and needs the whole file, and a
     * content URI cannot be handed to Dart's `File`. Copying is also what
     * keeps the read grant from having to be persisted: the URI is used once,
     * here, and the copy the app owns is what gets parsed.
     *
     * The copy lands in a cache subfolder the caller is expected to clear when
     * it is finished. It is app-private, so no other app can read it, and the
     * size is capped so a picked file cannot fill the device.
     */
    private fun copyToCache(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        val maxBytes = (call.argument<Int>("maxBytes") ?: DEFAULT_COPY_MAX_BYTES)
            .coerceAtMost(HARD_COPY_MAX_BYTES)

        if (uri.isNullOrEmpty()) {
            result.error(ERROR_INVALID_ARGUMENTS, "A uri is required", null)
            return
        }

        val folder = File(activity.cacheDir, COPY_FOLDER).apply { mkdirs() }
        val target = File(folder, "picked_${System.currentTimeMillis()}.tmp")

        try {
            activity.contentResolver.openInputStream(Uri.parse(uri)).use { input ->
                if (input == null) {
                    result.error(ERROR_UNREADABLE, "The file could not be opened", null)
                    return
                }

                var copied = 0L
                FileOutputStream(target).use { output ->
                    val buffer = ByteArray(COPY_BLOCK_BYTES)
                    while (true) {
                        val read = input.read(buffer)
                        if (read <= 0) break

                        copied += read
                        if (copied > maxBytes) {
                            // Stop as soon as the cap is passed, rather than
                            // after the whole thing is on disk.
                            output.close()
                            target.delete()
                            result.error(
                                ERROR_TOO_LARGE,
                                "The file is larger than the app will open",
                                null
                            )
                            return
                        }

                        output.write(buffer, 0, read)
                    }
                }
            }

            result.success(target.absolutePath)
        } catch (error: Exception) {
            // Never leave half a file behind for something else to read.
            target.delete()
            result.error(ERROR_UNREADABLE, error.javaClass.simpleName, null)
        }
    }

    /**
     * Asks the user to point at a folder.
     *
     * Used when a vault item is restored and the folder it came from is gone.
     * The grant is used once, for the restore that follows, and is not kept:
     * no `takePersistableUriPermission`, the same rule as the read side.
     */
    private fun openFolder(result: MethodChannel.Result) {
        if (!claim(result)) return

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        }

        launch(intent, REQUEST_TREE, result)
    }

    /**
     * Copies a decrypted vault working file into a folder the user picked.
     *
     * A new document is always created. When the name is taken, the provider
     * gives it a new one such as `photo (1).jpg`, so nothing already there is
     * ever overwritten. A copy that fails part way deletes its half-file.
     *
     * The source must be a working file inside the app's own vault folder.
     * Without that check this would be a general "copy any file the app can
     * read into any folder" tool, which no screen needs.
     *
     * The copy runs off the main thread: a video can be gigabytes.
     */
    private fun writeToFolder(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = call.argument<String>("treeUri")
        val displayName = call.argument<String>("displayName")
        val mimeType = call.argument<String>("mimeType") ?: DEFAULT_MIME
        val sourcePath = call.argument<String>("sourcePath")

        if (treeUri.isNullOrEmpty() || sourcePath.isNullOrEmpty() ||
            displayName.isNullOrBlank() || displayName.contains('/') ||
            displayName.contains('\\')
        ) {
            result.error(ERROR_INVALID_ARGUMENTS, "treeUri, displayName and sourcePath are required", null)
            return
        }

        val source = File(sourcePath)
        if (!isVaultWorkingFile(source)) {
            result.error(ERROR_INVALID_ARGUMENTS, "The source is not a vault working file", null)
            return
        }

        Thread {
            val outcome = runCatching { copyIntoTree(Uri.parse(treeUri), displayName, mimeType, source) }
            activity.runOnUiThread {
                outcome.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { error ->
                        result.error(ERROR_WRITE_FAILED, error.javaClass.simpleName, null)
                    }
                )
            }
        }.start()
    }

    private fun copyIntoTree(
        tree: Uri,
        displayName: String,
        mimeType: String,
        source: File
    ): Map<String, String?> {
        val resolver = activity.contentResolver
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree)
        )
        val created = DocumentsContract.createDocument(resolver, parent, mimeType, displayName)
            ?: throw IllegalStateException("The folder refused a new file")

        try {
            resolver.openOutputStream(created, "w").use { output ->
                if (output == null) throw IllegalStateException("The new file could not be opened")
                source.inputStream().use { input ->
                    input.copyTo(output, COPY_BLOCK_BYTES)
                }
            }
        } catch (error: Exception) {
            runCatching { DocumentsContract.deleteDocument(resolver, created) }
            throw error
        }

        val path = primaryStoragePath(created)
        if (path != null) {
            // Newer Android indexes files written this way by itself; older
            // versions need telling, or the photo would not show in galleries.
            MediaScannerConnection.scanFile(activity, arrayOf(path), arrayOf(mimeType), null)
        }
        return mapOf("uri" to created.toString(), "path" to path)
    }

    /** True only for a `.dec` working file directly inside the vault folder. */
    private fun isVaultWorkingFile(file: File): Boolean = runCatching {
        val vault = File(activity.filesDir, VAULT_FOLDER).canonicalFile
        val canonical = file.canonicalFile
        canonical.parentFile == vault &&
            canonical.name.endsWith(VAULT_WORKING_EXTENSION) &&
            canonical.isFile
    }.getOrDefault(false)

    /**
     * The real path of a document on the phone's main storage, or null.
     *
     * Only the built-in storage provider's `primary:` ids can be mapped. For
     * anything else the media index request is skipped, which is harmless.
     */
    private fun primaryStoragePath(document: Uri): String? = runCatching {
        if (document.authority != EXTERNAL_STORAGE_AUTHORITY) return null
        val id = DocumentsContract.getDocumentId(document)
        if (!id.startsWith(PRIMARY_PREFIX)) return null
        @Suppress("DEPRECATION")
        File(Environment.getExternalStorageDirectory(), id.removePrefix(PRIMARY_PREFIX)).absolutePath
    }.getOrNull()

    /**
     * Takes the pending slot, or tells the caller one is already in use.
     *
     * Returns false when it refused, so the caller stops.
     */
    private fun claim(result: MethodChannel.Result): Boolean {
        if (pending != null) {
            result.error(ERROR_BUSY, "A file picker is already open", null)
            return false
        }
        pending = result
        return true
    }

    private fun launch(intent: Intent, requestCode: Int, result: MethodChannel.Result) {
        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (error: Exception) {
            // A device with no document provider at all. Rare, but it must
            // not take the app down.
            pending = null
            result.error(ERROR_NO_PICKER, "No file picker is available", null)
        }
    }

    /**
     * Answers the waiting call once the picker closes.
     *
     * Returns true when the result was ours, so the activity knows whether to
     * pass it on to anything else.
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CREATE &&
            requestCode != REQUEST_OPEN &&
            requestCode != REQUEST_TREE
        ) {
            return false
        }

        val waiting = pending ?: return true
        pending = null

        if (resultCode != Activity.RESULT_OK) {
            // Backing out of the picker is a normal thing to do, not a fault.
            waiting.success(null)
            return true
        }

        val uri = data?.data
        if (uri == null) {
            waiting.success(null)
            return true
        }

        waiting.success(uri.toString())
        return true
    }

    /**
     * Deletes a document the app just created.
     *
     * Used when a backup fails part way through, so the user is not left with
     * an unreadable stub sitting where they expected their archive.
     */
    fun deleteDocument(uri: String): Boolean = runCatching {
        DocumentsContract.deleteDocument(activity.contentResolver, Uri.parse(uri))
    }.getOrDefault(false)

    companion object {
        private const val CHANNEL_NAME = "in.sreerajp.imgvidgal/documents"

        private const val REQUEST_CREATE = 0x8A11
        private const val REQUEST_OPEN = 0x8A12
        private const val REQUEST_TREE = 0x8A13

        /** Must match `AppConstants.vaultStorageDirectoryName` in Dart. */
        private const val VAULT_FOLDER = ".secure_vault"

        /** Must match `AppConstants.vaultWorkingExtension` in Dart. */
        private const val VAULT_WORKING_EXTENSION = ".dec"

        private const val EXTERNAL_STORAGE_AUTHORITY = "com.android.externalstorage.documents"
        private const val PRIMARY_PREFIX = "primary:"

        private const val DEFAULT_MIME = "application/octet-stream"

        /** Cap on a prefix read. The header is tens of bytes, not kilobytes. */
        private const val MAX_PREFIX_BYTES = 4096

        /** Cache subfolder picked documents are copied into. */
        private const val COPY_FOLDER = "picked_documents"
        private const val COPY_BLOCK_BYTES = 64 * 1024
        private const val DEFAULT_COPY_MAX_BYTES = 256 * 1024 * 1024
        private const val HARD_COPY_MAX_BYTES = 512 * 1024 * 1024

        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val ERROR_BUSY = "picker_busy"
        private const val ERROR_NO_PICKER = "no_picker"
        private const val ERROR_UNREADABLE = "unreadable"
        private const val ERROR_CANCELLED = "cancelled"
        private const val ERROR_TOO_LARGE = "too_large"
        private const val ERROR_WRITE_FAILED = "write_failed"
    }
}
