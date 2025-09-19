package com.spiralgang.weblabs.mobide

import android.app.Application
import android.content.Intent
import android.os.Build
import android.util.Log
import com.spiralgang.weblabs.mobide.services.AlpineLinuxService
import com.spiralgang.weblabs.mobide.utils.AlpineLinuxInstaller
import com.spiralgang.weblabs.mobide.utils.PermissionManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * WebLabs MobIDE Application Class
 * Initializes Alpine Linux environment and Shell-IDE components
 * Designed for ARM64/AArch64 Android 10+ devices
 */
class WeblabsMobIDEApplication : Application() {
    
    companion object {
        const val TAG = "WeblabsMobIDE"
        lateinit var instance: WeblabsMobIDEApplication
            private set
    }
    
    private val applicationScope = CoroutineScope(Dispatchers.Main)
    private lateinit var alpineInstaller: AlpineLinuxInstaller
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        Log.i(TAG, "WebLabs MobIDE Application starting...")
        Log.i(TAG, "Device Architecture: ${Build.SUPPORTED_ABIS.joinToString()}")
        Log.i(TAG, "Android Version: ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
        
        initializeApplication()
    }
    
    private fun initializeApplication() {
        applicationScope.launch {
            try {
                // Initialize Alpine Linux installer
                alpineInstaller = AlpineLinuxInstaller(this@WeblabsMobIDEApplication)
                
                // Check ARM64 compatibility
                if (!isARM64Compatible()) {
                    Log.e(TAG, "Device is not ARM64 compatible!")
                    return@launch
                }
                
                // Initialize Alpine Linux environment in background
                initializeAlpineLinux()
                
                // Start background services
                startBackgroundServices()
                
                Log.i(TAG, "WebLabs MobIDE Application initialized successfully")
                
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize application", e)
            }
        }
    }
    
    private fun isARM64Compatible(): Boolean {
        val supportedAbis = Build.SUPPORTED_ABIS
        return supportedAbis.contains("arm64-v8a") || supportedAbis.contains("aarch64")
    }
    
    private suspend fun initializeAlpineLinux() {
        Log.i(TAG, "Initializing Alpine Linux environment...")
        
        try {
            // Check if Alpine Linux is already installed
            if (!alpineInstaller.isAlpineInstalled()) {
                Log.i(TAG, "Alpine Linux not found, beginning installation...")
                alpineInstaller.downloadAndInstallAlpine()
            } else {
                Log.i(TAG, "Alpine Linux already installed, verifying integrity...")
                alpineInstaller.verifyInstallation()
            }
            
            // Setup development environment
            alpineInstaller.setupDevelopmentEnvironment()
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Alpine Linux", e)
        }
    }
    
    private fun startBackgroundServices() {
        Log.i(TAG, "Starting background services...")
        
        // Start Alpine Linux service
        val alpineService = Intent(this, AlpineLinuxService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(alpineService)
        } else {
            startService(alpineService)
        }
    }
    
    fun getAlpineInstaller(): AlpineLinuxInstaller = alpineInstaller
}