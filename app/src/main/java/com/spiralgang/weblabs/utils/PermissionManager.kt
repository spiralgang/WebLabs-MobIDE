package com.spiralgang.weblabs.utils

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.net.Uri
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
        const val REQUEST_CODE_ALL_FILES_ACCESS = 1002

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
    private var awaitingAllFilesAccess: Boolean = false

    fun requestAllPermissions(callback: (Boolean) -> Unit) {
        permissionCallback = callback

        val deniedPermissions = REQUIRED_PERMISSIONS.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }

        val needsAllFilesAccess = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !hasAllFilesAccess()

        when {
            deniedPermissions.isNotEmpty() -> {
                awaitingAllFilesAccess = needsAllFilesAccess
                ActivityCompat.requestPermissions(
                    activity,
                    deniedPermissions.toTypedArray(),
                    REQUEST_CODE_PERMISSIONS
                )
            }
            needsAllFilesAccess -> {
                awaitingAllFilesAccess = true
                launchAllFilesAccessIntent()
            }
            else -> {
                callback(true)
                permissionCallback = null
            }
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
            if (!allGranted) {
                permissionCallback?.invoke(false)
                permissionCallback = null
                awaitingAllFilesAccess = false
                return
            }

            if (awaitingAllFilesAccess && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !hasAllFilesAccess()) {
                launchAllFilesAccessIntent()
            } else {
                permissionCallback?.invoke(true)
                permissionCallback = null
                awaitingAllFilesAccess = false
            }
        }
    }

    fun hasAllPermissions(): Boolean {
        return hasStandardPermissions() && hasAllFilesAccess()
    }

    fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
    }

    fun onActivityResult(requestCode: Int) {
        if (requestCode == REQUEST_CODE_ALL_FILES_ACCESS) {
            val allFilesGranted = hasAllFilesAccess()
            val standardPermissionsGranted = hasStandardPermissions()
            permissionCallback?.invoke(allFilesGranted && standardPermissionsGranted)
            permissionCallback = null
            awaitingAllFilesAccess = false
        }
    }

    private fun hasStandardPermissions(): Boolean {
        return REQUIRED_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun hasAllFilesAccess(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.R || Environment.isExternalStorageManager()
    }

    private fun launchAllFilesAccessIntent() {
        try {
            val appSpecificIntent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                data = Uri.parse("package:${activity.packageName}")
            }

            val intent = if (appSpecificIntent.resolveActivity(activity.packageManager) != null) {
                appSpecificIntent
            } else {
                Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
            }

            activity.startActivityForResult(intent, REQUEST_CODE_ALL_FILES_ACCESS)
        } catch (exception: ActivityNotFoundException) {
            permissionCallback?.invoke(false)
            permissionCallback = null
            awaitingAllFilesAccess = false
        }
    }
}