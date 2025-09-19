package com.spiralgang.weblabs.utils

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Permission Manager for WebLabs MobIDE
 * Handles runtime permissions required for Alpine Linux environment
 */
class PermissionManager(private val activity: Activity) {
    
    companion object {
        const val REQUEST_CODE_PERMISSIONS = 1001
        
        private val REQUIRED_PERMISSIONS = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            arrayOf(
                Manifest.permission.INTERNET,
                Manifest.permission.ACCESS_NETWORK_STATE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.MANAGE_EXTERNAL_STORAGE,
                Manifest.permission.WAKE_LOCK,
                Manifest.permission.FOREGROUND_SERVICE,
                Manifest.permission.REQUEST_INSTALL_PACKAGES
            )
        } else {
            arrayOf(
                Manifest.permission.INTERNET,
                Manifest.permission.ACCESS_NETWORK_STATE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WAKE_LOCK,
                Manifest.permission.FOREGROUND_SERVICE,
                Manifest.permission.REQUEST_INSTALL_PACKAGES
            )
        }
    }
    
    private var permissionCallback: ((Boolean) -> Unit)? = null
    
    fun requestAllPermissions(callback: (Boolean) -> Unit) {
        permissionCallback = callback
        
        val deniedPermissions = REQUIRED_PERMISSIONS.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }
        
        if (deniedPermissions.isEmpty()) {
            callback(true)
        } else {
            ActivityCompat.requestPermissions(
                activity,
                deniedPermissions.toTypedArray(),
                REQUEST_CODE_PERMISSIONS
            )
        }
    }
    
    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            val allGranted = grantResults.isNotEmpty() && 
                            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            permissionCallback?.invoke(allGranted)
            permissionCallback = null
        }
    }
    
    fun hasAllPermissions(): Boolean {
        return REQUIRED_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
    }
}