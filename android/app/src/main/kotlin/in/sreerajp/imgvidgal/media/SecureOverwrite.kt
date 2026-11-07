package `in`.sreerajp.imgvidgal.media

import java.io.File
import java.io.FileDescriptor
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.security.SecureRandom

/**
 * Writes over a file's bytes so an ordinary undelete cannot bring them back.
 *
 * Passes alternate: zero, random, zero, ... Each pass is synced so the writes
 * reach the device rather than sitting in a buffer that is thrown away when
 * the file is removed. The file is truncated to zero at the end so its size
 * stops being a hint.
 *
 * Shared by the vault shredder and the gallery's secure delete, so both make
 * the same promise.
 *
 * **What this does not promise.** On flash storage the controller may write
 * each pass to a fresh block and keep the old contents where no file API can
 * reach. This defeats undelete tools and casual recovery; it is not a
 * guarantee against a laboratory.
 */
object SecureOverwrite {
    const val MIN_PASSES = 1
    const val MAX_PASSES = 5
    private const val BLOCK_SIZE = 64 * 1024

    private val secureRandom = SecureRandom()

    /** Overwrites [file] in place. Throws if the file cannot be written. */
    fun overwriteFile(file: File, passes: Int) {
        val length = file.length()
        if (length <= 0) return
        RandomAccessFile(file, "rws").use { raf ->
            val buffer = ByteArray(BLOCK_SIZE)
            for (pass in 0 until passes.coerceIn(MIN_PASSES, MAX_PASSES)) {
                fillPass(buffer, pass)
                raf.seek(0)
                writeLength(length) { chunk -> raf.write(buffer, 0, chunk) }
                raf.fd.sync()
            }
            raf.setLength(0)
            raf.fd.sync()
        }
    }

    /**
     * Overwrites the first [length] bytes behind [fd], then truncates it.
     *
     * Used for MediaStore content URIs, which give a file descriptor rather
     * than a path. Throws if the descriptor cannot be written.
     */
    fun overwriteDescriptor(fd: FileDescriptor, length: Long, passes: Int) {
        if (length <= 0) return
        // Not closed here: the descriptor belongs to the caller's
        // ParcelFileDescriptor, which closes it.
        val stream = FileOutputStream(fd)
        val channel = stream.channel
        val buffer = ByteArray(BLOCK_SIZE)
        for (pass in 0 until passes.coerceIn(MIN_PASSES, MAX_PASSES)) {
            fillPass(buffer, pass)
            channel.position(0)
            writeLength(length) { chunk -> stream.write(buffer, 0, chunk) }
            stream.flush()
            fd.sync()
        }
        channel.truncate(0)
        fd.sync()
    }

    private fun fillPass(buffer: ByteArray, pass: Int) {
        if (pass % 2 == 0) buffer.fill(0) else secureRandom.nextBytes(buffer)
    }

    private inline fun writeLength(length: Long, write: (Int) -> Unit) {
        var remaining = length
        while (remaining > 0) {
            val chunk = minOf(remaining, BLOCK_SIZE.toLong()).toInt()
            write(chunk)
            remaining -= chunk
        }
    }
}
