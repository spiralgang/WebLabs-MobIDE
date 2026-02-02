package com.spiralgang.weblabs.services

import android.app.*
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.spiralgang.weblabs.R
import com.spiralgang.weblabs.utils.AlpineLinuxManager
import kotlinx.coroutines.*
import java.io.File

/**
 * Alpine Linux Background Service
 * 
 * Manages the Alpine Linux environment running on Android:
 * - Downloads and installs Alpine Linux ARM64 rootfs
 * - Manages chroot environment
 * - Provides development tools (gcc, nodejs, python, git, etc.)
 * - Handles package management with apk
 * - Maintains persistent development environment
 */
class AlpineLinuxService : Service() {
    
    companion object {
        const val TAG = "AlpineLinuxService"
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "alpine_linux_service"
    }
    
    private val binder = LocalBinder()
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private lateinit var alpineManager: AlpineLinuxManager
    private var isEnvironmentReady = false
    
    inner class LocalBinder : Binder() {
        fun getService(): AlpineLinuxService = this@AlpineLinuxService
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Alpine Linux Service created")
        
        alpineManager = AlpineLinuxManager(this)
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "Alpine Linux Service started")
        
        // Start foreground service
        startForeground(NOTIFICATION_ID, createNotification("Initializing Alpine Linux..."))
        
        // Initialize Alpine Linux environment
        serviceScope.launch {
            initializeAlpineEnvironment()
        }
        
        return START_STICKY // Restart if killed
    }
    
    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alpine Linux Environment",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Manages Alpine Linux development environment"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(status: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("WebLabs MobIDE")
            .setContentText("Alpine Linux: $status")
            .setSmallIcon(R.drawable.ic_terminal) // You'll need to add this icon
            .setOngoing(true)
            .build()
    }
    
    private suspend fun initializeAlpineEnvironment() = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "Initializing Alpine Linux environment...")
            updateNotification("Downloading Alpine Linux...")
            
            // Download Alpine Linux ARM64 minirootfs if not exists
            if (!alpineManager.isAlpineInstalled()) {
                alpineManager.downloadAlpineRootfs()
                updateNotification("Installing Alpine Linux...")
                alpineManager.extractAlpineRootfs()
            }
            
            // Setup chroot environment
            updateNotification("Setting up chroot environment...")
            alpineManager.setupChrootEnvironment()
            
            // Install development tools
            updateNotification("Installing development tools...")
            installDevelopmentTools()
            
            // Setup AI development environment
            updateNotification("Setting up AI development environment...")
            setupAIDevelopmentEnvironment()
            
            isEnvironmentReady = true
            updateNotification("Alpine Linux ready for development")
            
            Log.i(TAG, "Alpine Linux environment initialized successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Alpine Linux environment", e)
            updateNotification("Failed to initialize Alpine Linux")
        }
    }
    
    private suspend fun installDevelopmentTools() = withContext(Dispatchers.IO) {
        val packages = listOf(
            // Essential development tools
            "build-base",
            "gcc", "g++", "make", "cmake",
            
            // Languages and runtimes
            "nodejs", "npm", "yarn",
            "python3", "py3-pip",
            "openjdk11",
            "go",
            "rust", "cargo",
            
            // Version control and utilities
            "git", "git-lfs",
            "curl", "wget",
            "nano", "vim",
            "tmux", "screen",
            
            // System tools
            "htop", "tree", "zip", "unzip",
            "openssh-client",
            
            // Mobile development specific
            "android-tools", // adb, fastboot
            
            // AI/ML development
            "py3-numpy", "py3-scipy",
            "py3-requests",
            
            // WebAssembly tools
            "wabt" // WebAssembly Binary Toolkit
        )
        
        for (pkg in packages) {
            try {
                Log.d(TAG, "Installing package: $pkg")
                alpineManager.installPackage(pkg)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to install package $pkg", e)
            }
        }
    }
    
    private suspend fun setupAIDevelopmentEnvironment() = withContext(Dispatchers.IO) {
        try {
            // Install AI development tools
            alpineManager.executeCommand("pip3 install --user transformers torch numpy requests aiohttp")
            
            // Setup development workspace
            val workspaceDir = File(alpineManager.alpineRoot, "home/developer")
            workspaceDir.mkdirs()
            
            // Create development scripts
            createDevelopmentScripts()
            
            // Setup git configuration
            alpineManager.executeCommand("git config --global user.name 'WebLabs MobIDE'")
            alpineManager.executeCommand("git config --global user.email 'developer@weblabs.mobide'")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup AI development environment", e)
        }
    }
    
    private fun createDevelopmentScripts() {
        // Create useful development scripts
        val scripts = mapOf(
            "ai-assist" to """#!/bin/sh
# AI Assistant Script for WebLabs MobIDE
echo "AI Assistant - WebLabs MobIDE"
echo "Usage: ai-assist <command> [arguments]"
case "$1" in
    generate)
        echo "Generating code for: $2"
        ;;
    analyze)
        echo "Analyzing project..."
        ;;
    refactor)
        echo "Refactoring code..."
        ;;
    *)
        echo "Available commands: generate, analyze, refactor"
        ;;
esac
""",
            
            "mobile-build" to """#!/bin/sh
# Mobile Build Script for ARM64 Android
echo "Mobile Build System - ARM64 Optimized"
echo "Building for architecture: aarch64"

# Set ARM64 compilation flags
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export CFLAGS="-march=armv8-a -mtune=cortex-a53"
export CXXFLAGS="-march=armv8-a -mtune=cortex-a53"

echo "ARM64 build environment configured"
""",
            
            "webide-tools" to """#!/bin/sh
# WebLabs MobIDE Development Tools
echo "WebLabs MobIDE Development Tools"
echo "Available tools:"
echo "  mobile-build  - ARM64 mobile build environment"
echo "  ai-assist     - AI development assistant"
echo "  apk-build     - Android APK build tools"
echo "  web-serve     - Local web development server"
""",
            
            "apk-build" to """#!/bin/sh
# APK Build Script for WebLabs MobIDE
echo "APK Build System - WebLabs MobIDE"
if [ -f "build.gradle" ]; then
    echo "Building Android APK..."
    ./gradlew assembleDebug assembleRelease
    echo "APK build complete"
else
    echo "No Android project found (build.gradle missing)"
fi
"""
        )
        
        val scriptsDir = File(alpineManager.alpineRoot, "usr/local/bin")
        scriptsDir.mkdirs()
        
        scripts.forEach { (name, content) ->
            val scriptFile = File(scriptsDir, name)
            scriptFile.writeText(content)
            scriptFile.setExecutable(true)
        }
    }
    
    private fun updateNotification(status: String) {
        val notification = createNotification(status)
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    // Public API for MainActivity and other components
    
    fun isEnvironmentReady(): Boolean = isEnvironmentReady
    
    suspend fun initializeEnvironment() = withContext(Dispatchers.IO) {
        if (!isEnvironmentReady) {
            initializeAlpineEnvironment()
        }
    }
    
    suspend fun setupDevelopmentTools() = withContext(Dispatchers.IO) {
        if (isEnvironmentReady) {
            installDevelopmentTools()
        }
    }
    
    fun executeCommand(command: String): String {
        return try {
            if (!isEnvironmentReady) {
                return "Alpine Linux environment not ready"
            }
            alpineManager.executeCommand(command)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to execute command: $command", e)
            "Error: ${e.message}"
        }
    }
    
    fun installPackage(packageName: String): Boolean {
        return try {
            if (!isEnvironmentReady) {
                return false
            }
            alpineManager.installPackage(packageName)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to install package: $packageName", e)
            false
        }
    }
    
    fun getSystemInfo(): String {
        return try {
            if (!isEnvironmentReady) {
                return """{"status":"not_ready","alpine_version":"unknown"}"""
            }
            
            val alpineVersion = alpineManager.executeCommand("cat /etc/alpine-release").trim()
            val architecture = alpineManager.executeCommand("uname -m").trim()
            val kernel = alpineManager.executeCommand("uname -r").trim()
            val packages = alpineManager.executeCommand("apk list --installed | wc -l").trim()
            
            """
            {
                "status": "ready",
                "alpine_version": "$alpineVersion",
                "architecture": "$architecture",
                "kernel": "$kernel",
                "installed_packages": $packages,
                "environment": "WebLabs MobIDE"
            }
            """.trimIndent()
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get system info", e)
            """{"status":"error","message":"${e.message}"}"""
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        alpineManager.cleanup()
        Log.i(TAG, "Alpine Linux Service destroyed")
    }
}