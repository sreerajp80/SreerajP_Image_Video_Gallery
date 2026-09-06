package `in`.sreerajp.imgvidgal.backup

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.security.SecureRandom
import java.util.concurrent.Executors
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

/**
 * Password-derived encryption for the `.gallerybak` archive, and the session
 * cipher the local transfer uses.
 *
 * This is deliberately not the vault's cipher. The vault's key lives inside
 * the Android Keystore and never leaves the device, which is exactly right
 * for a vault and exactly wrong for a backup: an archive that only the phone
 * that made it could open would be no use the day that phone is lost, which
 * is the day people reach for a backup.
 *
 * So the archive key is stretched from the user's password with
 * PBKDF2-HMAC-SHA256, over a random per-file salt, with the iteration count
 * written into the file. Nothing about the key is stored anywhere. Forget the
 * password and the archive is gone; the create dialog says so plainly.
 *
 * ### Why the header is authenticated rather than encrypted
 *
 * The salt and the iteration count have to be readable without the password,
 * because they are what the password is stretched with. They must not be
 * *changeable*: an attacker who could rewrite the iteration count down to one
 * would turn a strong password into a weak one. So the header bytes are
 * passed to AES-GCM as additional authenticated data. Alter one byte of the
 * magic, the version, the salt, the count or the IV, and the tag check fails
 * and the archive will not open at all.
 *
 * ### Why it streams
 *
 * A metadata archive is small, but "small" is a guess about someone else's
 * library. Both directions are pumped through in blocks, so the memory cost
 * is one buffer whatever the file turns out to be.
 *
 * Every call runs off the main thread and every failure comes back as a
 * channel error. A wrong password surfaces as [ERROR_WRONG_PASSWORD], not as
 * a crash, because a wrong password is the single most likely thing to happen
 * here and it is not an exceptional event.
 */
class BackupChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL_NAME).also {
        it.setMethodCallHandler(this)
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val secureRandom = SecureRandom()

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "randomBytes" -> runInBackground(result) { randomBytes(call) }
            "encryptArchive" -> runInBackground(result) { encryptArchive(call) }
            "decryptArchive" -> runInBackground(result) { decryptArchive(call) }
            "encryptWithKey" -> runInBackground(result) { encryptWithKey(call) }
            "decryptWithKey" -> runInBackground(result) { decryptWithKey(call) }
            else -> result.notImplemented()
        }
    }

    // ------------------------------------------------------------- randomness

    /**
     * Draws cryptographically strong random bytes.
     *
     * Used for the archive salt and IV and for the transfer session key. Dart
     * has no strong random source of its own worth trusting with a key, so it
     * asks the platform rather than improvising.
     */
    private fun randomBytes(call: MethodCall): ByteArray {
        val length = call.argument<Int>("length")
            ?: throw IllegalArgumentException("length is required")
        if (length <= 0 || length > MAX_RANDOM_BYTES) {
            throw IllegalArgumentException("length is out of range")
        }
        return ByteArray(length).also { secureRandom.nextBytes(it) }
    }

    // ---------------------------------------------------------------- archive

    /**
     * Writes `sourcePath` into `destUri` as an encrypted archive.
     *
     * The caller has already built the header bytes and passes them in. They
     * are written to the file in the clear and fed to the cipher as
     * additional authenticated data, so the file is self-describing and the
     * description cannot be edited.
     */
    private fun encryptArchive(call: MethodCall): Map<String, Any> {
        val sourcePath = call.argument<String>("sourcePath")
            ?: throw IllegalArgumentException("sourcePath is required")
        val destUri = call.argument<String>("destUri")
            ?: throw IllegalArgumentException("destUri is required")
        val header = call.argument<ByteArray>("header")
            ?: throw IllegalArgumentException("header is required")
        val password = call.argument<String>("password")
            ?: throw IllegalArgumentException("password is required")
        val salt = call.argument<ByteArray>("salt")
            ?: throw IllegalArgumentException("salt is required")
        val iv = call.argument<ByteArray>("iv")
            ?: throw IllegalArgumentException("iv is required")
        val iterations = call.argument<Int>("iterations")
            ?: throw IllegalArgumentException("iterations is required")

        val source = File(sourcePath)
        if (!source.isFile) {
            throw IllegalArgumentException("source is not a file")
        }

        val key = deriveKey(password, salt, iterations)
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(TAG_LENGTH_BITS, iv))
            updateAAD(header)
        }

        var written = 0L
        try {
            openOutput(destUri).use { output ->
                // The header goes out in the clear, ahead of the ciphertext.
                output.write(header)
                source.inputStream().use { input ->
                    written = pumpThroughCipher(input, output, cipher)
                }
                output.flush()
            }
        } catch (error: Exception) {
            // A half-written archive would fail its tag check later and look
            // like tampering rather than like the interrupted write it was.
            runCatching { context.contentResolver.delete(Uri.parse(destUri), null, null) }
            throw error
        } finally {
            zero(key)
        }

        return mapOf(
            "headerBytes" to header.size,
            "cipherBytes" to written
        )
    }

    /**
     * Reads `sourceUri` back out to `destPath`.
     *
     * The header has already been read and parsed in Dart, which is why the
     * salt, the count and the IV arrive as arguments: this side does not
     * re-parse a format the pure Dart layer already owns and tests.
     *
     * `headerBytes` says how many bytes to skip before the ciphertext starts,
     * and those same bytes are fed back in as additional authenticated data.
     */
    private fun decryptArchive(call: MethodCall): Map<String, Any> {
        val sourceUri = call.argument<String>("sourceUri")
            ?: throw IllegalArgumentException("sourceUri is required")
        val destPath = call.argument<String>("destPath")
            ?: throw IllegalArgumentException("destPath is required")
        val header = call.argument<ByteArray>("header")
            ?: throw IllegalArgumentException("header is required")
        val password = call.argument<String>("password")
            ?: throw IllegalArgumentException("password is required")
        val salt = call.argument<ByteArray>("salt")
            ?: throw IllegalArgumentException("salt is required")
        val iv = call.argument<ByteArray>("iv")
            ?: throw IllegalArgumentException("iv is required")
        val iterations = call.argument<Int>("iterations")
            ?: throw IllegalArgumentException("iterations is required")

        val key = deriveKey(password, salt, iterations)
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(TAG_LENGTH_BITS, iv))
            updateAAD(header)
        }

        val destination = File(destPath)
        destination.parentFile?.mkdirs()

        var written = 0L
        try {
            openInput(sourceUri).use { input ->
                if (input == null) {
                    throw IllegalArgumentException("could not open the archive")
                }
                // Step over the plaintext header; it is authenticated, not
                // enciphered, so it must not go through the cipher.
                skipFully(input, header.size.toLong())
                FileOutputStream(destination).use { output ->
                    written = pumpThroughCipher(input, output, cipher)
                    output.flush()
                    output.fd.sync()
                }
            }
        } catch (error: Exception) {
            // A partial plaintext is worse than none: a restore reading it
            // would see a truncated archive as a valid, emptier one.
            destination.delete()
            throw error
        } finally {
            zero(key)
        }

        return mapOf("plainBytes" to written)
    }

    // --------------------------------------------------------- session cipher

    /**
     * Encrypts bytes under a key that is already agreed.
     *
     * Used by the local transfer, where the key came off the pairing QR code
     * rather than out of a password. It is here rather than in its own
     * handler so that every AES operation in the app lives in one of two
     * files, and both of them are ones a reviewer will think to look at.
     */
    private fun encryptWithKey(call: MethodCall): Map<String, Any> {
        val keyBytes = call.argument<ByteArray>("key")
            ?: throw IllegalArgumentException("key is required")
        val plain = call.argument<ByteArray>("bytes")
            ?: throw IllegalArgumentException("bytes is required")
        val iv = call.argument<ByteArray>("iv")
            ?: throw IllegalArgumentException("iv is required")
        val aad = call.argument<ByteArray>("aad")

        requireKeySize(keyBytes)

        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(
                Cipher.ENCRYPT_MODE,
                SecretKeySpec(keyBytes, ALGORITHM),
                GCMParameterSpec(TAG_LENGTH_BITS, iv)
            )
            if (aad != null) updateAAD(aad)
        }
        return mapOf("bytes" to cipher.doFinal(plain))
    }

    private fun decryptWithKey(call: MethodCall): Map<String, Any> {
        val keyBytes = call.argument<ByteArray>("key")
            ?: throw IllegalArgumentException("key is required")
        val cipherBytes = call.argument<ByteArray>("bytes")
            ?: throw IllegalArgumentException("bytes is required")
        val iv = call.argument<ByteArray>("iv")
            ?: throw IllegalArgumentException("iv is required")
        val aad = call.argument<ByteArray>("aad")

        requireKeySize(keyBytes)

        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(
                Cipher.DECRYPT_MODE,
                SecretKeySpec(keyBytes, ALGORITHM),
                GCMParameterSpec(TAG_LENGTH_BITS, iv)
            )
            if (aad != null) updateAAD(aad)
        }
        return mapOf("bytes" to cipher.doFinal(cipherBytes))
    }

    // ------------------------------------------------------------------- keys

    /**
     * Stretches a password into an AES-256 key.
     *
     * PBKDF2-HMAC-SHA256, matching the vault's PIN hashing, so the app has one
     * key-derivation story rather than two. The iteration count comes from the
     * caller and is written into the archive, so a file made before the
     * constant changed still opens afterwards.
     *
     * The intermediate `PBEKeySpec` is cleared as soon as the key is out of
     * it; the password `String` itself cannot be, which is a limitation of the
     * platform API and not something to pretend otherwise about.
     */
    private fun deriveKey(password: String, salt: ByteArray, iterations: Int): SecretKey {
        if (salt.isEmpty()) throw IllegalArgumentException("salt is empty")
        if (iterations < MIN_ITERATIONS || iterations > MAX_ITERATIONS) {
            throw IllegalArgumentException("iteration count is out of range")
        }

        val spec = PBEKeySpec(password.toCharArray(), salt, iterations, KEY_SIZE_BITS)
        try {
            val factory = SecretKeyFactory.getInstance(KDF_ALGORITHM)
            return SecretKeySpec(factory.generateSecret(spec).encoded, ALGORITHM)
        } finally {
            spec.clearPassword()
        }
    }

    private fun requireKeySize(key: ByteArray) {
        if (key.size != KEY_SIZE_BITS / 8) {
            throw IllegalArgumentException("key must be ${KEY_SIZE_BITS / 8} bytes")
        }
    }

    /** Overwrites a derived key so it does not sit in the heap afterwards. */
    private fun zero(key: SecretKey) {
        runCatching { key.encoded?.fill(0) }
    }

    // --------------------------------------------------------------- plumbing

    private fun openInput(uri: String): InputStream? =
        if (uri.startsWith("content://")) {
            context.contentResolver.openInputStream(Uri.parse(uri))
        } else {
            File(uri).inputStream()
        }

    private fun openOutput(uri: String): OutputStream =
        if (uri.startsWith("content://")) {
            context.contentResolver.openOutputStream(Uri.parse(uri), "wt")
                ?: throw IllegalArgumentException("could not open the destination")
        } else {
            FileOutputStream(File(uri))
        }

    /**
     * Skips exactly [count] bytes.
     *
     * `InputStream.skip` may do less than asked and reports how much it did,
     * so it is looped. Getting this wrong would misalign the ciphertext by a
     * few bytes and produce a tag failure that looked like a wrong password.
     */
    private fun skipFully(input: InputStream, count: Long) {
        var remaining = count
        while (remaining > 0) {
            val skipped = input.skip(remaining)
            if (skipped <= 0) {
                if (input.read() < 0) {
                    throw IllegalArgumentException("the archive is truncated")
                }
                remaining--
            } else {
                remaining -= skipped
            }
        }
    }

    private fun pumpThroughCipher(
        input: InputStream,
        output: OutputStream,
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
        // doFinal appends the GCM tag when encrypting, and checks it when
        // decrypting. On decrypt this is where a wrong password shows up.
        cipher.doFinal()?.let {
            output.write(it)
            written += it.size
        }
        return written
    }

    /**
     * Runs [block] off the main thread and answers on it.
     *
     * A failed tag becomes [ERROR_WRONG_PASSWORD] rather than a generic
     * failure, because with GCM the two are indistinguishable from the inside
     * and the wrong password is overwhelmingly the likelier of the two. The
     * message says both, so nobody is told their file is fine when it is not.
     *
     * No file name or path goes into an error: those get logged, and where
     * somebody keeps their photos is not something to write to logcat.
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
                    is AEADBadTagException -> ERROR_WRONG_PASSWORD
                    is IllegalArgumentException -> ERROR_INVALID_ARGUMENTS
                    else -> ERROR_BACKUP_FAILED
                }
                mainHandler.post {
                    result.error(code, error.javaClass.simpleName, null)
                }
            }
        }
    }

    companion object {
        private const val CHANNEL_NAME = "in.sreerajp.imgvidgal/backup"

        private const val ALGORITHM = "AES"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val KDF_ALGORITHM = "PBKDF2WithHmacSHA256"
        private const val KEY_SIZE_BITS = 256
        private const val TAG_LENGTH_BITS = 128
        private const val BLOCK_SIZE = 64 * 1024

        /** Guards against a caller asking for an absurd derivation cost. */
        private const val MIN_ITERATIONS = 1_000
        private const val MAX_ITERATIONS = 2_000_000

        private const val MAX_RANDOM_BYTES = 1024

        private const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        private const val ERROR_WRONG_PASSWORD = "wrong_password"
        private const val ERROR_BACKUP_FAILED = "backup_failed"
    }
}
