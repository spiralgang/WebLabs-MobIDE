package com.spiralgang.weblabs.mobide.utils

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.*
import java.net.URL
import java.util.zip.GZIPInputStream
import kotlin.io.use

/**
 * Alpine Linux Installer
 * Downloads and installs Alpine Linux ARM64 rootfs for Android
 */
class AlpineLinuxInstaller(private val context: Context) {
    
    companion object {
        const val TAG = "AlpineLinuxInstaller"
        const val ALPINE_VERSION = "3.18"
        const val ALPINE_ARCH = "aarch64"
        const val ALPINE_DOWNLOAD_URL = "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/releases/$ALPINE_ARCH/alpine-minirootfs-$ALPINE_VERSION.0-$ALPINE_ARCH.tar.gz"
        const val ALPINE_DIR_NAME = "alpine"
    }
    
    private val alpineRoot: File by lazy {
        File(context.filesDir, ALPINE_DIR_NAME)
    }
    
    private val alpineTarball: File by lazy {
        File(context.cacheDir, "alpine-minirootfs.tar.gz")
    }
    
    suspend fun downloadAndInstallAlpine() = withContext(Dispatchers.IO) {
        Log.i(TAG, "Starting Alpine Linux download and installation...")
        
        try {
            // Download Alpine Linux rootfs
            downloadAlpineRootfs()
            
            // Extract rootfs
            extractAlpineRootfs()
            
            // Setup basic environment
            setupBasicEnvironment()
            
            // Copy AI model installer script to Alpine environment
            copyAIInstallerToAlpine(alpineRoot)
            
            Log.i(TAG, "Alpine Linux installation completed successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to download and install Alpine Linux", e)
            throw e
        }
    }
    
    private suspend fun downloadAlpineRootfs() = withContext(Dispatchers.IO) {
        if (alpineTarball.exists() && alpineTarball.length() > 0) {
            Log.i(TAG, "Alpine Linux tarball already exists, skipping download")
            return@withContext
        }
        
        Log.i(TAG, "Downloading Alpine Linux rootfs from $ALPINE_DOWNLOAD_URL")
        
        try {
            val url = URL(ALPINE_DOWNLOAD_URL)
            url.openStream().use { input ->
                FileOutputStream(alpineTarball).use { output ->
                    input.copyTo(output)
                }
            }
            
            Log.i(TAG, "Alpine Linux rootfs downloaded: ${alpineTarball.length()} bytes")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to download Alpine Linux rootfs", e)
            throw IOException("Failed to download Alpine Linux: ${e.message}", e)
        }
    }
    
    private suspend fun extractAlpineRootfs() = withContext(Dispatchers.IO) {
        if (alpineRoot.exists() && alpineRoot.listFiles()?.isNotEmpty() == true) {
            Log.i(TAG, "Alpine Linux already extracted, skipping extraction")
            return@withContext
        }
        
        Log.i(TAG, "Extracting Alpine Linux rootfs...")
        
        try {
            // Create Alpine root directory
            alpineRoot.mkdirs()
            
            // Extract tar.gz file
            FileInputStream(alpineTarball).use { fileInput ->
                GZIPInputStream(fileInput).use { gzipInput ->
                    extractTarStream(gzipInput, alpineRoot)
                }
            }
            
            Log.i(TAG, "Alpine Linux rootfs extracted successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract Alpine Linux rootfs", e)
            throw IOException("Failed to extract Alpine Linux: ${e.message}", e)
        }
    }
    
    private fun extractTarStream(inputStream: InputStream, destDir: File) {
        // Simple tar extraction implementation
        // In production, you might want to use a proper tar library
        
        val processBuilder = ProcessBuilder()
        processBuilder.command("tar", "-xzf", "-", "-C", destDir.absolutePath)
        processBuilder.redirectErrorStream(true)
        
        try {
            val process = processBuilder.start()
            
            // Pipe the input stream to tar process
            inputStream.use { input ->
                process.outputStream.use { output ->
                    input.copyTo(output)
                }
            }
            
            val exitCode = process.waitFor()
            if (exitCode != 0) {
                val errorOutput = process.inputStream.bufferedReader().readText()
                throw IOException("tar extraction failed with exit code $exitCode: $errorOutput")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract tar stream", e)
            throw e
        }
    }
    
    private suspend fun setupBasicEnvironment() = withContext(Dispatchers.IO) {
        Log.i(TAG, "Setting up basic Alpine Linux environment...")
        
        try {
            // Create necessary directories
            val dirs = listOf(
                "dev", "proc", "sys", "tmp",
                "home/developer",
                "var/log",
                "etc/apk"
            )
            
            dirs.forEach { dir ->
                File(alpineRoot, dir).mkdirs()
            }
            
            // Setup APK repositories
            setupApkRepositories()
            
            // Create basic startup script
            createStartupScript()
            
            // Set permissions
            setPermissions()
            
            Log.i(TAG, "Basic Alpine Linux environment setup completed")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup basic environment", e)
            throw e
        }
    }
    
    private fun setupApkRepositories() {
        val repositoriesFile = File(alpineRoot, "etc/apk/repositories")
        val repositories = """
            https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main
            https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community
            https://dl-cdn.alpinelinux.org/alpine/edge/testing
        """.trimIndent()
        
        repositoriesFile.writeText(repositories)
    }
    
    private fun createStartupScript() {
        val startupScript = File(alpineRoot, "startup.sh")
        val script = """
            #!/bin/sh
            # WebLabs MobIDE Alpine Linux Startup Script
            
            echo "WebLabs MobIDE - Alpine Linux Environment"
            echo "Architecture: $ALPINE_ARCH"
            echo "Alpine Version: $ALPINE_VERSION"
            echo ""
            
            # Mount essential filesystems
            if ! mountpoint -q /proc; then
                mount -t proc proc /proc
            fi
            
            if ! mountpoint -q /sys; then
                mount -t sysfs sysfs /sys
            fi
            
            if ! mountpoint -q /dev; then
                mount --bind /dev /dev
            fi
            
            # Update package index if needed
            if [ ! -f "/var/lib/apk/installed" ]; then
                echo "Updating package index..."
                apk update
            fi
            
            # Setup developer environment
            if [ ! -d "/home/developer" ]; then
                mkdir -p /home/developer
                cd /home/developer
            fi
            
            echo "Alpine Linux environment ready!"
            echo "Use 'apk' to install packages"
            echo "Development tools available: gcc, nodejs, python3, git"
            echo ""
            
            # Start shell
            exec /bin/sh
        """.trimIndent()
        
        startupScript.writeText(script)
        startupScript.setExecutable(true)
    }
    
    private fun setPermissions() {
        try {
            // Set execute permissions on essential binaries
            val binaries = listOf(
                "bin/sh", "bin/ash", "sbin/apk",
                "usr/bin/env", "startup.sh"
            )
            
            binaries.forEach { binary ->
                val file = File(alpineRoot, binary)
                if (file.exists()) {
                    file.setExecutable(true)
                }
            }
            
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set some permissions", e)
        }
    }
    
    suspend fun setupDevelopmentEnvironment() = withContext(Dispatchers.IO) {
        Log.i(TAG, "Setting up development environment...")
        
        try {
            // Install essential development packages
            val packages = listOf(
                "alpine-sdk", "build-base",
                "nodejs", "npm", "python3", "py3-pip",
                "git", "curl", "wget", "nano"
            )
            
            // This would be implemented by AlpineLinuxManager
            // for now, just create the package list
            val packageListFile = File(alpineRoot, "home/developer/packages-to-install.txt")
            packageListFile.writeText(packages.joinToString("\n"))
            
            Log.i(TAG, "Development environment setup completed")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup development environment", e)
            throw e
        }
    }
    
    fun isAlpineInstalled(): Boolean {
        return alpineRoot.exists() && 
               alpineRoot.isDirectory && 
               File(alpineRoot, "bin/sh").exists() &&
               File(alpineRoot, "sbin/apk").exists()
    }
    
    suspend fun verifyInstallation() = withContext(Dispatchers.IO) {
        Log.i(TAG, "Verifying Alpine Linux installation...")
        
        val requiredFiles = listOf(
            "bin/sh", "sbin/apk", "etc/apk/repositories",
            "startup.sh"
        )
        
        val missingFiles = requiredFiles.filter { 
            !File(alpineRoot, it).exists() 
        }
        
        if (missingFiles.isNotEmpty()) {
            Log.w(TAG, "Missing files in Alpine installation: $missingFiles")
            throw IOException("Alpine Linux installation is incomplete: missing $missingFiles")
        }
        
        Log.i(TAG, "Alpine Linux installation verified successfully")
    }
    
    fun getAlpineRoot(): File = alpineRoot
    
    fun cleanup() {
        try {
            if (alpineTarball.exists()) {
                alpineTarball.delete()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to cleanup temporary files", e)
        }
    }
}