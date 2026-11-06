package `in`.sreerajp.imgvidgal.media

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import java.io.File
import java.io.IOException

/**
 * Decides whether a media link may be opened by this app.
 *
 * "Open with" is exported, so any app can hand over any link, and this app
 * reads a link with its own rights. Without this check, a link to this app's
 * private folders would make it open its own files on another app's say-so.
 *
 * `file://` cannot simply be refused: on Android 9 and below, `publishFile`
 * returns a `file://` link for a saved file. So the rule targets the real
 * danger, which is private files. A check that cannot finish refuses the link.
 */
object IncomingUriRules {

    private const val FILE_PROVIDER_SUFFIX = ".fileprovider"

    fun isAllowed(context: Context, uri: Uri): Boolean {
        return when (uri.scheme?.lowercase()) {
            ContentResolver.SCHEME_CONTENT ->
                uri.authority?.lowercase() !=
                    (context.packageName + FILE_PROVIDER_SUFFIX).lowercase()
            ContentResolver.SCHEME_FILE -> isOutsidePrivateFolders(context, uri)
            else -> false
        }
    }

    private fun isOutsidePrivateFolders(context: Context, uri: Uri): Boolean {
        val path = uri.path ?: return false
        return try {
            // Canonical, so `..` and symbolic links cannot walk around the check.
            val target = File(path).canonicalPath
            privateFolders(context).none { folder ->
                val root = folder.canonicalPath
                target == root || target.startsWith(root + File.separator)
            }
        } catch (_: IOException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun privateFolders(context: Context): List<File> {
        val folders = mutableListOf(
            context.dataDir,
            context.createDeviceProtectedStorageContext().dataDir,
        )
        folders += context.getExternalFilesDirs(null).filterNotNull()
        folders += context.externalCacheDirs.filterNotNull()
        return folders
    }
}
