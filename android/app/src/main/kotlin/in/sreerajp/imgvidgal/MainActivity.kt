package `in`.sreerajp.imgvidgal

import `in`.sreerajp.imgvidgal.backup.BackupChannelHandler
import `in`.sreerajp.imgvidgal.backup.DocumentPickerChannelHandler
import `in`.sreerajp.imgvidgal.media.MediaStoreChannelHandler
import `in`.sreerajp.imgvidgal.playback.PlaybackChannelHandler
import `in`.sreerajp.imgvidgal.tools.HashToolsChannelHandler
import `in`.sreerajp.imgvidgal.tools.ImageToolsChannelHandler
import `in`.sreerajp.imgvidgal.tools.IntentChannelHandler
import `in`.sreerajp.imgvidgal.tools.VideoToolsChannelHandler
import `in`.sreerajp.imgvidgal.vault.VaultChannelHandler
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    private var mediaStoreHandler: MediaStoreChannelHandler? = null
    private var playbackHandler: PlaybackChannelHandler? = null
    private var imageToolsHandler: ImageToolsChannelHandler? = null
    private var videoToolsHandler: VideoToolsChannelHandler? = null
    private var hashToolsHandler: HashToolsChannelHandler? = null
    private var intentHandler: IntentChannelHandler? = null
    private var vaultHandler: VaultChannelHandler? = null
    private var backupHandler: BackupChannelHandler? = null
    private var documentPickerHandler: DocumentPickerChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStoreHandler = MediaStoreChannelHandler(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
        playbackHandler = PlaybackChannelHandler(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
        imageToolsHandler = ImageToolsChannelHandler(
            flutterEngine.dartExecutor.binaryMessenger
        )
        videoToolsHandler = VideoToolsChannelHandler(
            flutterEngine.dartExecutor.binaryMessenger
        )
        hashToolsHandler = HashToolsChannelHandler(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
        intentHandler = IntentChannelHandler(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
        vaultHandler = VaultChannelHandler(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
        backupHandler = BackupChannelHandler(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
        documentPickerHandler = DocumentPickerChannelHandler(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
    }

    /**
     * Hands the file picker its answer.
     *
     * The backup and restore flows both wait on a Storage Access Framework
     * dialog, and this is the only route its result can arrive by. The
     * handler says whether the result was one of its own, so anything else
     * still reaches the rest of the app untouched.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val handledMedia = mediaStoreHandler?.onActivityResult(
            requestCode,
            resultCode,
            data
        ) ?: false
        if (handledMedia) return

        val handled = documentPickerHandler?.onActivityResult(
            requestCode,
            resultCode,
            data
        ) ?: false
        if (!handled) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        mediaStoreHandler?.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intentHandler?.handleNewIntent(intent)
    }

    override fun onDestroy() {
        mediaStoreHandler?.dispose()
        mediaStoreHandler = null
        playbackHandler?.dispose()
        playbackHandler = null
        imageToolsHandler?.dispose()
        imageToolsHandler = null
        videoToolsHandler?.dispose()
        videoToolsHandler = null
        hashToolsHandler?.dispose()
        hashToolsHandler = null
        intentHandler?.dispose()
        intentHandler = null
        vaultHandler?.dispose()
        vaultHandler = null
        backupHandler?.dispose()
        backupHandler = null
        documentPickerHandler?.dispose()
        documentPickerHandler = null
        super.onDestroy()
    }
}
