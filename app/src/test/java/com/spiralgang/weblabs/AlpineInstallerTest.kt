package com.spiralgang.weblabs

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.apache.commons.compress.archivers.tar.TarArchiveEntry
import org.apache.commons.compress.archivers.tar.TarArchiveOutputStream
import org.apache.commons.compress.compressors.gzip.GzipCompressorOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.MessageDigest

@RunWith(RobolectricTestRunner::class)
class AlpineInstallerTest {

    private lateinit var context: Context
    private lateinit var installer: AlpineInstaller

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        File(context.filesDir, "alpine").deleteRecursively()
        installer = AlpineInstaller(context, TestRootfsFetcher(context))
    }

    @After
    fun tearDown() = runTest {
        installer.uninstallAlpine()
    }

    @Test
    fun installsRootfsWithEssentialBinaries() = runTest {
        val installed = installer.installAlpineLinux()
        assertTrue(installed)

        val rootfsDir = installer.getRootfsDirectory()
        assertTrue(File(rootfsDir, "bin/sh").exists())
        assertTrue(File(rootfsDir, "sbin/apk").exists())
        assertTrue(File(rootfsDir, ".weblabs_alpine_installed").exists())
    }

    private class TestRootfsFetcher(private val context: Context) : AlpineInstaller.RootfsFetcher {
        override suspend fun fetch(): AlpineInstaller.RootfsArtifact = withContext(Dispatchers.IO) {
            val archive = File.createTempFile("alpine-test-rootfs", ".tar.gz", context.cacheDir)
            val checksum = createTestRootfsArchive(archive)
            AlpineInstaller.RootfsArtifact(archive, checksum)
        }

        private fun createTestRootfsArchive(destination: File): String {
            FileOutputStream(destination).use { fileOut ->
                GzipCompressorOutputStream(fileOut).use { gzipOut ->
                    TarArchiveOutputStream(gzipOut).use { tarOut ->
                        tarOut.setLongFileMode(TarArchiveOutputStream.LONGFILE_POSIX)

                        addDirectory(tarOut, "bin")
                        addDirectory(tarOut, "sbin")
                        addDirectory(tarOut, "home")
                        addDirectory(tarOut, "home/developer")

                        addExecutableFile(tarOut, "bin/sh", "#!/bin/sh\nexit 0\n")
                        addExecutableFile(tarOut, "sbin/apk", "#!/bin/sh\necho apk\n")

                        tarOut.finish()
                    }
                }
            }

            return calculateSha256(destination)
        }

        private fun addDirectory(tarOut: TarArchiveOutputStream, path: String) {
            val entry = TarArchiveEntry("${path.trimEnd('/')}/")
            entry.mode = 0o755
            tarOut.putArchiveEntry(entry)
            tarOut.closeArchiveEntry()
        }

        private fun addExecutableFile(tarOut: TarArchiveOutputStream, path: String, contents: String) {
            val data = contents.toByteArray()
            val entry = TarArchiveEntry(path)
            entry.mode = 0o755
            entry.size = data.size.toLong()
            tarOut.putArchiveEntry(entry)
            tarOut.write(data)
            tarOut.closeArchiveEntry()
        }

        private fun calculateSha256(file: File): String {
            val digest = MessageDigest.getInstance("SHA-256")
            FileInputStream(file).use { input ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                var read = input.read(buffer)
                while (read != -1) {
                    digest.update(buffer, 0, read)
                    read = input.read(buffer)
                }
            }
            return digest.digest().joinToString(separator = "") { byte -> "%02x".format(byte) }
        }
    }
}
