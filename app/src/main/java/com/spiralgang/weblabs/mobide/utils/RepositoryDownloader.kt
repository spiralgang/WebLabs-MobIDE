package com.spiralgang.weblabs.mobide.utils

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.apache.commons.compress.archivers.zip.ZipArchiveInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.TimeUnit

class RepositoryDownloader(private val context: Context) {
    
    companion object {
        private const val TAG = "RepositoryDownloader"
        private const val REPO_URL = "https://github.com/spiralgang/WebLabs-MobIDE"
        private const val REPO_ZIP_URL = "$REPO_URL/archive/refs/heads/main.zip"
    }
    
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()
    
    /**
     * Downloads the repository and extracts it to the app's data directory
     */
    suspend fun downloadAndExtractRepository(): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "Starting repository download from: $REPO_ZIP_URL")
            
            val request = Request.Builder()
                .url(REPO_ZIP_URL)
                .addHeader("User-Agent", "WebLabs-MobIDE/1.0")
                .build()
            
            val response = httpClient.newCall(request).execute()
            
            if (!response.isSuccessful) {
                Log.e(TAG, "Failed to download repository: ${response.code}")
                return@withContext false
            }
            
            val repoDir = File(context.filesDir, "weblabs-mobide-repo")
            if (repoDir.exists()) {
                repoDir.deleteRecursively()
            }
            repoDir.mkdirs()
            
            response.body?.byteStream()?.use { inputStream ->
                ZipArchiveInputStream(inputStream).use { zipStream ->
                    var entry = zipStream.nextEntry
                    
                    while (entry != null) {
                        if (!entry.isDirectory) {
                            // Remove the root folder name from the path
                            val entryPath = entry.name.substringAfter("/")
                            if (entryPath.isNotEmpty()) {
                                val file = File(repoDir, entryPath)
                                file.parentFile?.mkdirs()
                                
                                FileOutputStream(file).use { outputStream ->
                                    zipStream.copyTo(outputStream)
                                }
                                
                                Log.d(TAG, "Extracted: $entryPath")
                            }
                        }
                        entry = zipStream.nextEntry
                    }
                }
            }
            
            Log.i(TAG, "Repository downloaded and extracted successfully")
            
            // Create symlinks and setup workspace
            setupWorkspace(repoDir)
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error downloading repository", e)
            false
        }
    }
    
    /**
     * Sets up the development workspace after repository extraction
     */
    private fun setupWorkspace(repoDir: File) {
        try {
            // Create workspace directories
            val workspaceDir = File(context.filesDir, "workspace")
            workspaceDir.mkdirs()
            
            // Copy essential files to workspace
            val essentialFiles = listOf(
                "WebLabs_MobIDE.html",
                "QuantumWebIDE.html",
                "package.json",
                "requirements.txt",
                "ai.js",
                "files.js",
                "terminal.js",
                "editor.js"
            )
            
            essentialFiles.forEach { fileName ->
                val sourceFile = File(repoDir, fileName)
                val destFile = File(workspaceDir, fileName)
                
                if (sourceFile.exists()) {
                    sourceFile.copyTo(destFile, overwrite = true)
                    Log.d(TAG, "Copied $fileName to workspace")
                }
            }
            
            // Create development directories
            File(workspaceDir, "projects").mkdirs()
            File(workspaceDir, "alpine-root").mkdirs()
            File(workspaceDir, "tmp").mkdirs()
            
            Log.i(TAG, "Workspace setup complete")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up workspace", e)
        }
    }
    
    /**
     * Gets the path to the downloaded repository
     */
    fun getRepositoryPath(): String {
        return File(context.filesDir, "weblabs-mobide-repo").absolutePath
    }
    
    /**
     * Gets the path to the workspace directory
     */
    fun getWorkspacePath(): String {
        return File(context.filesDir, "workspace").absolutePath
    }
    
    /**
     * Checks if the repository has been downloaded
     */
    fun isRepositoryDownloaded(): Boolean {
        val repoDir = File(context.filesDir, "weblabs-mobide-repo")
        return repoDir.exists() && repoDir.listFiles()?.isNotEmpty() == true
    }
}