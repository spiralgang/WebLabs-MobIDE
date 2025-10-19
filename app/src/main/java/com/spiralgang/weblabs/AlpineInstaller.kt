package com.spiralgang.weblabs

import android.content.Context
import android.system.ErrnoException
import android.system.Os
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.ResponseBody
import org.apache.commons.compress.archivers.tar.TarArchiveEntry
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest
import java.util.concurrent.TimeUnit

/**
 * AlpineInstaller - Alpine Linux ARM64 Installation and Management
 *
 * Handles the download, installation, and configuration of Alpine Linux ARM64 rootfs
 * for the mobile development environment. Provides secure, production-ready
 * Alpine Linux integration for Android 10+ ARM64 devices.
 */
class AlpineInstaller(
    private val context: Context,
    private val rootfsFetcher: RootfsFetcher = HttpRootfsFetcher(
        context,
        ROOTFS_URL,
        ROOTFS_SHA256_URL
    )
) {

    companion object {
        private const val TAG = "AlpineInstaller"
        private const val ALPINE_VERSION = "3.19"
        private const val ALPINE_ARCH = "aarch64"
        private const val ROOTFS_URL = "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/alpine-minirootfs-${ALPINE_VERSION}.0-${ALPINE_ARCH}.tar.gz"
        private const val ROOTFS_SHA256_URL = "$ROOTFS_URL.sha256"
        private const val DOWNLOAD_TIMEOUT_SECONDS = 120L
    }

    private val alpineDir = File(context.filesDir, "alpine")
    private val rootfsDir = File(alpineDir, "rootfs")

    /**
     * Install Alpine Linux ARM64 rootfs for mobile development
     */
    suspend fun installAlpineLinux(): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "Starting Alpine Linux ARM64 installation...")

            alpineDir.mkdirs()

            if (isAlpineInstalled()) {
                Log.i(TAG, "Alpine Linux already installed")
                return@withContext true
            }

            val artifact = downloadRootfs() ?: return@withContext false

            val installationSucceeded = try {
                extractRootfs(artifact.archive)
                configureAlpine()
            } catch (e: Exception) {
                Log.e(TAG, "Installation failed", e)
                cleanupPartialInstall()
                false
            } finally {
                artifact.archive.deleteSafely()
            }

            if (installationSucceeded) {
                Log.i(TAG, "Alpine Linux ARM64 installation completed successfully")
                return@withContext true
            }

            Log.e(TAG, "Alpine Linux installation failed")
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error installing Alpine Linux", e)
            cleanupPartialInstall()
            false
        }
    }

    /**
     * Check if Alpine Linux is properly installed
     */
    fun isAlpineInstalled(): Boolean {
        val markerFile = File(rootfsDir, ".weblabs_alpine_installed")
        return markerFile.exists() && File(rootfsDir, "bin/sh").exists()
    }

    /**
     * Get Alpine Linux rootfs directory
     */
    fun getRootfsDirectory(): File = rootfsDir

    /**
     * Get Alpine Linux installation directory
     */
    fun getAlpineDirectory(): File = alpineDir

    private suspend fun downloadRootfs(): RootfsArtifact? = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "Downloading Alpine Linux rootfs from official mirror")
            val artifact = rootfsFetcher.fetch()
            verifyChecksum(artifact)
            artifact
        } catch (e: Exception) {
            Log.e(TAG, "Error downloading rootfs", e)
            null
        }
    }

    private fun extractRootfs(archive: File) {
        if (rootfsDir.exists()) {
            rootfsDir.deleteRecursively()
        }
        rootfsDir.mkdirs()

        FileInputStream(archive).use { fileInput ->
            GzipCompressorInputStream(fileInput).use { gzipStream ->
                TarArchiveInputStream(gzipStream).use { tarStream ->
                    var entry: TarArchiveEntry? = tarStream.nextTarEntry
                    while (entry != null) {
                        extractEntry(entry, tarStream)
                        entry = tarStream.nextTarEntry
                    }
                }
            }
        }

        Log.i(TAG, "Rootfs extraction completed")
    }

    private fun configureAlpine(): Boolean {
        return try {
            val homeDir = File(rootfsDir, "home/developer")
            if (!homeDir.exists()) {
                homeDir.mkdirs()
            }

            setupDevelopmentEnvironment()
            copyBootstrapScript()

            val markerFile = File(rootfsDir, ".weblabs_alpine_installed")
            markerFile.createNewFile()

            Log.i(TAG, "Alpine Linux configuration completed")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error configuring Alpine Linux", e)
            false
        }
    }

    private fun setupDevelopmentEnvironment() {
        try {
            val webLabsDir = File(rootfsDir, "home/developer/weblabs")
            webLabsDir.mkdirs()

            File(webLabsDir, "projects").mkdirs()
            File(webLabsDir, "scripts").mkdirs()
            File(webLabsDir, "ai").mkdirs()

            Log.i(TAG, "Development environment setup completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up development environment", e)
            throw e
        }
    }

    private fun copyBootstrapScript() {
        val bootstrapScript = File(alpineDir, "bootstrap.sh")
        context.assets.open("alpine/bootstrap.sh").use { input ->
            FileOutputStream(bootstrapScript).use { output ->
                input.copyTo(output)
            }
        }
        bootstrapScript.setExecutable(true)
    }

    private fun extractEntry(entry: TarArchiveEntry, tarStream: TarArchiveInputStream) {
        val target = File(rootfsDir, entry.name)
        ensureWithinRootfs(target)

        if (entry.isDirectory) {
            if (!target.exists() && !target.mkdirs()) {
                throw IOException("Failed to create directory ${target.absolutePath}")
            }
            return
        }

        if (entry.isSymbolicLink) {
            target.parentFile?.let { parent ->
                if (!parent.exists() && !parent.mkdirs()) {
                    throw IOException("Failed to create parent directory for symlink ${parent.absolutePath}")
                }
            }
            try {
                Os.symlink(entry.linkName, target.absolutePath)
            } catch (e: ErrnoException) {
                throw IOException("Failed to create symlink ${target.absolutePath} -> ${entry.linkName}", e)
            }
            return
        }

        if (entry.isLink) {
            val linkTarget = File(rootfsDir, entry.linkName)
            ensureWithinRootfs(linkTarget)
            if (!linkTarget.exists()) {
                throw IOException("Hard link target missing: ${entry.linkName}")
            }
            linkTarget.inputStream().use { input ->
                FileOutputStream(target).use { output ->
                    input.copyTo(output)
                }
            }
            return
        }

        target.parentFile?.let { parent ->
            if (!parent.exists() && !parent.mkdirs()) {
                throw IOException("Failed to create parent directory ${parent.absolutePath}")
            }
        }

        FileOutputStream(target).use { output ->
            tarStream.copyTo(output)
        }

        if (entry.mode and 0b001_000_000 != 0) {
            target.setExecutable(true, false)
        }
        if (entry.mode and 0b000_100_000 != 0) {
            target.setReadable(true, false)
        }
        if (entry.mode and 0b000_010_000 != 0) {
            target.setWritable(true, false)
        }
    }

    private fun ensureWithinRootfs(target: File) {
        val rootfsPath = rootfsDir.canonicalPath
        val targetPath = target.canonicalPath
        if (targetPath != rootfsPath && !targetPath.startsWith(rootfsPath + File.separator)) {
            throw IOException("Attempted path traversal outside rootfs: ${target.path}")
        }
    }

    private fun verifyChecksum(artifact: RootfsArtifact) {
        val expected = artifact.checksum?.lowercase()
            ?: throw IllegalStateException("Missing checksum for Alpine rootfs download")

        val actual = artifact.archive.inputStream().use { stream ->
            val digest = MessageDigest.getInstance("SHA-256")
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            var read = stream.read(buffer)
            while (read != -1) {
                digest.update(buffer, 0, read)
                read = stream.read(buffer)
            }
            digest.digest().joinToString(separator = "") { byte -> "%02x".format(byte) }
        }

        if (actual != expected) {
            throw SecurityException("Rootfs checksum mismatch. Expected $expected, got $actual")
        }
    }

    private fun cleanupPartialInstall() {
        if (rootfsDir.exists()) {
            rootfsDir.deleteRecursively()
        }
        val bootstrapScript = File(alpineDir, "bootstrap.sh")
        if (bootstrapScript.exists() && !bootstrapScript.delete()) {
            Log.w(TAG, "Failed to delete bootstrap script during cleanup")
        }
    }

    suspend fun uninstallAlpine(): Boolean = withContext(Dispatchers.IO) {
        try {
            if (alpineDir.exists()) {
                alpineDir.deleteRecursively()
                Log.i(TAG, "Alpine Linux uninstalled successfully")
                return@withContext true
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error uninstalling Alpine Linux", e)
            false
        }
    }

    private fun File.deleteSafely() {
        if (exists() && !delete()) {
            Log.w(TAG, "Unable to delete temporary file: $absolutePath")
        }
    }

    interface RootfsFetcher {
        suspend fun fetch(): RootfsArtifact
    }

    data class RootfsArtifact(val archive: File, val checksum: String?)

    private class HttpRootfsFetcher(
        private val context: Context,
        private val rootfsUrl: String,
        private val checksumUrl: String,
        private val client: OkHttpClient = OkHttpClient.Builder()
            .connectTimeout(DOWNLOAD_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(DOWNLOAD_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .build()
    ) : RootfsFetcher {

        override suspend fun fetch(): RootfsArtifact = withContext(Dispatchers.IO) {
            val archive = File.createTempFile("alpine-rootfs", ".tar.gz", context.cacheDir)
            try {
                downloadToFile(rootfsUrl, archive)
                val checksum = downloadChecksum(checksumUrl)
                RootfsArtifact(archive, checksum)
            } catch (e: Exception) {
                archive.delete()
                throw e
            }
        }

        private fun downloadToFile(url: String, destination: File) {
            val request = Request.Builder().url(url).build()
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Failed to download rootfs: ${response.code}")
                }
                val body: ResponseBody = response.body ?: throw IOException("Empty response body")
                body.byteStream().use { input ->
                    FileOutputStream(destination).use { output ->
                        input.copyTo(output)
                    }
                }
            }
        }

        private fun downloadChecksum(url: String): String {
            val request = Request.Builder().url(url).build()
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Failed to download checksum: ${response.code}")
                }
                val body = response.body?.string()?.trim()
                    ?: throw IOException("Empty checksum response")
                return body.split(" ").firstOrNull()?.trim()?.lowercase()
                    ?: throw IOException("Invalid checksum format")
            }
        }
    }
}
