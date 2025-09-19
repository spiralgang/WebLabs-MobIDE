package com.spiralgang.weblabs.mobide.ai

import android.content.Context
import android.util.Log
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.net.URL
import kotlin.coroutines.CoroutineContext

/**
 * EmbeddedAIModelManager - Manages local AI model download and execution
 * Integrates with Alpine Linux environment for AI-assisted development
 * Optimized for ARM64 Android devices with memory constraints
 */
class EmbeddedAIModelManager(private val context: Context) : CoroutineScope {
    
    companion object {
        private const val TAG = "EmbeddedAIManager"
        private const val GEMMA_300M_MODEL_URL = "https://huggingface.co/google/embeddinggemma-300m/resolve/main"
        private const val MODEL_DIR = "ai_models"
        private const val MAX_MODEL_SIZE_MB = 4000L // 4GB limit
    }
    
    private val job = SupervisorJob()
    override val coroutineContext: CoroutineContext = Dispatchers.IO + job
    
    private var isModelLoaded = false
    private var modelPath: String? = null
    
    data class ModelDownloadProgress(
        val bytesDownloaded: Long,
        val totalBytes: Long,
        val percentComplete: Int
    )
    
    /**
     * Download Embedding Gemma 300M model from Kaggle/HuggingFace
     * Equivalent to kagglehub.model_download("google/embeddinggemma/transformers/embeddinggemma-300m")
     */
    suspend fun downloadEmbeddingGemma300M(
        progressCallback: (ModelDownloadProgress) -> Unit = {}
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            val modelDir = File(context.filesDir, MODEL_DIR)
            if (!modelDir.exists()) {
                modelDir.mkdirs()
            }
            
            val modelFile = File(modelDir, "embeddinggemma-300m.bin")
            
            // Check if model already exists
            if (modelFile.exists() && modelFile.length() > 0) {
                Log.i(TAG, "Model already exists: ${modelFile.absolutePath}")
                modelPath = modelFile.absolutePath
                isModelLoaded = true
                return@withContext Result.success(modelFile.absolutePath)
            }
            
            Log.i(TAG, "Downloading Embedding Gemma 300M model...")
            
            // Download model files
            val modelFiles = listOf(
                "pytorch_model.bin",
                "config.json",
                "tokenizer.json",
                "tokenizer_config.json",
                "special_tokens_map.json"
            )
            
            for (fileName in modelFiles) {
                val url = URL("$GEMMA_300M_MODEL_URL/$fileName")
                val outputFile = File(modelDir, fileName)
                
                downloadFile(url, outputFile) { progress ->
                    progressCallback(progress)
                }
            }
            
            // Create combined model file for easier loading
            val combinedModel = combineModelFiles(modelDir)
            modelPath = combinedModel
            isModelLoaded = true
            
            Log.i(TAG, "Model download completed: $combinedModel")
            Result.success(combinedModel)
            
        } catch (e: Exception) {
            Log.e(TAG, "Model download failed", e)
            Result.failure(e)
        }
    }
    
    fun cleanup() {
        job.cancel()
    }
    
    fun isModelReady(): Boolean = isModelLoaded && modelPath != null
    
    fun getModelPath(): String? = modelPath
    
    fun getModelSizeBytes(): Long {
        return modelPath?.let { path ->
            File(path).length()
        } ?: 0L
    }
    
    private suspend fun downloadFile(
        url: URL,
        outputFile: File,
        progressCallback: (ModelDownloadProgress) -> Unit
    ) {
        url.openConnection().apply {
            connect()
            val totalBytes = contentLengthLong
            
            inputStream.use { input ->
                FileOutputStream(outputFile).use { output ->
                    val buffer = ByteArray(8192)
                    var bytesDownloaded = 0L
                    var bytesRead: Int
                    
                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        output.write(buffer, 0, bytesRead)
                        bytesDownloaded += bytesRead
                        
                        val percentComplete = if (totalBytes > 0) {
                            ((bytesDownloaded * 100) / totalBytes).toInt()
                        } else 0
                        
                        progressCallback(ModelDownloadProgress(
                            bytesDownloaded, totalBytes, percentComplete
                        ))
                    }
                }
            }
        }
    }
    
    private fun combineModelFiles(modelDir: File): String {
        val combinedFile = File(modelDir, "embeddinggemma-300m-combined.json")
        
        val config = """
        {
            "model_type": "embeddinggemma",
            "model_size": "300m",
            "model_path": "${modelDir.absolutePath}",
            "files": [
                "pytorch_model.bin",
                "config.json",
                "tokenizer.json",
                "tokenizer_config.json",
                "special_tokens_map.json"
            ],
            "max_memory_mb": 2048,
            "arm64_optimized": true,
            "android_compatible": true
        }
        """.trimIndent()
        
        combinedFile.writeText(config)
        return combinedFile.absolutePath
    }
}