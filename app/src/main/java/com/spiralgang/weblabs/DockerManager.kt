package com.spiralgang.weblabs

import android.content.Context
import android.util.Log
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import java.io.*
import java.net.HttpURLConnection
import java.net.URL

/**
 * DockerManager - Android Virtualization Environment Manager
 *
 * Manages the Termux + proot-distro based Ubuntu development environment for
 * WebLabs-MobIDE. The class used to orchestrate Docker but now targets the
 * lightweight userspace virtualization layer that actually works on Android
 * devices without privileged access.
 *
 * Features:
 * - Ubuntu userspace provided by proot-distro
 * - Code-Server web IDE at localhost:8080
 * - Workspace sharing with the Android app sandbox
 * - Telemetry stream so the UI can surface virtualization errors
 */
class DockerManager(private val context: Context) {

    companion object {
        const val TAG = "DockerManager"
        const val DISTRO_ALIAS = "weblabs-mobide"
        const val DISTRO_BASE = "ubuntu"
        const val IDE_PORT = 8080
        const val WORKSPACE_DIR = "/root/workspace"
        private const val START_SCRIPT = "/usr/local/bin/weblabs-start.sh"
        private const val PID_FILE = "/tmp/weblabs-code-server.pid"
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val telemetryFlow = MutableSharedFlow<VirtualizationEvent>(replay = 0, extraBufferCapacity = 16)
    private var activeDistroAlias: String? = null
    private val workspaceDir = File(context.filesDir, "workspace")

    sealed class VirtualizationEvent(val message: String, val throwable: Throwable? = null) {
        class Info(message: String) : VirtualizationEvent(message)
        class Warning(message: String) : VirtualizationEvent(message)
        class Error(message: String, throwable: Throwable? = null) : VirtualizationEvent(message, throwable)
    }

    val telemetry: SharedFlow<VirtualizationEvent> = telemetryFlow.asSharedFlow()

    /**
     * Initialize Docker environment
     */
    suspend fun initializeDocker(): Boolean = withContext(Dispatchers.IO) {
        try {
            emitTelemetry(VirtualizationEvent.Info("Initializing Android virtualization environment"))

            if (!isVirtualizationAvailable()) {
                emitTelemetry(VirtualizationEvent.Error("proot-distro not available on PATH. Install Termux + proot-distro."))
                emitTelemetry(VirtualizationEvent.Warning("Falling back to local environment"))
                return@withContext setupLocalEnvironment()
            }

            if (!ensureDistro()) {
                emitTelemetry(VirtualizationEvent.Error("Failed to provision virtualization distro"))
                return@withContext false
            }

            if (!provisionDistro()) {
                emitTelemetry(VirtualizationEvent.Error("Failed to configure virtualization distro"))
                return@withContext false
            }

            if (!startVirtualInstance()) {
                emitTelemetry(VirtualizationEvent.Error("Failed to start virtualized IDE"))
                return@withContext false
            }

            // Verify IDE is accessible
            if (!waitForIDE()) {
                emitTelemetry(VirtualizationEvent.Error("IDE not reachable after virtualization start"))
                return@withContext false
            }

            emitTelemetry(VirtualizationEvent.Info("Virtual environment ready at http://localhost:$IDE_PORT"))
            true
        } catch (e: Exception) {
            emitTelemetry(VirtualizationEvent.Error("Failed to initialize virtualization environment", e))
            false
        }
    }

    /**
     * Check if proot-distro virtualization is available on the system
     */
    private suspend fun isVirtualizationAvailable(): Boolean = withContext(Dispatchers.IO) {
        try {
            val result = executeHostCommand(listOf("which", "proot-distro"))
            result.exitCode == 0
        } catch (e: Exception) {
            Log.w(TAG, "Virtualization not available: ${e.message}")
            false
        }
    }

    /**
     * Ensure the distro we need exists (installing it when missing)
     */
    private suspend fun ensureDistro(): Boolean {
        val aliases = getInstalledAliases()
        activeDistroAlias = aliases.firstOrNull { it == DISTRO_ALIAS }
            ?: aliases.firstOrNull { it.contains("weblabs") }

        if (activeDistroAlias != null) {
            return true
        }

        val installedAlias = installDistro()
        if (installedAlias != null) {
            activeDistroAlias = installedAlias
            return true
        }

        val fallbackAlias = aliases.firstOrNull { it.contains("ubuntu") }
        if (fallbackAlias != null) {
            emitTelemetry(VirtualizationEvent.Warning("Using existing distro '$fallbackAlias'. Some tooling may be missing."))
            activeDistroAlias = fallbackAlias
            return true
        }

        return false
    }

    /**
     * Install the required distro alias via proot-distro
     */
    private suspend fun installDistro(): String? {
        emitTelemetry(VirtualizationEvent.Info("Installing '$DISTRO_BASE' via proot-distro"))
        val result = executeHostCommand(
            listOf(
                "proot-distro",
                "install",
                "--override-alias",
                DISTRO_ALIAS,
                DISTRO_BASE
            )
        )

        return if (result.exitCode == 0) {
            DISTRO_ALIAS
        } else {
            emitTelemetry(
                VirtualizationEvent.Error(
                    "proot-distro install failed: ${result.stderr.ifBlank { result.stdout }}"
                )
            )
            null
        }
    }

    /**
     * Configure the distro with required packages and supervisor script
     */
    private suspend fun provisionDistro(): Boolean {
        val alias = activeDistroAlias ?: return false

        if (!workspaceDir.exists()) {
            workspaceDir.mkdirs()
        }

        val setupScript = """
            set -e
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y --no-install-recommends \
                curl ca-certificates git openssh-client \
                nodejs npm python3 python3-pip \
                openjdk-17-jdk build-essential
            if ! command -v code-server >/dev/null 2>&1; then
                curl -fsSL https://code-server.dev/install.sh | sh
            fi
            mkdir -p $WORKSPACE_DIR
            cat <<'EOF' > $START_SCRIPT
            #!/usr/bin/env bash
            set -e
            CODE_SERVER_BIN="${'$'}(command -v code-server)"
            LOG_FILE="/var/log/weblabs-code-server.log"
            PID_FILE="$PID_FILE"
            WORKSPACE="$WORKSPACE_DIR"

            ensure_running() {
                mkdir -p "${'$'}(dirname "${'$'}LOG_FILE")"
                mkdir -p "$WORKSPACE"
                nohup "${'$'}CODE_SERVER_BIN" --bind-addr 0.0.0.0:$IDE_PORT --auth none "$WORKSPACE" \
                    >> "${'$'}LOG_FILE" 2>&1 &
                echo ${'$'}! > "${'$'}PID_FILE"
            }

            status() {
                if [ -f "${'$'}PID_FILE" ] && kill -0 "${'$'}(cat "${'$'}PID_FILE")" 2>/dev/null; then
                    echo "running"
                else
                    echo "stopped"
                fi
            }

            case "${'$'}1" in
                start)
                    if [ "${'$'}(status)" = "running" ]; then
                        exit 0
                    fi
                    ensure_running
                    ;;
                stop)
                    if [ "${'$'}(status)" = "running" ]; then
                        kill "${'$'}(cat "${'$'}PID_FILE")" && rm -f "${'$'}PID_FILE"
                    fi
                    ;;
                status)
                    status
                    ;;
                *)
                    echo "Usage: ${'$'}0 {start|stop|status}" >&2
                    exit 1
                    ;;
            esac
            EOF
            chmod +x $START_SCRIPT
        """.trimIndent()

        val result = executeHostCommand(
            buildLoginCommand(
                alias,
                "bash",
                "-lc",
                setupScript
            )
        )

        if (result.exitCode != 0) {
            emitTelemetry(
                VirtualizationEvent.Error(
                    "Failed to configure distro: ${result.stderr.ifBlank { result.stdout }}"
                )
            )
        }

        return result.exitCode == 0
    }

    /**
     * Start Code-Server inside the virtualized environment
     */
    private suspend fun startVirtualInstance(): Boolean {
        val alias = activeDistroAlias ?: return false
        stopContainer()

        val startResult = executeHostCommand(
            buildLoginCommand(
                alias,
                "bash",
                "-lc",
                "$START_SCRIPT start"
            )
        )

        if (startResult.exitCode != 0) {
            emitTelemetry(
                VirtualizationEvent.Error(
                    "Failed to start Code-Server: ${startResult.stderr.ifBlank { startResult.stdout }}"
                )
            )
        }

        return startResult.exitCode == 0
    }

    /**
     * Wait for IDE to become available
     */
    private suspend fun waitForIDE(): Boolean = withContext(Dispatchers.IO) {
        repeat(30) { attempt ->
            try {
                val url = URL("http://localhost:$IDE_PORT")
                val connection = url.openConnection() as HttpURLConnection
                connection.connectTimeout = 2000
                connection.readTimeout = 2000
                
                if (connection.responseCode == 200) {
                    Log.i(TAG, "✅ IDE is ready at http://localhost:$IDE_PORT")
                    return@withContext true
                }
            } catch (e: Exception) {
                Log.d(TAG, "Waiting for IDE... attempt ${attempt + 1}/30")
            }
            
            delay(2000)
        }
        
        Log.w(TAG, "❌ IDE not accessible after 60 seconds")
        false
    }

    /**
     * Setup local environment as fallback
     */
    private suspend fun setupLocalEnvironment(): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "📱 Setting up local development environment...")
            
            // Create workspace directories
            val workspaceDir = File(context.filesDir, "workspace")
            workspaceDir.mkdirs()
            
            val projectsDir = File(workspaceDir, "projects")
            projectsDir.mkdirs()
            
            val aiDir = File(workspaceDir, "ai")
            aiDir.mkdirs()
            
            // Copy web IDE assets
            copyWebIDEAssets()
            
            emitTelemetry(VirtualizationEvent.Warning("Local environment is active. Some IDE capabilities may be limited."))
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup local environment", e)
            false
        }
    }

    /**
     * Copy web IDE assets to workspace
     */
    private fun copyWebIDEAssets() {
        try {
            val assetsManager = context.assets
            val workspaceDir = File(context.filesDir, "workspace")
            
            // Copy webide assets
            val webideAssets = assetsManager.list("webide") ?: emptyArray()
            val webideDir = File(workspaceDir, "webide")
            webideDir.mkdirs()
            
            webideAssets.forEach { asset ->
                val inputStream = assetsManager.open("webide/$asset")
                val outputFile = File(webideDir, asset)
                outputFile.outputStream().use { output ->
                    inputStream.copyTo(output)
                }
            }
            
            Log.i(TAG, "✅ Web IDE assets copied")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy web IDE assets", e)
        }
    }
    
    /**
     * Execute command in Docker container
     */
    suspend fun executeCommand(command: String): String = withContext(Dispatchers.IO) {
        val alias = activeDistroAlias ?: throw IllegalStateException("Virtual environment not initialized")
        val result = executeHostCommand(
            buildLoginCommand(
                alias,
                "bash",
                "-lc",
                "cd $WORKSPACE_DIR && $command"
            )
        )

        if (result.exitCode == 0) {
            result.stdout
        } else {
            val errorMessage = result.stderr.ifBlank { result.stdout }
            throw RuntimeException("Command failed: $errorMessage")
        }
    }

    /**
     * Public API to (re)start the virtual environment on demand
     */
    suspend fun startContainerPublic(): String = withContext(Dispatchers.IO) {
        if (!isVirtualizationAvailable()) {
            return@withContext "Virtualization unavailable"
        }

        if (!ensureDistro()) {
            return@withContext "Provisioning failed"
        }

        if (!provisionDistro()) {
            return@withContext "Configuration failed"
        }

        if (!startVirtualInstance()) {
            return@withContext "Failed to start"
        }

        if (waitForIDE()) {
            "Running"
        } else {
            "Timeout waiting for IDE"
        }
    }

    /**
     * Get container status
     */
    suspend fun getContainerStatus(): String = withContext(Dispatchers.IO) {
        if (!isVirtualizationAvailable()) {
            return@withContext "Virtualization unavailable"
        }

        val alias = activeDistroAlias ?: return@withContext "Not provisioned"
        val result = executeHostCommand(
            buildLoginCommand(
                alias,
                "bash",
                "-lc",
                "$START_SCRIPT status"
            )
        )

        return@withContext when {
            result.exitCode != 0 -> "Error: ${result.stderr.ifBlank { result.stdout }}"
            result.stdout.trim().equals("running", ignoreCase = true) -> "Running"
            result.stdout.trim().equals("stopped", ignoreCase = true) -> "Stopped"
            else -> "Unknown"
        }
    }

    /**
     * Cleanup resources
     */
    fun cleanup() {
        scope.cancel()
    }

    /**
     * Stop Code-Server inside the virtualized environment
     */
    suspend fun stopContainer(): Boolean = withContext(Dispatchers.IO) {
        val alias = activeDistroAlias ?: return@withContext true
        val result = executeHostCommand(
            buildLoginCommand(
                alias,
                "bash",
                "-lc",
                "$START_SCRIPT stop"
            )
        )

        result.exitCode == 0
    }

    private suspend fun getInstalledAliases(): List<String> {
        val result = executeHostCommand(listOf("proot-distro", "list"))
        if (result.exitCode != 0) {
            emitTelemetry(
                VirtualizationEvent.Warning(
                    "Unable to query proot-distro: ${result.stderr.ifBlank { result.stdout }}"
                )
            )
            return emptyList()
        }

        return result.stdout
            .lineSequence()
            .map { it.trim() }
            .filter { it.startsWith("*") }
            .map { it.removePrefix("*").trim() }
            .filter { it.isNotEmpty() }
            .toList()
    }

    private suspend fun emitTelemetry(event: VirtualizationEvent) {
        when (event) {
            is VirtualizationEvent.Info -> Log.i(TAG, event.message)
            is VirtualizationEvent.Warning -> Log.w(TAG, event.message)
            is VirtualizationEvent.Error -> Log.e(TAG, event.message, event.throwable)
        }
        telemetryFlow.emit(event)
    }

    private suspend fun executeHostCommand(
        command: List<String>,
        workingDir: File? = null,
        environment: Map<String, String> = emptyMap()
    ): CommandResult = withContext(Dispatchers.IO) {
        try {
            val builder = ProcessBuilder(command)
            if (workingDir != null) {
                builder.directory(workingDir)
            }

            val env = builder.environment()
            environment.forEach { (key, value) ->
                env[key] = value
            }

            val process = builder.start()
            val stdout = process.inputStream.bufferedReader().readText()
            val stderr = process.errorStream.bufferedReader().readText()
            val exitCode = process.waitFor()
            CommandResult(exitCode, stdout, stderr)
        } catch (e: IOException) {
            CommandResult(1, "", e.message ?: "IO error")
        }
    }

    data class CommandResult(
        val exitCode: Int,
        val stdout: String,
        val stderr: String
    )

    private fun buildLoginCommand(alias: String, vararg command: String): List<String> {
        workspaceDir.mkdirs()
        val base = mutableListOf(
            "proot-distro",
            "login",
            alias,
            "--shared-tmp",
            "--termux-home",
            "--bind",
            "${workspaceDir.absolutePath}:$WORKSPACE_DIR",
            "--"
        )
        base.addAll(command)
        return base
    }
}
