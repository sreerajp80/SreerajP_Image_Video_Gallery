package `in`.sreerajp.imgvidgal.tools

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands a scanned code to another app, and refuses to hand over anything else.
 *
 * This is the only place in the app that builds an outgoing intent from text
 * the user did not type. A code came off a poster, a screenshot, or a stranger,
 * so it is untrusted input in the fullest sense: an unchecked `intent:` or
 * `content:` URI here would let a printed square reach into other apps or at
 * this app's own private files.
 *
 * So the rule is a permitted list, never a forbidden one. Six schemes are
 * allowed and everything else is refused. Dart checks first, in
 * `ScanActionResolver`; this checks again, because the Dart side is one bug
 * away from being bypassed and a second gate costs almost nothing.
 *
 * Nothing here reaches the internet. An `http` URL is handed to the browser,
 * which is the user's own app making its own connection; this app opens no
 * socket, and hard rule 2 is untouched.
 */
class IntentChannelHandler(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL_NAME).also {
        it.setMethodCallHandler(this)
    }
    private var initialIntentConsumed = false

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openUri" -> openUri(call, result)
            "openWifiSettings" -> openWifiSettings(result)
            "suggestWifiNetwork" -> suggestWifiNetwork(call, result)
            "copyToClipboard" -> copyToClipboard(call, result)
            "getInitialMediaIntent" -> getInitialMediaIntent(result)
            "openDefaultAppsSettings" -> openDefaultAppsSettings(result)
            "shareFile" -> shareFile(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * Opens a `http`, `https`, `tel`, `mailto`, `sms` or `geo` URI.
     *
     * `ACTION_VIEW` with an explicit `Uri` is deliberate. `Intent.parseUri`
     * would accept the `intent:` form, which can name a target component and
     * carry its own extras — exactly the thing a hostile QR code wants.
     */
    private fun openUri(call: MethodCall, result: MethodChannel.Result) {
        val raw = call.argument<String>("uri")
        if (raw.isNullOrBlank()) {
            result.error("bad_uri", "No address was given", null)
            return
        }

        val uri = try {
            Uri.parse(raw)
        } catch (error: Exception) {
            result.error("bad_uri", "The address could not be read", null)
            return
        }

        val scheme = uri.scheme?.lowercase()
        if (scheme == null || scheme !in ALLOWED_SCHEMES) {
            result.error(
                "blocked_scheme",
                "This kind of address is not opened by the app",
                null
            )
            return
        }

        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            // Never let the code choose the component it lands in.
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            activity.startActivity(intent)
            result.success(true)
        } catch (error: ActivityNotFoundException) {
            result.error("no_app", "No app on this device can open it", null)
        } catch (error: SecurityException) {
            result.error("refused", "Android refused to open it", null)
        }
    }

    /** Opens the system Wi-Fi screen so the user picks the network by hand. */
    private fun openWifiSettings(result: MethodChannel.Result) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent(Settings.Panel.ACTION_WIFI)
        } else {
            Intent(Settings.ACTION_WIFI_SETTINGS)
        }.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        try {
            activity.startActivity(intent)
            result.success(true)
        } catch (error: ActivityNotFoundException) {
            result.error("no_app", "The Wi-Fi settings could not be opened", null)
        }
    }

    /**
     * Offers the network to Android, then opens the Wi-Fi screen.
     *
     * A suggestion is the strongest thing an app may do here without holding
     * location permission, and it is the right strength: Android decides, and
     * the user still taps the network themselves. The app never silently joins
     * anything, which matters when the code came off a wall in a cafe.
     *
     * Below Android 10 there is no suggestion API worth using — the old
     * `addNetwork` route is deprecated and refused to apps that do not own the
     * network — so the honest answer is to say it is not supported and let the
     * Dart side fall back to the settings screen and the copied password.
     */
    private fun suggestWifiNetwork(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(false)
            return
        }

        val ssid = call.argument<String>("ssid")
        if (ssid.isNullOrBlank()) {
            result.error("bad_network", "No network name was given", null)
            return
        }

        val password = call.argument<String>("password").orEmpty()
        val security = call.argument<String>("security").orEmpty().lowercase()
        val hidden = call.argument<Boolean>("hidden") ?: false

        val suggestion = try {
            WifiNetworkSuggestion.Builder()
                .setSsid(ssid)
                .setIsHiddenSsid(hidden)
                .apply {
                    when {
                        security == "sae" && password.isNotEmpty() ->
                            setWpa3Passphrase(password)
                        password.isNotEmpty() -> setWpa2Passphrase(password)
                        // An open network needs no passphrase set at all.
                    }
                }
                .build()
        } catch (error: IllegalArgumentException) {
            // A name or passphrase Android will not accept, such as one that
            // is too long. Not worth an error dialog: the settings screen is
            // still a perfectly good answer.
            result.success(false)
            return
        }

        val manager = activity.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager
        if (manager == null) {
            result.success(false)
            return
        }

        val status = try {
            manager.addNetworkSuggestions(listOf(suggestion))
        } catch (error: Exception) {
            result.success(false)
            return
        }

        val accepted = status == WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS ||
            status == WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_DUPLICATE

        result.success(accepted)
    }

    /**
     * Puts text on the clipboard.
     *
     * `isSensitive` marks a Wi-Fi password so Android 13 and above does not
     * show it in the clipboard preview toast. A password read off a card is
     * still a password, and it should not end up on a screen someone else is
     * looking at.
     */
    private fun copyToClipboard(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text")
        if (text == null) {
            result.error("bad_text", "There was nothing to copy", null)
            return
        }

        val label = call.argument<String>("label").orEmpty()
        val sensitive = call.argument<Boolean>("isSensitive") ?: false

        val manager = activity.getSystemService(Context.CLIPBOARD_SERVICE)
            as? ClipboardManager
        if (manager == null) {
            result.error("no_clipboard", "The clipboard is not available", null)
            return
        }

        val clip = ClipData.newPlainText(label, text).apply {
            if (sensitive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                description.extras = android.os.PersistableBundle().apply {
                    putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                }
            }
        }

        manager.setPrimaryClip(clip)
        result.success(true)
    }

    /**
     * Forwards an incoming intent to Flutter if it targets media viewing.
     * Called when the app is already in memory and receives a new intent.
     */
    fun handleNewIntent(intent: Intent) {
        val data = extractMediaIntentData(intent) ?: return
        channel.invokeMethod("onMediaIntent", data)
    }

    /**
     * Returns the media data from the launch intent if the app was opened
     * to view an image or video file. Consumed after the first read.
     */
    private fun getInitialMediaIntent(result: MethodChannel.Result) {
        if (initialIntentConsumed) {
            result.success(null)
            return
        }
        val data = extractMediaIntentData(activity.intent)
        if (data != null) {
            initialIntentConsumed = true
        }
        result.success(data)
    }

    /**
     * Opens the system settings screen where users can set default apps.
     */
    private fun openDefaultAppsSettings(result: MethodChannel.Result) {
        // Try the standard Default Apps settings screen first
        val manageDefaultsIntent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (canResolve(manageDefaultsIntent)) {
            try {
                activity.startActivity(manageDefaultsIntent)
                result.success(true)
                return
            } catch (_: Exception) {}
        }

        // On Android 12+, try the app-specific "Open by default" screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val appDefaultsIntent = Intent(
                Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS,
                Uri.parse("package:${activity.packageName}")
            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            if (canResolve(appDefaultsIntent)) {
                try {
                    activity.startActivity(appDefaultsIntent)
                    result.success(true)
                    return
                } catch (_: Exception) {}
            }
        }

        // Fallback to app details settings
        val appDetailsIntent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${activity.packageName}")
        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
        try {
            activity.startActivity(appDetailsIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("no_settings", "The settings screen could not be opened", null)
        }
    }

    /**
     * Shares a local file through the Android system share sheet (ACTION_SEND).
     *
     * Uses FileProvider to expose a content URI with read grant permissions,
     * maintaining 100% offline local IPC with zero external network access.
     */
    private fun shareFile(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        if (filePath.isNullOrBlank()) {
            result.error("bad_path", "No file path was given", null)
            return
        }

        val file = File(filePath)
        if (!file.exists()) {
            result.error("not_found", "The file does not exist", null)
            return
        }

        val mimeType = call.argument<String>("mimeType") ?: "image/*"
        val title = call.argument<String>("title") ?: "Share Media"

        try {
            val contentUri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                file
            )

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, contentUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = Intent.createChooser(shareIntent, title).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(chooser)
            result.success(true)
        } catch (e: Exception) {
            result.error("share_failed", e.message ?: "Failed to share file", null)
        }
    }

    private fun canResolve(intent: Intent): Boolean {
        return intent.resolveActivity(activity.packageManager) != null
    }

    /**
     * Extracts safe URI, MIME type, and display name from an ACTION_VIEW intent.
     */
    private fun extractMediaIntentData(intent: Intent?): Map<String, Any?>? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: return null

        val resolver = activity.contentResolver
        var mimeType = intent.type ?: resolver.getType(uri)
        var displayName: String? = null
        var size: Long? = null

        if (uri.scheme == ContentResolver.SCHEME_CONTENT) {
            try {
                resolver.query(
                    uri,
                    arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                    null,
                    null,
                    null
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (nameIndex != -1) displayName = cursor.getString(nameIndex)
                        val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (sizeIndex != -1) size = cursor.getLong(sizeIndex)
                    }
                }
            } catch (_: Exception) {}
        }

        if (displayName.isNullOrBlank()) {
            displayName = uri.lastPathSegment ?: "media"
        }

        if (mimeType.isNullOrBlank()) {
            val extension = MimeTypeMap.getFileExtensionFromUrl(uri.toString())
            if (!extension.isNullOrEmpty()) {
                mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
            }
        }

        val resolvedMime = mimeType ?: "image/*"
        val isVideo = resolvedMime.startsWith("video/")

        return mapOf(
            "uri" to uri.toString(),
            "mimeType" to resolvedMime,
            "displayName" to displayName,
            "size" to (size ?: 0L),
            "isVideo" to isVideo
        )
    }

    private companion object {
        const val CHANNEL_NAME = "in.sreerajp.imgvidgal/intents"

        /**
         * The only schemes this app will ever launch.
         *
         * Kept in step with `AppConstants.scanLaunchableSchemes` on the Dart
         * side. Adding one here without a reason written down is a security
         * change, not a convenience.
         */
        val ALLOWED_SCHEMES = setOf(
            "http",
            "https",
            "tel",
            "mailto",
            "sms",
            "geo"
        )
    }
}
