package `in`.sreerajp.imgvidgal.vault

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.WindowManager
import `in`.sreerajp.imgvidgal.media.MediaStoreWriter
import `in`.sreerajp.imgvidgal.media.SecureOverwrite
import com.google.crypto.tink.Aead
import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.RegistryConfiguration
import com.google.crypto.tink.StreamingAead
import com.google.crypto.tink.TinkProtoKeysetFormat
import com.google.crypto.tink.streamingaead.PredefinedStreamingAeadParameters
import com.google.crypto.tink.streamingaead.StreamingAeadConfig
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.security.DigestOutputStream
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.concurrent.Executors
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * The vault's key, cipher, shredder, and secure window flag.
 *
 * Everything that touches key material lives here and nowhere else. There
 * is no channel method that returns a key, and adding one would defeat the
 * point of the keystore.
 *
 * **Two keys (envelope encryption).** The AES-256 *master key* is generated
 * inside the Android Keystore (StrongBox when the phone has it) and is never
 * exported. It is slow for bulk data, because every byte would have to travel
 * into the secure hardware and back, so it now encrypts only one small thing:
 * the *data keyset*. That keyset (Tink `AES256_GCM_HKDF_1MB` streaming AEAD)
 * is stored, encrypted by the master key, in one file in the vault directory,
 * and does the bulk work on the normal CPU. It is held in memory only while
 * the vault is open; Dart calls `forgetDataKey` when the vault locks.
 *
 * **Two payload formats.** Format 1 is the old one: raw AES-GCM under the
 * master key, with the IV in the database. Format 2 is Tink streaming
 * ciphertext under the data keyset; the database "iv" column then holds a
 * random per-file id that is bound to the ciphertext as associated data, so
 * two payload files swapped on disk fail their check. Every write is format 2.
 * Format 1 is only read, until the upgrade job converts it.
 *
 * The ciphers are streamed. A vault video can be gigabytes, so the file is
 * pushed through in blocks rather than read into a byte array first, which
 * keeps memory flat whatever the file size. Tink's format checks each 1 MB
 * segment on its own, so even decryption never has to hold the whole file.
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
            "digestPayload" -> runInBackground(result) { digestPayload(call) }
            "previewFromPayload" -> runInBackground(result) { previewFromPayload(call) }
            "restoreToGallery" -> runInBackground(result) { restoreToGallery(call) }
            "canRestoreToGallery" -> result.success(
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
            )
            "forgetDataKey" -> runInBackground(result) { forgetDataKey(); true }
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

    // ------------------------------------------------------------ data key

    /** The data keyset's primitive while the vault is open, else null. */
    private var dataKey: StreamingAead? = null

    /** Which keyset file [dataKey] was loaded from. */
    private var dataKeyPath: String? = null

    /**
     * Returns the data keyset's streaming cipher, loading or creating it.
     *
     * The keyset file is created only when it does not exist. A file that
     * exists but will not open is an error, never a reason to make a new one:
     * replacing it would make every format-2 item unreadable for good.
     *
     * Runs only on [worker], which is single-threaded, so the cache needs no
     * lock.
     */
    private fun dataKeyFor(keysetPath: String): StreamingAead {
        val cached = dataKey
        if (cached != null && dataKeyPath == keysetPath) return cached

        StreamingAeadConfig.register()
        val wrapper = MasterKeyAead(ensureMasterKey())
        val file = File(keysetPath)

        val handle = if (file.exists()) {
            TinkProtoKeysetFormat.parseEncryptedKeyset(
                file.readBytes(),
                wrapper,
                KEYSET_ASSOCIATED_DATA
            )
        } else {
            val fresh = KeysetHandle.generateNew(
                PredefinedStreamingAeadParameters.AES256_GCM_HKDF_1MB
            )
            val sealed = TinkProtoKeysetFormat.serializeEncryptedKeyset(
                fresh,
                wrapper,
                KEYSET_ASSOCIATED_DATA
            )
            writeAtomically(file, sealed)
            fresh
        }

        val primitive = handle.getPrimitive(
            RegistryConfiguration.get(),
            StreamingAead::class.java
        )
        dataKey = primitive
        dataKeyPath = keysetPath
        return primitive
    }

    /**
     * Drops the data keyset from memory. Called when the vault locks.
     *
     * The JVM cannot promise the key bytes are wiped, but nothing here holds a
     * reference any more, so they become garbage and are not reachable.
     */
    private fun forgetDataKey() {
        dataKey = null
        dataKeyPath = null
    }

    /**
     * Writes [bytes] to [target] through a temporary file and a rename, so a
     * crash leaves either no keyset or a whole one, never half of one.
     */
    private fun writeAtomically(target: File, bytes: ByteArray) {
        target.parentFile?.mkdirs()
        val temp = File(target.parentFile, target.name + ".tmp")
        FileOutputStream(temp).use { output ->
            output.write(bytes)
            output.flush()
            output.fd.sync()
        }
        if (!temp.renameTo(target)) {
            temp.delete()
            throw IllegalStateException("the data key could not be saved")
        }
    }

    /**
     * The Keystore master key as a Tink [Aead], used only to seal and open
     * the data keyset. Output is `IV (12 bytes) || ciphertext+tag`.
     */
    private class MasterKeyAead(private val key: SecretKey) : Aead {
        override fun encrypt(plaintext: ByteArray, associatedData: ByteArray?): ByteArray {
            val cipher = Cipher.getInstance(TRANSFORMATION).apply {
                init(Cipher.ENCRYPT_MODE, key)
            }
            if (associatedData != null) cipher.updateAAD(associatedData)
            val iv = cipher.iv
            if (iv == null || iv.size != IV_LENGTH_BYTES) {
                throw GeneralSecurityException("unexpected IV")
            }
            return iv + cipher.doFinal(plaintext)
        }

        override fun decrypt(ciphertext: ByteArray, associatedData: ByteArray?): ByteArray {
            if (ciphertext.size <= IV_LENGTH_BYTES) {
                throw GeneralSecurityException("sealed key is too short")
            }
            val cipher = Cipher.getInstance(TRANSFORMATION).apply {
                init(
                    Cipher.DECRYPT_MODE,
                    key,
                    GCMParameterSpec(
                        TAG_LENGTH_BITS,
                        ciphertext.copyOfRange(0, IV_LENGTH_BYTES)
                    )
                )
            }
            if (associatedData != null) cipher.updateAAD(associatedData)
            return cipher.doFinal(ciphertext, IV_LENGTH_BYTES, ciphertext.size - IV_LENGTH_BYTES)
        }
    }

    // ---------------------------------------------------------------- cipher

    /**
     * Encrypts the file at `sourceUri` or `sourcePath` into `destPath`.
     *
     * Always writes format 2. Returns the per-file id (as "iv"), the
     * ciphertext size and the format.
     */
    private fun encryptFile(call: MethodCall): Map<String, Any> {
        val destPath = call.argument<String>("destPath")
            ?: throw IllegalArgumentException("destPath is required")
        val streaming = dataKeyFor(keysetPathOf(call))

        val destination = File(destPath)
        destination.parentFile?.mkdirs()
        val fileId = newFileId()
        val digest = MessageDigest.getInstance(DIGEST_ALGORITHM)
        var plainBytes = 0L

        try {
            openSource(call).use { input ->
                SyncingFileOutputStream(destination).use { file ->
                    streaming.newEncryptingStream(file, fileId).use { output ->
                        // The plaintext is measured on its way through, so
                        // Dart can check the written file gives back exactly
                        // this before anything readable is let go.
                        plainBytes = copy(input, output, digest)
                    }
                }
            }
        } catch (error: Exception) {
            // Never leave a half-written payload: a truncated file would fail
            // its check later and look like tampering.
            destination.delete()
            throw error
        }

        return encryptResult(fileId, destination.length(), digest, plainBytes)
    }

    /**
     * Encrypts bytes already in memory into `destPath`.
     *
     * This exists for the previews. A vault preview is generated by decoding
     * the original and shrinking it, which happens in Dart, and writing that
     * plaintext to a file just so it could be encrypted would put a readable
     * copy of a private photo on disk — briefly, but on disk. The bytes cross
     * the channel instead and only ciphertext is ever written.
     */
    private fun encryptBytes(call: MethodCall): Map<String, Any> {
        val destPath = call.argument<String>("destPath")
            ?: throw IllegalArgumentException("destPath is required")
        val plain = call.argument<ByteArray>("bytes")
            ?: throw IllegalArgumentException("bytes is required")
        val streaming = dataKeyFor(keysetPathOf(call))

        val destination = File(destPath)
        destination.parentFile?.mkdirs()
        val fileId = newFileId()

        try {
            SyncingFileOutputStream(destination).use { file ->
                streaming.newEncryptingStream(file, fileId)
                    .use { output -> output.write(plain) }
            }
        } catch (error: Exception) {
            destination.delete()
            throw error
        }

        val digest = MessageDigest.getInstance(DIGEST_ALGORITHM).apply { update(plain) }
        return encryptResult(fileId, destination.length(), digest, plain.size.toLong())
    }

    /**
     * Makes a small JPEG preview from an encrypted photo, all in memory.
     *
     * For vault items that never got a preview. The payload is decrypted
     * into memory (refused over `maxBytes`), decoded with `inSampleSize` so a
     * 12 MP photo is never held at full size, turned upright from its EXIF
     * orientation, scaled so the longest side is `maxSide`, and returned as
     * JPEG. Nothing is written anywhere; the decrypted bytes are wiped before
     * returning. Returns an empty array when the bytes are not a picture
     * Android can decode: a missing preview is never an error.
     */
    private fun previewFromPayload(call: MethodCall): ByteArray {
        val sourcePath = call.argument<String>("sourcePath")
            ?: throw IllegalArgumentException("sourcePath is required")
        val maxSide = (call.argument<Number>("maxSide") ?: 320).toInt().coerceIn(64, 1024)
        val maxBytes = (call.argument<Number>("maxBytes") ?: 0L).toLong()
        val source = File(sourcePath)
        if (!source.exists()) throw IllegalStateException("payload is missing")
        if (maxBytes > 0 && source.length() > maxBytes) {
            throw IllegalStateException("payload is too large to read into memory")
        }

        val sink = ByteArrayOutputStream(source.length().coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
        decryptInto(call, source, sink)
        val plain = sink.toByteArray()
        try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(plain, 0, plain.size, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return ByteArray(0)

            var sample = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) {
                sample *= 2
            }
            val decoded = BitmapFactory.decodeByteArray(
                plain,
                0,
                plain.size,
                BitmapFactory.Options().apply { inSampleSize = sample }
            ) ?: return ByteArray(0)

            val rotation = try {
                when (ExifInterface(plain.inputStream()).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL
                )) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                    ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                    ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                    else -> 0f
                }
            } catch (_: Exception) {
                0f // No readable EXIF: show it as stored.
            }

            val scale = maxSide.toFloat() / maxOf(decoded.width, decoded.height)
            val matrix = Matrix().apply {
                if (scale < 1f) postScale(scale, scale)
                if (rotation != 0f) postRotate(rotation)
            }
            val finished = Bitmap.createBitmap(
                decoded, 0, 0, decoded.width, decoded.height, matrix, true
            )
            return try {
                ByteArrayOutputStream().use { out ->
                    finished.compress(Bitmap.CompressFormat.JPEG, PREVIEW_JPEG_QUALITY, out)
                    out.toByteArray()
                }
            } finally {
                if (finished !== decoded) finished.recycle()
                decoded.recycle()
            }
        } finally {
            plain.fill(0)
        }
    }

    /**
     * Restores a payload into the shared gallery through MediaStore.
     *
     * Android 10 and later only; below that it answers `supported: false`
     * without writing anything, and Dart uses its path-based route, which
     * those versions allow. (On Android 10 an app cannot create files in
     * shared folders by path at all; that is why restores used to fail.)
     *
     * 1. A pending row is made in `relativePath` (re-checked here: DCIM or
     *    Pictures, plus Movies for video). Other apps cannot see it yet.
     * 2. The payload is decrypted straight into it, hashed on the way. No
     *    plaintext lands in the app's own storage.
     * 3. The new file is read back and hashed again; only a match is kept.
     * 4. The row is made visible. On any failure it is deleted instead, and
     *    the item stays in the vault.
     */
    private fun restoreToGallery(call: MethodCall): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return mapOf("supported" to false)
        }
        val sourcePath = call.argument<String>("sourcePath")
            ?: throw IllegalArgumentException("sourcePath is required")
        val displayName = call.argument<String>("displayName")
            ?: throw IllegalArgumentException("displayName is required")
        val mimeType = call.argument<String>("mimeType")
            ?: throw IllegalArgumentException("mimeType is required")
        val isVideo = call.argument<Boolean>("isVideo") ?: false
        val relativePath = call.argument<String>("relativePath")
            ?: throw IllegalArgumentException("relativePath is required")
        if (!MediaStoreWriter.isAllowedRelativePath(relativePath, isVideo)) {
            throw IllegalArgumentException("that folder is not allowed")
        }
        if (displayName.isEmpty() || displayName.contains('/') || displayName.startsWith(".")) {
            throw IllegalArgumentException("that file name is not allowed")
        }
        val source = File(sourcePath)
        if (!source.exists()) throw IllegalStateException("payload is missing")

        val writer = MediaStoreWriter(activity)
        val resolver = activity.contentResolver
        val uri = writer.insertPending(isVideo, displayName, mimeType, relativePath)
        try {
            val written = MessageDigest.getInstance(DIGEST_ALGORITHM)
            val counter = DigestingSink(MessageDigest.getInstance(DIGEST_ALGORITHM))
            (resolver.openOutputStream(uri, "w")
                ?: throw IllegalStateException("the new file could not be opened")).use { raw ->
                val out = DigestOutputStream(raw, written)
                decryptInto(call, source, TeeOutputStream(out, counter))
                out.flush()
            }

            // Read back what is actually in the gallery now.
            val readBack = MessageDigest.getInstance(DIGEST_ALGORITHM)
            var readBytes = 0L
            (resolver.openInputStream(uri)
                ?: throw IllegalStateException("the new file could not be read back")).use { input ->
                val buffer = ByteArray(BLOCK_SIZE)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    readBack.update(buffer, 0, read)
                    readBytes += read
                }
            }
            if (readBytes != counter.count || !MessageDigest.isEqual(readBack.digest(), written.digest())) {
                throw IllegalStateException("the restored file did not read back the same")
            }

            writer.finish(uri)
            return mapOf(
                "supported" to true,
                "uri" to uri.toString(),
                "path" to writer.resolvePath(uri)
            )
        } catch (error: Exception) {
            writer.abort(uri)
            throw error
        }
    }

    /** Writes every byte to [first] and to [second]. Closes only [first]. */
    private class TeeOutputStream(
        private val first: OutputStream,
        private val second: OutputStream
    ) : OutputStream() {
        override fun write(b: Int) {
            first.write(b)
            second.write(b)
        }

        override fun write(b: ByteArray, off: Int, len: Int) {
            first.write(b, off, len)
            second.write(b, off, len)
        }

        override fun flush() = first.flush()

        override fun close() = first.close()
    }

    /**
     * Decrypts a payload as a stream and returns only the SHA-256 and length
     * of its plaintext.
     *
     * The read-back check. Nothing decrypted crosses the channel or touches
     * disk, and memory stays flat whatever the file size. A failed tag check
     * is reported as tampering, like any other read.
     */
    private fun digestPayload(call: MethodCall): Map<String, Any> {
        val sourcePath = call.argument<String>("sourcePath")
            ?: throw IllegalArgumentException("sourcePath is required")
        val source = File(sourcePath)
        if (!source.exists()) throw IllegalStateException("payload is missing")

        val digest = MessageDigest.getInstance(DIGEST_ALGORITHM)
        val sink = DigestingSink(digest)
        decryptInto(call, source, sink)
        return mapOf(
            "sha256" to hex(digest.digest()),
            "plainBytes" to sink.count
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

        val sink = ByteArrayOutputStream(source.length().coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
        decryptInto(call, source, sink)
        return sink.toByteArray()
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

        val destination = File(destPath)
        destination.parentFile?.mkdirs()

        try {
            SyncingFileOutputStream(destination).use { output ->
                decryptInto(call, source, output)
            }
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
        return destination.length()
    }

    /**
     * Decrypts [source] into [sink], by the payload's format.
     *
     * Format 2 reads through the data keyset. Format 1 (the old one) feeds the
     * Keystore cipher in 64 KB blocks; it used to go through
     * `CipherInputStream`, which sends about 512 bytes per call into the
     * secure hardware and made old items very slow to open.
     */
    private fun decryptInto(call: MethodCall, source: File, sink: OutputStream) {
        val format = (call.argument<Number>("format") ?: FORMAT_LEGACY).toInt()
        val idBase64 = call.argument<String>("iv")
            ?: throw IllegalArgumentException("iv is required")
        val id = Base64.decode(idBase64, Base64.NO_WRAP)

        when (format) {
            FORMAT_STREAMING -> {
                val streaming = dataKeyFor(keysetPathOf(call))
                try {
                    source.inputStream().use { raw ->
                        streaming.newDecryptingStream(raw, id).use { input ->
                            copy(input, sink)
                        }
                    }
                } catch (error: FileNotFoundException) {
                    throw error
                } catch (error: IOException) {
                    // Tink reports a failed segment check as an IOException.
                    // The bytes cannot be trusted either way, so it is
                    // reported as the integrity failure it almost always is.
                    throw AEADBadTagException("segment check failed")
                }
            }
            FORMAT_LEGACY -> {
                val cipher = Cipher.getInstance(TRANSFORMATION).apply {
                    init(
                        Cipher.DECRYPT_MODE,
                        ensureMasterKey(),
                        GCMParameterSpec(TAG_LENGTH_BITS, id)
                    )
                }
                source.inputStream().use { input ->
                    val buffer = ByteArray(BLOCK_SIZE)
                    while (true) {
                        val read = input.read(buffer)
                        if (read <= 0) break
                        cipher.update(buffer, 0, read)?.let { sink.write(it) }
                    }
                }
                cipher.doFinal()?.let { sink.write(it) }
            }
            else -> throw IllegalArgumentException("unknown payload format")
        }
    }

    private fun keysetPathOf(call: MethodCall): String =
        call.argument<String>("keysetPath")
            ?: throw IllegalArgumentException("keysetPath is required")

    /** A random id bound to one payload as associated data. */
    private fun newFileId(): ByteArray =
        ByteArray(FILE_ID_LENGTH_BYTES).also { secureRandom.nextBytes(it) }

    private fun encryptResult(
        fileId: ByteArray,
        size: Long,
        digest: MessageDigest,
        plainBytes: Long
    ): Map<String, Any> =
        mapOf(
            "iv" to Base64.encodeToString(fileId, Base64.NO_WRAP),
            "sizeBytes" to size,
            "format" to FORMAT_STREAMING,
            "sha256" to hex(digest.digest()),
            "plainBytes" to plainBytes
        )

    private fun hex(bytes: ByteArray): String =
        bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }

    /** An output that keeps nothing: it only hashes and counts. */
    private class DigestingSink(private val digest: MessageDigest) : OutputStream() {
        var count = 0L
            private set

        override fun write(b: Int) {
            digest.update(b.toByte())
            count++
        }

        override fun write(b: ByteArray, off: Int, len: Int) {
            digest.update(b, off, len)
            count += len
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
     * Copies [input] to [output], returning the byte count. When [digest] is
     * given, every byte also goes through it.
     */
    private fun copy(
        input: InputStream,
        output: OutputStream,
        digest: MessageDigest? = null
    ): Long {
        val buffer = ByteArray(BLOCK_SIZE)
        var total = 0L
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            if (read > 0) {
                output.write(buffer, 0, read)
                digest?.update(buffer, 0, read)
                total += read
            }
        }
        return total
    }

    /**
     * A file stream that syncs to the device when it is closed.
     *
     * Tink's encrypting stream writes its last segment inside `close()`, and
     * closes the stream under it, so the sync has to happen here.
     */
    private class SyncingFileOutputStream(file: File) : FileOutputStream(file) {
        private var closed = false

        override fun close() {
            if (closed) return
            closed = true
            try {
                flush()
                fd.sync()
            } finally {
                super.close()
            }
        }
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
            SecureOverwrite.overwriteFile(file, passes)
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
        private const val FILE_ID_LENGTH_BYTES = 16
        private const val DIGEST_ALGORITHM = "SHA-256"
        private const val PREVIEW_JPEG_QUALITY = 80

        /** Payload formats. Must match `AppConstants.vaultPayloadFormat*` in Dart. */
        private const val FORMAT_LEGACY = 1
        private const val FORMAT_STREAMING = 2

        /** Binds the sealed keyset file to its purpose. */
        private val KEYSET_ASSOCIATED_DATA =
            "imgvidgal-vault-data-keyset-v1".toByteArray(Charsets.UTF_8)

        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val ERROR_TAMPERED = "payload_tampered"
        private const val ERROR_VAULT_FAILED = "vault_failed"
    }
}
