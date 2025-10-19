package com.spiralgang.weblabs.utils

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.util.Locale

/**
 * Alpine Linux Manager
 * Manages Alpine Linux chroot environment and package operations
 */
class AlpineLinuxManager(
    private val context: Context,
    private val commandLauncher: CommandLauncher = ProotCommandLauncher()
) {

    companion object {
        const val TAG = "AlpineLinuxManager"
        const val ALPINE_DIR = "alpine"
    }

    val alpineRoot: File by lazy {
        File(context.filesDir, ALPINE_DIR)
    }

    fun isAlpineInstalled(): Boolean {
        val rootfsDir = File(alpineRoot, "rootfs")
        return rootfsDir.exists() &&
            rootfsDir.isDirectory &&
            File(rootfsDir, "bin/sh").exists() &&
            File(rootfsDir, "sbin/apk").exists()
    }

    suspend fun setupChrootEnvironment() = withContext(Dispatchers.IO) {
        Log.i(TAG, "Setting up chroot environment...")

        try {
            val rootfsDir = File(alpineRoot, "rootfs")
            val dirs = listOf("dev", "proc", "sys", "tmp", "var/tmp").map { File(rootfsDir, it) }
            dirs.forEach { dir ->
                if (!dir.exists()) {
                    dir.mkdirs()
                }
            }

            createChrootScript(rootfsDir)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup chroot environment", e)
            throw e
        }
    }

    private fun createChrootScript(rootfsDir: File) {
        val chrootScript = File(alpineRoot, "enter-chroot.sh")
        val script = """
            #!/system/bin/sh
            # WebLabs MobIDE Alpine Linux Rootfs Entry Script

            ROOTFS_DIR="${rootfsDir.absolutePath}"
            PROOT_BIN="$(command -v proot 2>/dev/null)"
            CHROOT_BIN="$(command -v chroot 2>/dev/null)"

            if [ -n "$PROOT_BIN" ]; then
              exec "$PROOT_BIN" -0 -r "$ROOTFS_DIR" \
                   -b /dev -b /proc -b /sys -w /root \
                   /bin/sh -lc "${'$'}@"
            elif [ -n "$CHROOT_BIN" ]; then
              exec "$CHROOT_BIN" "$ROOTFS_DIR" /bin/sh -lc "${'$'}@"
            else
              echo "Unable to locate proot or chroot on this device" >&2
              exit 1
            fi
        """.trimIndent()

        chrootScript.writeText(script)
        chrootScript.setExecutable(true)
    }

    fun executeCommand(command: String): String {
        if (!isAlpineInstalled()) {
            throw IllegalStateException("Alpine Linux is not installed")
        }

        val rootfsDir = File(alpineRoot, "rootfs")
        val environment = mapOf(
            "PATH" to "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
            "HOME" to "/root",
            "USER" to "developer",
            "SHELL" to "/bin/sh",
            "LANG" to Locale.getDefault().toLanguageTag()
        )

        return try {
            Log.d(TAG, "Executing command in Alpine: $command")
            val result = commandLauncher.launch(rootfsDir, command, environment)
            if (result.exitCode != 0) {
                val errorMessage = "Command failed with exit code ${result.exitCode}: ${result.stderr.trim()}"
                Log.e(TAG, errorMessage)
                throw IOException(errorMessage)
            }
            result.stdout.trimEnd()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to execute command: $command", e)
            throw e
        }
    }

    fun cleanup() {
        Log.i(TAG, "Cleaning up Alpine Linux manager...")
        // Additional cleanup hooks can be implemented if required
    }

    interface CommandLauncher {
        fun launch(rootfs: File, command: String, environment: Map<String, String>): CommandResult
    }

    data class CommandResult(val stdout: String, val stderr: String, val exitCode: Int)

    class ProotCommandLauncher : CommandLauncher {
        override fun launch(rootfs: File, command: String, environment: Map<String, String>): CommandResult {
            val rootfsShellCommand = listOf("/bin/sh", "-lc", command)
            val processArgs = resolveWrapper(rootfs)?.toMutableList()
                ?: fallbackDirectExecution(rootfs)

            processArgs.addAll(rootfsShellCommand)

            val processBuilder = ProcessBuilder(processArgs)
            processBuilder.directory(rootfs)
            val env = processBuilder.environment()
            env.putAll(environment)

            val process = processBuilder.start()
            val stdout = process.inputStream.bufferedReader().use { it.readText() }
            val stderr = process.errorStream.bufferedReader().use { it.readText() }
            val exitCode = process.waitFor()
            return CommandResult(stdout, stderr, exitCode)
        }

        private fun resolveWrapper(rootfs: File): List<String>? {
            val proot = findExecutable("proot")
            if (proot != null) {
                return listOf(
                    proot.absolutePath,
                    "-0",
                    "-r",
                    rootfs.absolutePath,
                    "-b",
                    "/dev",
                    "-b",
                    "/proc",
                    "-b",
                    "/sys",
                    "-w",
                    "/root"
                )
            }

            val chroot = findExecutable("chroot")
            if (chroot != null) {
                return listOf(chroot.absolutePath, rootfs.absolutePath)
            }

            return null
        }

        private fun fallbackDirectExecution(rootfs: File): MutableList<String> {
            val shell = File(rootfs, "bin/sh")
            if (!shell.exists()) {
                throw IllegalStateException("Unable to locate shell in rootfs")
            }
            Log.w(TAG, "Falling back to direct rootfs execution; proot/chroot not found")
            return mutableListOf(shell.absolutePath)
        }

        private fun findExecutable(name: String): File? {
            val searchPaths = System.getenv("PATH")?.split(":") ?: emptyList()
            val candidates = searchPaths.map { File(it, name) }
            return candidates.firstOrNull { it.exists() && it.canExecute() }
        }
    }
}
