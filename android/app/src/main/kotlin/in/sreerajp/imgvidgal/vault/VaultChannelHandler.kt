package `in`.sreerajp.imgvidgal.vault

import android.app.Activity
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.RandomAccessFile
import java.security.KeyStore
import java.security.SecureRandom
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.CipherInputStream
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * The vault's key, cipher, shredder, and secure window flag.
 *
 * Everything that touches key material lives here and nowhere else. The
 * AES-256 master key is generated inside the Android Keystore under a fixed
 * alias and is never exported: Dart asks for a file to be encrypted or
 * decrypted and gets back only ciphertext, plaintext, or an error. There is no
 * channel method that returns a key, and adding one would defeat the point of
 * the keystore.
 *
 * The ciphers are streamed. A vault video can be gigabytes, so the file is
 * pushed through in blocks rather than read into a byte array first, which
 * keeps memory flat whatever the file size.
 *
 * Every call runs on a background executor and posts its result back on the
 * main thread. Every failure is a channel error: a vault that crashes the app
 * on a corrupt payload would be worse than one that reports it.
 */
class VaultChannelHandler(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL_NAME).also {
        it.setMethodCallHandler(this)
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val secureRandom = SecureRandom()

    /**
     * How many screens have asked for FLAG_SECURE.
     *
     * Counted rather than set, so a vault viewer opening on top of the vault
     * grid and then closing does not clear the flag while the grid is still
     * on screen.
     */
    private var secureRequestCount = 0

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // The window flag has to be set on the UI thread and is instant,
            // so it does not go near the worker.
            "setSecureFlag" -> {
                setSecureFlag(call.argument<Boolean>("enabled") ?: false)
                result.success(null)
            }
            "isKeystoreReady" -> runInBackground(result) { isKeystoreReady() }
            "ensureMasterKey" -> runInBackground(result) { ensureMasterKey(); true }
            "encryptFile" -> runInBackground(result) { encryptFile(call) }
            "encryptBytes" -> runInBackground(result) { encryptBytes(call) }
            "decryptToBytes" -> runInBackground(result) { decryptToBytes(call) }
            "decryptToFile" -> runInBackground(result) { decryptToFile(call) }
            "shredFile" -> runInBackground(result) { shredFile(call) }
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- window

    /**
     * Turns FLAG_SECURE on or off, keeping a count of who asked.
     *
     * With the flag set, Android refuses screenshots and screen recording for
     * this window, and shows a blank card in the app switcher instead of a
     * preview of whatever the vault was showing.
     */
    private fun setSecureFlag(enabled: Boolean) {
        if (enabled) {
            secureRequestCount++
        } else if (secureRequestCount > 0) {
            secureRequestCount--
        }
        val shouldBeSecure = secureRequestCount > 0
        activity.runOnUiThread {
            if (shouldBeSecure) {
                activity.window.setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE
                )
            } else {
                activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    // ------------------------------------------------------------------- key

    /** Whether a usable master key exists, or can be created right now. */
    private fun isKeystoreReady(): Boolean {
        return try {
            ensureMasterKey()
            true
        } catch (error: Exception) {
            false
        }
    }

    /**
     * Returns the master key, generating it on first use.
     *
     * StrongBox is asked for when the device advertises it, which puts the key
     * in a separate security chip. A device can advertise it and still refuse
     * to generate, so that path falls back to the ordinary hardware-backed
     * keystore rather than leaving the user with no vault at all.
     *
     * The key is deliberately not bound to user authentication. Binding it
     * would make the vault unopenable on a phone with no screen lock and no
     * enrolled fingerprint, with no way back to the photos inside. The app
     * gates the vault instead: biometric or PIN before anything is decrypted.
     */
    private fun ensureMasterKey(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && hasStrongBox()) {
            try {
                return generateKey(useStrongBox = true)
            } catch (error: Exception) {
                // Advertised but unusable. Fall through to the normal keystore.
            }
        }
        return generateKey(useStrongBox = false)
    }

    private fun hasStrongBox(): Boolean =
        activity.packageManager.hasSystemFeature(
            android.content.pm.PackageManager.FEATURE_STRONGBOX_KEYSTORE
        )

    private fun generateKey(useStrongBox: Boolean): SecretKey {
        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            KEYSTORE_PROVIDER
        )
        val builder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(KEY_SIZE_BITS)
            // Refuses to reuse an IV, so a caller cannot accidentally destroy
            // GCM's guarantees by passing the same one twice.
            .setRandomizedEncryptionRequired(true)

        if (useStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }

        generator.init(builder.build())
        return generator.generateKey()
    }

    // ---------------------------------------------------------------- cipher

    /**
     * Encrypts the file at `sourceUri` or `sourcePath` into `destPath`.
     *
     * Returns the base64 IV and the ciphertext size. The GCM authentication
     * tag is appended to the ciphertext by the platform cipher, so it is part
     * of the payload rather than a separate value to store.
     */
    private fun encryptFile(call: MethodCall): Map<String, Any> {
        val destPath = call.argument<String>("destPath")
            ?: throw IllegalArgumentException("destPath is required")

        val key = ensureMasterKey()
        // No IV is passed in. The key is generated with randomised encryption
        // required, so the keystore insists on drawing the IV itself and
        // refuses a caller-supplied one. That is the stronger arrangement: it
        // makes reusing an IV under this key impossible rather than merely
        // discouraged. The IV it chose is read back below and stored beside
        // the ciphertext, which is all decryption needs.
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.ENCRYPT_MODE, key)
        }
        val iv = cipher.iv
            ?: throw IllegalStateException("the cipher produced no IV")
        if (iv.size != IV_LENGTH_BYTES) {
            throw IllegalStateException("unexpected IV length")
        }

        val destination = File(destPath)
        destination.parentFile?.mkdirs()

        var written = 0L
        try {
            openSource(call).use { input ->
                FileOutputStream(destination).use { rawOutput ->
                    written = pumpThroughCipher(input, rawOutput, cipher)
                }
            }
        } catch (error: Exception) {
            // Never leave a half-written payload: a truncated file would fail
            // its tag check later and look like tampering.
            destination.delete()
            throw error
        }

        return mapOf(
            "iv" to Base64.encodeToString(iv, Base64.NO_WRAP),
            "sizeBytes" to written
        )
    }

    /**
     * Encrypts bytes already in memory into `destPath`.
     *
     * This exists for the previews. A vault preview is generated by decoding
     * the original and shrinking it, which happens in Dart, and writing that
     * plaintext to a file just so it could be encrypted would put a readable
     * copy of a private photo on disk — briefly, but on disk. The bytes cross
     * the channel instead and only ciphertext is ever written.
     *
     * Previews are small by construction, so holding one in memory is cheap.
     * Whole media files go through [encryptFile], which streams.
     */
    private fun encryptBytes(call: MethodCall): Map<String, Any> {
        val destPath = call.argument<String>("destPath")
            ?: throw IllegalArgumentException("destPath is required")
        val plain = call.argument<ByteArray>("bytes")
            ?: throw IllegalArgumentException("bytes is required")

        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.ENCRYPT_MODE, ensureMasterKey())
        }
        val iv = cipher.iv
            ?: throw IllegalStateException("the cipher produced no IV")

        val destination = File(destPath)
        destination.parentFile?.mkdirs()

        val cipherText = cipher.doFinal(plain)
        try {
            FileOutputStream(destination).use { output ->
                output.write(cipherText)
                output.flush()
                output.fd.sync()
            }
        } catch (error: Exception) {
            destination.delete()
            throw error
        }

        return mapOf(
            "iv" to Base64.encodeToString(iv, Base64.NO_WRAP),
            "sizeBytes" to cipherText.size.toLong()
        )
    }

    /**
     * Decrypts a payload straight into a byte array.
     *
     * Used for photos and previews, so nothing decrypted ever reaches disk.
     * `maxBytes` is enforced before the file is opened, so a video cannot be
     * pulled into memory by mistake.
     */
    private fun decryptToBytes(call: MethodCall): ByteArray {
        val sourcePath = call.argument<String>("sourcePath")
            ?: throw IllegalArgumentException("sourcePath is required")
        val maxBytes = (call.argument<Number>("maxBytes") ?: 0L).toLong()

        val source = File(sourcePath)
        if (!source.exists()) throw IllegalStateException("payload is missing")
        if (maxBytes > 0 && source.length() > maxBytes) {
            throw IllegalStateException("payload is too large to read into memory")
        }

        val cipher = decryptCipher(call)
        return CipherInputStream(source.inputStream(), cipher).use { it.readBytes() }
    }

    /**
     * Decrypts a payload into a working file the platform player can open.
     *
     * The destination is chosen by Dart and always sits inside the app-private
     * vault directory, never the public cache and never the temporary
     * directory. Dart shreds it when the player closes.
     */
    private fun decryptToFile(call: MethodCall): Long {
        val sourcePath = call.argument<String>("sourcePath")
            ?: throw IllegalArgumentException("sourcePath is required")
        val destPath = call.argument<String>("destPath")
            ?: throw IllegalArgumentException("destPath is required")

        val source = File(sourcePath)
        if (!source.exists()) throw IllegalStateException("payload is missing")

        val cipher = decryptCipher(call)
        val destination = File(destPath)
        destination.parentFile?.mkdirs()

        var written = 0L
        try {
            CipherInputStream(source.inputStream(), cipher).use { input ->
                FileOutputStream(destination).use { output ->
                    val buffer = ByteArray(BLOCK_SIZE)
                    while (true) {
                        val read = input.read(buffer)
                        if (read <= 0) break
                        output.write(buffer, 0, read)
                        written += read
                    }
                    output.flush()
                    output.fd.sync()
                }
            }
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
        return written
    }

    private fun decryptCipher(call: MethodCall): Cipher {
        val ivBase64 = call.argument<String>("iv")
            ?: throw IllegalArgumentException("iv is required")
        val iv = Base64.decode(ivBase64, Base64.NO_WRAP)
        return Cipher.getInstance(TRANSFORMATION).apply {
            init(
                Cipher.DECRYPT_MODE,
                ensureMasterKey(),
                GCMParameterSpec(TAG_LENGTH_BITS, iv)
            )
        }
    }

    /**
     * Opens the original, from a content URI when there is one and a path
     * otherwise.
     *
     * Newer Android versions hand out URIs and no usable path, older ones the
     * other way round, so both are accepted.
     */
    private fun openSource(call: MethodCall): InputStream {
        val uri = call.argument<String>("sourceUri")
        if (!uri.isNullOrEmpty()) {
            return activity.contentResolver.openInputStream(Uri.parse(uri))
                ?: throw IllegalStateException("the original could not be opened")
        }
        val path = call.argument<String>("sourcePath")
            ?: throw IllegalArgumentException("sourceUri or sourcePath is required")
        return File(path).inputStream()
    }

    /**
     * Streams [input] through [cipher] into [output], returning bytes written.
     *
     * `doFinal` at the end is what appends the GCM tag, so it must run even
     * when the last read returned nothing.
     */
    private fun pumpThroughCipher(
        input: InputStream,
        output: FileOutputStream,
        cipher: Cipher
    ): Long {
        val buffer = ByteArray(BLOCK_SIZE)
        var written = 0L
        while (true) {
            val read = input.read(buffer)
            if (read <= 0) break
            cipher.update(buffer, 0, read)?.let {
                output.write(it)
                written += it.size
            }
        }
        cipher.doFinal()?.let {
            output.write(it)
            written += it.size
        }
        output.flush()
        output.fd.sync()
        return written
    }

    // --------------------------------------------------------------- shredder

    /**
     * Overwrites a file and then unlinks it.
     *
     * One zero-fill pass, then alternating random and zero passes, each
     * followed by a sync so the bytes actually reach the device rather than
     * sitting in a buffer that is thrown away when the file is deleted.
     *
     * This is a best effort and is documented as one. On flash storage the
     * controller may write each pass to a fresh block and leave the old
     * contents in an area no file API can reach. It defeats undelete tools and
     * casual recovery; it is not a guarantee against a laboratory.
     */
    private fun shredFile(call: MethodCall): Boolean {
        val path = call.argument<String>("path")
            ?: throw IllegalArgumentException("path is required")
        val passes = (call.argument<Int>("passes") ?: 2).coerceIn(1, 5)

        val file = File(path)
        // Already gone is the outcome the caller wanted, not a failure.
        if (!file.exists()) return true
        if (!file.isFile) return false

        try {
            val length = file.length()
            if (length > 0) {
                RandomAccessFile(file, "rws").use { raf ->
                    val buffer = ByteArray(BLOCK_SIZE)
                    for (pass in 0 until passes) {
                        if (pass % 2 == 0) {
                            buffer.fill(0)
                        } else {
                            secureRandom.nextBytes(buffer)
                        }
                        raf.seek(0)
                        var remaining = length
                        while (remaining > 0) {
                            val chunk = minOf(remaining, buffer.size.toLong()).toInt()
                            raf.write(buffer, 0, chunk)
                            remaining -= chunk
                        }
                        raf.fd.sync()
                    }
                    // Truncate so the size itself stops being a hint.
                    raf.setLength(0)
                    raf.fd.sync()
                }
            }
        } catch (error: Exception) {
            // An overwrite that failed part way still leaves a file that has
            // to go. Deleting is strictly better than keeping it.
            return file.delete()
        }

        return file.delete()
    }

    // ---------------------------------------------------------------- plumbing

    /**
     * Runs [block] off the main thread and answers the channel on it.
     *
     * Every exception becomes a channel error carrying a short code and no
     * file name: a vault error can be logged, and a log line naming a vault
     * file would undo part of what the vault is for.
     */
    private fun <T> runInBackground(
        result: MethodChannel.Result,
        block: () -> T
    ) {
        worker.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                val code = when (error) {
                    is IllegalArgumentException -> ERROR_INVALID_ARGUMENTS
                    is javax.crypto.AEADBadTagException -> ERROR_TAMPERED
                    else -> ERROR_VAULT_FAILED
                }
                mainHandler.post {
                    result.error(code, error.javaClass.simpleName, null)
                }
            }
        }
    }

    companion object {
        private const val CHANNEL_NAME = "in.sreerajp.imgvidgal/vault"

        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "imgvidgal_vault_master_key"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val KEY_SIZE_BITS = 256
        private const val IV_LENGTH_BYTES = 12
        private const val TAG_LENGTH_BITS = 128
        private const val BLOCK_SIZE = 64 * 1024

        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val ERROR_TAMPERED = "payload_tampered"
        private const val ERROR_VAULT_FAILED = "vault_failed"
    }
}
