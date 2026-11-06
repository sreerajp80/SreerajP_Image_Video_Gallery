package `in`.sreerajp.imgvidgal.device

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The app's own version name and build number, read from PackageManager.
 *
 * This replaces the `package_info_plus` plugin, which pulled an HTTP client
 * into the dependency tree for its web build. It reads only this app's own
 * package record, needs no permission, and opens no connection.
 */
class AppInfoChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL_NAME).also {
        it.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAppInfo" -> {
                try {
                    result.success(readAppInfo())
                } catch (e: PackageManager.NameNotFoundException) {
                    result.error(ERROR_UNAVAILABLE, "package info unavailable", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun readAppInfo(): Map<String, String> {
        val manager = context.packageManager
        val name = context.packageName
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.getPackageInfo(name, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            manager.getPackageInfo(name, 0)
        }
        val buildNumber = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return mapOf(
            "versionName" to (info.versionName ?: ""),
            "buildNumber" to buildNumber.toString()
        )
    }

    companion object {
        const val CHANNEL_NAME = "in.sreerajp.imgvidgal/app_info"
        private const val ERROR_UNAVAILABLE = "unavailable"
    }
}
