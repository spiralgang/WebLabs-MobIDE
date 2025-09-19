package com.spiralgang.weblabs

import android.content.Context
import android.util.Log
import kotlinx.coroutines.*
import java.io.*
import java.net.HttpURLConnection
import java.net.URL

/**
 * DockerManager - Ubuntu 24.04 ARM64 Docker Environment Manager
 * 
 * Manages Docker-based Ubuntu development environment for WebLabs-MobIDE.
 * Replaces Alpine Linux proot with standard Docker containerization.
 * 
 * Features:
 * - Ubuntu 24.04 ARM64 container management
 * - Code-Server web IDE at localhost:8080
 * - Android SDK, NDK, Python, Node.js, AI tools
 * - GitHub Copilot compatible environment
 */
class DockerManager(private val context: Context) {
    
    companion object {
        const val TAG = "DockerManager"
        const val DOCKER_IMAGE = "weblabs-mobide:latest"
        const val CONTAINER_NAME = "weblabs-mobide"
        const val IDE_PORT = 8080
        const val WORKSPACE_DIR = "/home/developer/workspace"
    }
    
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    /**
     * Initialize Docker environment
     */
    suspend fun initializeDocker(): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "🐳 Initializing Docker Ubuntu environment...")
            
            // Check if Docker is available
            if (!isDockerAvailable()) {
                Log.e(TAG, "Docker not available, falling back to local environment")
                return@withContext setupLocalEnvironment()
            }
            
            // Build Docker image if needed
            if (!isImageBuilt()) {
                buildDockerImage()
            }
            
            // Start container
            startContainer()
            
            // Verify IDE is accessible
            waitForIDE()
            
            Log.i(TAG, "✅ Docker environment ready at http://localhost:$IDE_PORT")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Docker environment", e)
            false
        }
    }
    
    /**
     * Check if Docker is available on the system
     */
    private suspend fun isDockerAvailable(): Boolean = withContext(Dispatchers.IO) {
        try {
            val process = ProcessBuilder("docker", "--version").start()
            val exitCode = process.waitFor()
            exitCode == 0
        } catch (e: Exception) {
            Log.w(TAG, "Docker not available: ${e.message}")
            false
        }
    }
    
    /**
     * Check if Docker image is built
     */
    private suspend fun isImageBuilt(): Boolean = withContext(Dispatchers.IO) {
        try {
            val process = ProcessBuilder("docker", "images", "-q", DOCKER_IMAGE).start()
            val output = process.inputStream.bufferedReader().readText().trim()
            val exitCode = process.waitFor()
            exitCode == 0 && output.isNotEmpty()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to check Docker image: ${e.message}")
            false
        }
    }
    
    /**
     * Build Docker image
     */
    private suspend fun buildDockerImage(): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "🔨 Building Docker image...")
            
            // Copy Docker files to cache directory
            copyDockerFilesToCache()
            
            val cacheDir = File(context.cacheDir, "docker")
            val process = ProcessBuilder("docker", "build", "-t", DOCKER_IMAGE, ".")
                .directory(cacheDir)
                .start()
            
            // Stream build output
            val reader = process.inputStream.bufferedReader()
            reader.useLines { lines ->
                lines.forEach { line ->
                    Log.d(TAG, "Docker build: $line")
                }
            }
            
            val exitCode = process.waitFor()
            if (exitCode == 0) {
                Log.i(TAG, "✅ Docker image built successfully")
                true
            } else {
                Log.e(TAG, "❌ Docker build failed with exit code: $exitCode")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to build Docker image", e)
            false
        }
    }
    
    /**
     * Start Docker container
     */
    private suspend fun startContainer(): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "🚀 Starting Docker container...")
            
            // Stop existing container if running
            stopContainer()
            
            // Ensure dedicated workspace directory exists
            val workspaceDir = File(context.filesDir, "workspace")
            if (!workspaceDir.exists()) {
                workspaceDir.mkdirs()
            }
            
            val process = ProcessBuilder(
                "docker", "run", "-d",
                "--name", CONTAINER_NAME,
                "--platform", "linux/arm64",
                "-p", "$IDE_PORT:8080",
                "-v", "${workspaceDir.absolutePath}:$WORKSPACE_DIR",
                "--restart", "on-failure:3",
                DOCKER_IMAGE
            ).start()
            
            val exitCode = process.waitFor()
            if (exitCode == 0) {
                Log.i(TAG, "✅ Container started successfully")
                true
            } else {
                val error = process.errorStream.bufferedReader().readText()
                Log.e(TAG, "❌ Failed to start container: $error")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start container", e)
            false
        }
    }
    
    /**
     * Stop Docker container
     */
    suspend fun stopContainer(): Boolean = withContext(Dispatchers.IO) {
        try {
            val process = ProcessBuilder("docker", "stop", CONTAINER_NAME).start()
            process.waitFor()
            
            val removeProcess = ProcessBuilder("docker", "rm", CONTAINER_NAME).start()
            removeProcess.waitFor()
            
            Log.i(TAG, "🛑 Container stopped")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Failed to stop container: ${e.message}")
            true // Not a critical failure
        }
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
            
            Log.i(TAG, "✅ Local environment ready")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup local environment", e)
            false
        }
    }
    
    /**
     * Copy Docker files to cache directory for building
     */
    private fun copyDockerFilesToCache() {
        val cacheDir = File(context.cacheDir, "docker")
        cacheDir.mkdirs()
        
        // Copy Dockerfile
        val dockerfileContent = """
            FROM ubuntu:24.04
            
            ENV ANDROID_HOME=/opt/android-sdk
            ENV PATH=${'$'}PATH:${'$'}ANDROID_HOME/cmdline-tools/latest/bin:${'$'}ANDROID_HOME/platform-tools
            ENV DEBIAN_FRONTEND=noninteractive
            
            RUN apt-get update && apt-get install -y --no-install-recommends \
                git curl unzip wget ca-certificates \
                openjdk-17-jdk nodejs npm python3 python3-pip \
                build-essential cmake ninja-build pkg-config \
                nano vim htop tree bash-completion \
                && apt-get clean && rm -rf /var/lib/apt/lists/*
            
            RUN curl -fsSL https://code-server.dev/install.sh | sh
            
            RUN useradd -m -s /bin/bash developer && \
                mkdir -p /home/developer/workspace && \
                chown -R developer:developer /home/developer
            
            USER developer
            WORKDIR /home/developer/workspace
            
            EXPOSE 8080
            CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]
        """.trimIndent()
        
        File(cacheDir, "Dockerfile").writeText(dockerfileContent)
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
        try {
            val process = ProcessBuilder(
                "docker", "exec", CONTAINER_NAME, "bash", "-c", command
            ).start()
            
            val output = process.inputStream.bufferedReader().readText()
            val exitCode = process.waitFor()
            
            if (exitCode == 0) {
                output
            } else {
                val error = process.errorStream.bufferedReader().readText()
                throw RuntimeException("Command failed: $error")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to execute command: $command", e)
            throw e
        }
    }
    
    /**
     * Get container status
     */
    suspend fun getContainerStatus(): String = withContext(Dispatchers.IO) {
        try {
            val process = ProcessBuilder("docker", "ps", "-f", "name=$CONTAINER_NAME", "--format", "table {{.Status}}").start()
            val output = process.inputStream.bufferedReader().readText().trim()
            
            when {
                output.contains("Up") -> "Running"
                output.isEmpty() -> "Stopped"
                else -> "Unknown"
            }
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }
    
    /**
     * Cleanup resources
     */
    fun cleanup() {
        scope.cancel()
    }
}