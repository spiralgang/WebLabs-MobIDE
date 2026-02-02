package com.spiralgang.weblabs.services

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.util.Log
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.BufferedWriter
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.io.OutputStreamWriter
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Shell Terminal Service
 * Manages shell sessions and command execution within Alpine Linux environment
 */
class ShellTerminalService : Service() {
    
    companion object {
        const val TAG = "ShellTerminalService"
        private const val DEFAULT_HOME = "/home/developer"
        private const val CWD_STATE_FILE = ".weblabs_cwd"
        private const val ENV_BOOTSTRAP_FILE = ".weblabs_env.sh"
    }

    private val binder = LocalBinder()
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val commandHistory = ConcurrentLinkedQueue<String>()
    private val terminalEvents = MutableSharedFlow<TerminalEvent>(
        extraBufferCapacity = 128,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    private val inputMutex = Mutex()
    private var shellProcess: Process? = null
    private var stdinWriter: BufferedWriter? = null
    private var stdoutJob: Job? = null
    private var stderrJob: Job? = null
    private var processWatcherJob: Job? = null
    
    inner class LocalBinder : Binder() {
        fun getService(): ShellTerminalService = this@ShellTerminalService
    }
    
    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Shell Terminal Service created")
    }
    
    override fun onDestroy() {
        cleanupShell()
        super.onDestroy()
        serviceScope.cancel()
        Log.i(TAG, "Shell Terminal Service destroyed")
    }

    fun startShell() {
        if (shellProcess?.isAlive == true) {
            Log.i(TAG, "Shell session already running")
            return
        }

        serviceScope.launch {
            Log.i(TAG, "Starting shell session...")
            try {
                startShellInternal()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start shell session", e)
                emitEvent(TerminalEvent.Error("Failed to start shell: ${'$'}{e.message}"))
            }
        }
    }

    fun executeCommand(command: String): String {
        Log.d(TAG, "Queueing command for shell: $command")

        return if (shellProcess?.isAlive != true) {
            Log.w(TAG, "Shell is not running; starting a new session")
            startShell()
            queueCommand(command)
            "Shell starting, command queued"
        } else {
            queueCommand(command)
            "Command sent to shell"
        }
    }

    fun observeTerminal(): SharedFlow<TerminalEvent> = terminalEvents.asSharedFlow()

    fun stopShell() {
        serviceScope.launch {
            try {
                if (shellProcess?.isAlive == true) {
                    emitEvent(TerminalEvent.Status("Stopping shell session"))
                    inputMutex.withLock {
                        stdinWriter?.apply {
                            write("exit\n")
                            flush()
                        }
                    }
                    shellProcess?.waitFor()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop shell gracefully", e)
                shellProcess?.destroy()
            } finally {
                cleanupShell()
            }
        }
    }

    fun getCommandHistory(): String {
        return commandHistory.joinToString("\n")
    }

    fun getCurrentDirectory(): String {
        val rootfs = resolveRootfs()
        return readPersistedDirectory(rootfs)
    }

    fun isShellRunning(): Boolean = shellProcess?.isAlive == true

    private suspend fun startShellInternal() {
        val filesDir = applicationContext.filesDir
        val prootBinary = File(filesDir, "proot")
        val rootfs = resolveRootfs()

        if (!prootBinary.exists() || !prootBinary.canExecute()) {
            val message = "PRoot binary not found at ${prootBinary.absolutePath}"
            Log.e(TAG, message)
            emitEvent(TerminalEvent.Error(message))
            return
        }

        if (!rootfs.exists()) {
            val message = "Alpine rootfs not found at ${rootfs.absolutePath}"
            Log.e(TAG, message)
            emitEvent(TerminalEvent.Error(message))
            return
        }

        val initialDirectory = prepareWorkingDirectory(rootfs)
        val envBootstrap = ensureBootstrapScript(rootfs, initialDirectory)

        val command = mutableListOf(
            prootBinary.absolutePath,
            "--rootfs=${rootfs.absolutePath}",
            "--bind=/proc",
            "--bind=/sys",
            "--bind=/dev"
        )

        val alpineHostDir = File(filesDir, "alpine")
        if (alpineHostDir.exists()) {
            command.add("--bind=${alpineHostDir.absolutePath}:${alpineHostDir.absolutePath}")
        }

        command.addAll(
            listOf(
                "--working-directory=$initialDirectory",
                "--change-id=1000:1000",
                "/bin/sh",
                "-il"
            )
        )

        val processBuilder = ProcessBuilder(command)
        processBuilder.directory(rootfs)
        processBuilder.redirectErrorStream(false)

        val environment = processBuilder.environment()
        environment["HOME"] = DEFAULT_HOME
        environment["USER"] = "developer"
        environment["SHELL"] = "/bin/sh"
        environment["TERM"] = "xterm-256color"
        environment["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        environment["LANG"] = "en_US.UTF-8"
        environment["ENV"] = envBootstrap

        cleanupShell()

        val process = processBuilder.start()
        shellProcess = process
        stdinWriter = BufferedWriter(OutputStreamWriter(process.outputStream))

        stdoutJob = serviceScope.launch { pumpStream(process.inputStream, TerminalStream.STDOUT) }
        stderrJob = serviceScope.launch { pumpStream(process.errorStream, TerminalStream.STDERR) }
        processWatcherJob = serviceScope.launch {
            val exitCode = process.waitFor()
            emitEvent(TerminalEvent.Exit(exitCode))
            cleanupShell()
        }

        emitEvent(TerminalEvent.Status("Shell session started (cwd: $initialDirectory)"))
    }

    private fun resolveRootfs(): File {
        val alpineDir = File(applicationContext.filesDir, "alpine")
        val rootfs = File(alpineDir, "rootfs")
        return if (rootfs.exists()) rootfs else alpineDir
    }

    private fun prepareWorkingDirectory(rootfs: File): String {
        val homeDir = File(rootfs, DEFAULT_HOME.trimStart('/'))
        if (!homeDir.exists()) {
            homeDir.mkdirs()
        }

        val cwdFile = File(homeDir, CWD_STATE_FILE)
        if (!cwdFile.exists()) {
            try {
                cwdFile.writeText(DEFAULT_HOME)
            } catch (e: IOException) {
                Log.w(TAG, "Unable to create default cwd file", e)
            }
        }

        return readPersistedDirectory(rootfs)
    }

    private fun ensureBootstrapScript(rootfs: File, initialDirectory: String): String {
        val homeDir = File(rootfs, DEFAULT_HOME.trimStart('/'))
        val scriptFile = File(homeDir, ENV_BOOTSTRAP_FILE)
        val script = """
            # WebLabs MobIDE shell bootstrap
            if [ -f "${'$'}HOME/$CWD_STATE_FILE" ]; then
                target=${'$'}(cat "${'$'}HOME/$CWD_STATE_FILE" 2>/dev/null)
                if [ -d "${'$'}target" ]; then
                    cd "${'$'}target"
                else
                    cd "$initialDirectory"
                fi
            else
                echo "$initialDirectory" > "${'$'}HOME/$CWD_STATE_FILE"
                cd "$initialDirectory"
            fi

            weblabs_update_cwd() {
                pwd > "${'$'}HOME/$CWD_STATE_FILE"
            }
            PROMPT_COMMAND="weblabs_update_cwd"
        """.trimIndent()

        try {
            scriptFile.writeText(script)
        } catch (e: IOException) {
            Log.e(TAG, "Failed to write bootstrap script", e)
        }

        return scriptFile.absolutePath
    }

    private suspend fun pumpStream(stream: InputStream, streamType: TerminalStream) {
        val buffer = ByteArray(4096)
        try {
            while (isActive) {
                val read = withContext(Dispatchers.IO) { stream.read(buffer) }
                if (read == -1) break
                if (read > 0) {
                    val text = String(buffer, 0, read)
                    emitEvent(TerminalEvent.Output(streamType, text))
                }
            }
        } catch (e: IOException) {
            if (shellProcess?.isAlive == true) {
                Log.e(TAG, "Error reading ${streamType.name.lowercase()} stream", e)
                emitEvent(TerminalEvent.Error("IO error: ${'$'}{e.message}"))
            }
        }
    }

    private fun cleanupShell() {
        stdoutJob?.cancel()
        stderrJob?.cancel()
        processWatcherJob?.cancel()
        stdoutJob = null
        stderrJob = null
        processWatcherJob = null

        try {
            stdinWriter?.close()
        } catch (ignored: IOException) {
        }
        stdinWriter = null

        shellProcess?.let {
            if (it.isAlive) {
                it.destroy()
            }
        }
        shellProcess = null
    }

    private fun readPersistedDirectory(rootfs: File): String {
        val candidate = try {
            val cwdFile = File(rootfs, "${DEFAULT_HOME.trimStart('/')}/$CWD_STATE_FILE")
            if (cwdFile.exists()) cwdFile.readText().trim() else null
        } catch (e: IOException) {
            Log.w(TAG, "Unable to read cwd file", e)
            null
        }

        val directory = candidate?.takeIf { it.isNotEmpty() } ?: DEFAULT_HOME
        val resolved = File(rootfs, directory.trimStart('/'))
        return if (resolved.exists() && resolved.isDirectory) directory else DEFAULT_HOME
    }

    private fun queueCommand(command: String) {
        commandHistory.offer(command)
        if (commandHistory.size > 100) {
            commandHistory.poll()
        }

        serviceScope.launch {
            try {
                var writer = stdinWriter
                var attempts = 0
                while (writer == null && attempts < 50) {
                    delay(100)
                    writer = stdinWriter
                    attempts++
                }

                if (writer == null) {
                    throw IllegalStateException("Shell is not running")
                }

                val safeWriter = writer!!
                inputMutex.withLock {
                    safeWriter.write(command)
                    if (!command.endsWith('\n')) {
                        safeWriter.write('\n'.code)
                    }
                    safeWriter.flush()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send command to shell", e)
                emitEvent(TerminalEvent.Error("Failed to send command: ${'$'}{e.message}"))
            }
        }
    }

    private suspend fun emitEvent(event: TerminalEvent) {
        terminalEvents.emit(event)
    }

    sealed class TerminalEvent {
        data class Output(val stream: TerminalStream, val text: String) : TerminalEvent()
        data class Error(val message: String) : TerminalEvent()
        data class Status(val message: String) : TerminalEvent()
        data class Exit(val exitCode: Int) : TerminalEvent()
    }

    enum class TerminalStream {
        STDOUT,
        STDERR
    }
}
