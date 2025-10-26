package com.spiralgang.weblabs.utils

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Permission Manager for WebLabs MobIDE
 * Handles runtime permissions required for Alpine Linux environment
 */
class PermissionManager(private val activity: Activity) {
    
    companion object {
        const val REQUEST_CODE_PERMISSIONS = 1001
        const val REQUEST_CODE_MANAGE_ALL_FILES = 1002

        private val REQUIRED_PERMISSIONS = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            arrayOf(
                Manifest.permission.INTERNET,
                Manifest.permission.ACCESS_NETWORK_STATE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE,
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
    private var shouldRequestManageAllFiles = false

    fun requestAllPermissions(callback: (Boolean) -> Unit) {
        permissionCallback = callback

        shouldRequestManageAllFiles = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            !Environment.isExternalStorageManager()

        val deniedPermissions = REQUIRED_PERMISSIONS.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }

        if (deniedPermissions.isEmpty()) {
            if (shouldRequestManageAllFiles) {
                launchManageAllFilesAccessIntent()
            } else {
                finishPermissionRequest(true)
            }
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
            if (allGranted) {
                if (shouldRequestManageAllFiles) {
                    launchManageAllFilesAccessIntent()
                } else {
                    finishPermissionRequest(true)
                }
            } else {
                finishPermissionRequest(false)
            }
        }
    }

    fun hasAllPermissions(): Boolean {
        val standardPermissionsGranted = REQUIRED_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            standardPermissionsGranted && Environment.isExternalStorageManager()
        } else {
            standardPermissionsGranted
        }
    }

    fun hasPermission(permission: String): Boolean {
        if (permission == Manifest.permission.MANAGE_EXTERNAL_STORAGE &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
        ) {
            return Environment.isExternalStorageManager()
        }

        return ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
    }

    fun onActivityResult(requestCode: Int) {
        if (requestCode == REQUEST_CODE_MANAGE_ALL_FILES) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                finishPermissionRequest(Environment.isExternalStorageManager())
            } else {
                finishPermissionRequest(true)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun launchManageAllFilesAccessIntent() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            finishPermissionRequest(true)
            return
        }

        shouldRequestManageAllFiles = false

        val packageUri = Uri.parse("package:${activity.packageName}")
        val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, packageUri)

        try {
            activity.startActivityForResult(intent, REQUEST_CODE_MANAGE_ALL_FILES)
        } catch (e: ActivityNotFoundException) {
            val fallbackIntent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
            activity.startActivityForResult(fallbackIntent, REQUEST_CODE_MANAGE_ALL_FILES)
        }
    }

    private fun finishPermissionRequest(granted: Boolean) {
        shouldRequestManageAllFiles = false
        permissionCallback?.invoke(granted)
        permissionCallback = null
    }
}
