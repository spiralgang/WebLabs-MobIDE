package com.spiralgang.weblabs

import android.content.Context
import android.util.Log
import com.spiralgang.weblabs.ai.CredentialsProvider
import com.spiralgang.weblabs.ai.HuggingFaceInferenceClient
import com.spiralgang.weblabs.ai.InferenceClient
import com.spiralgang.weblabs.ai.InferenceException
import com.spiralgang.weblabs.ai.InferenceRequest
import com.spiralgang.weblabs.ai.ModelCache
import com.spiralgang.weblabs.ai.PromptBuilder
import com.spiralgang.weblabs.ai.PromptBundle
import com.spiralgang.weblabs.security.SecureCredentialsStore
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import org.json.JSONObject

/**
 * AiManager - AI Integration and Model Management
 *
 * Provides comprehensive AI assistance for mobile development including:
 * - Code generation and completion
 * - Error debugging and resolution
 * - Code optimization for ARM64
 * - Security vulnerability scanning
 * - Performance analysis and recommendations
 */
class AiManager(
    private val context: Context,
    private val credentialsProvider: CredentialsProvider = SecureCredentialsStore(context),
    private val modelCache: ModelCache = ModelCache(),
    private val httpClient: OkHttpClient = OkHttpClient()
) {

    companion object {
        private const val TAG = "AiManager"
        private const val AI_CONFIG_FILE = "ai-config.json"
        private const val DEFAULT_MODEL = "deepseek-coder"
        private const val DEFAULT_MAX_TOKENS = 512
        private const val DEFAULT_TEMPERATURE = 0.2
    }

    private val aiModels = ConcurrentHashMap<String, AIModel>()
    private val inferenceClients = ConcurrentHashMap<String, InferenceClient>()
    private var currentModel: String = DEFAULT_MODEL
    private var aiConfig: JSONObject? = null

    /**
     * Initialize AI Manager with configuration
     */
    suspend fun initialize(): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "Initializing AI Manager for ARM64 development...")

            loadAIConfiguration()
            initializeModels()
            verifyModelAccess()

            Log.i(TAG, "AI Manager initialized successfully")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing AI Manager", e)
            false
        }
    }

    /**
     * Load AI configuration from assets or cached storage
     */
    private fun loadAIConfiguration() {
        try {
            val configFile = File(context.filesDir, "models/$AI_CONFIG_FILE")
            if (configFile.exists()) {
                aiConfig = JSONObject(configFile.readText())
            } else {
                context.assets.open("models/$AI_CONFIG_FILE").use { inputStream ->
                    val configText = inputStream.bufferedReader().readText()
                    aiConfig = JSONObject(configText)
                    configFile.parentFile?.mkdirs()
                    configFile.writeText(configText)
                }
            }

            Log.i(TAG, "AI configuration loaded successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading AI configuration", e)
            createDefaultConfiguration()
        }
    }

    /**
     * Create default AI configuration when none is provided
     */
    private fun createDefaultConfiguration() {
        aiConfig = JSONObject().apply {
            put("models", JSONObject().apply {
                put("deepseek-coder", JSONObject().apply {
                    put("provider", "huggingface")
                    put("endpoint", "https://api-inference.huggingface.co/models/deepseek-ai/deepseek-coder-6.7b-instruct")
                    put("type", "code-generation")
                    put("context_length", 4096)
                })
                put("codellama", JSONObject().apply {
                    put("provider", "huggingface")
                    put("endpoint", "https://api-inference.huggingface.co/models/codellama/CodeLlama-7b-Instruct-hf")
                    put("type", "code-generation")
                    put("context_length", 4096)
                })
            })
            put("default_model", DEFAULT_MODEL)
            put("arm64_optimizations", true)
            put("security_scanning", true)
        }
    }

    private fun modelsConfig(): JSONObject? {
        val config = aiConfig ?: return null
        return when {
            config.has("models") -> config.optJSONObject("models")
            config.has("ai_models") -> config.optJSONObject("ai_models")
            else -> null
        }
    }

    /**
     * Initialize available AI models
     */
    private fun initializeModels() {
        aiModels.clear()
        val modelsConfig = modelsConfig() ?: return
        for (modelName in modelsConfig.keys()) {
            val modelConfig = modelsConfig.getJSONObject(modelName)
            val provider = modelConfig.getString("provider")
            val endpoint = credentialsProvider.getEndpoint(provider, modelConfig.getString("endpoint"))
            val model = AIModel(
                name = modelName,
                provider = provider,
                endpoint = endpoint,
                type = modelConfig.optString("type", "code-generation"),
                contextLength = modelConfig.optInt("context_length", 4096)
            )
            aiModels[modelName] = model
        }

        currentModel = aiConfig?.optString("default_model", DEFAULT_MODEL) ?: DEFAULT_MODEL
        Log.i(TAG, "Initialized ${aiModels.size} AI models")
    }

    /**
     * Verify model access and availability
     */
    private suspend fun verifyModelAccess(): Boolean = withContext(Dispatchers.IO) {
        return@withContext try {
            var hasCredentials = true
            aiModels.values.forEach { model ->
                val apiKey = credentialsProvider.getApiKey(model.provider)
                if (apiKey.isNullOrBlank()) {
                    hasCredentials = false
                    Log.w(TAG, "No API key stored for provider ${model.provider}")
                }
            }
            hasCredentials
        } catch (e: Exception) {
            Log.e(TAG, "Error verifying model access", e)
            false
        }
    }

    /**
     * Generate code based on prompt and context
     */
    suspend fun generateCode(
        prompt: String,
        context: String = "",
        language: String = "kotlin"
    ): String = withContext(Dispatchers.IO) {
        val model = aiModels[currentModel]
            ?: return@withContext "// Error: AI model not available"

        val cacheKey = computeCacheKey("generate", prompt, context, language, model.name)
        modelCache.get(cacheKey)?.let { cached ->
            Log.d(TAG, "Cache hit for generateCode")
            return@withContext cached
        }

        val bundle = PromptBuilder.buildCodeGenerationPrompt(prompt, context, language, model.contextLength)
        val request = buildRequest(model, bundle)

        try {
            val response = runInference(model.provider, cacheKey, request)
            Log.d(TAG, "Received inference response for generateCode")
            response
        } catch (e: InferenceException) {
            Log.e(TAG, "Inference error during code generation", e)
            formatInferenceError(e)
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during code generation", e)
            "// Error generating code: ${e.message}"
        }
    }

    /**
     * Debug and analyze code for issues
     */
    suspend fun debugCode(code: String, error: String): String = withContext(Dispatchers.IO) {
        val model = aiModels[currentModel]
            ?: return@withContext "Error: AI model not available"

        val cacheKey = computeCacheKey("debug", code, error, model.name)
        modelCache.get(cacheKey)?.let { cached ->
            Log.d(TAG, "Cache hit for debugCode")
            return@withContext cached
        }

        val bundle = PromptBuilder.buildDebugPrompt(code, error, model.contextLength)
        val request = buildRequest(model, bundle)

        try {
            val response = runInference(model.provider, cacheKey, request)
            Log.d(TAG, "Received inference response for debugCode")
            response
        } catch (e: InferenceException) {
            Log.e(TAG, "Inference error during debugCode", e)
            formatInferenceError(e)
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during debugCode", e)
            "Error analyzing code: ${e.message}"
        }
    }

    /**
     * Optimize code for ARM64 performance
     */
    suspend fun optimizeForARM64(code: String, targetAPI: Int = 29): String = withContext(Dispatchers.IO) {
        val model = aiModels[currentModel]
            ?: return@withContext code

        val cacheKey = computeCacheKey("optimize", code, targetAPI.toString(), model.name)
        modelCache.get(cacheKey)?.let { cached ->
            Log.d(TAG, "Cache hit for optimizeForARM64")
            return@withContext cached
        }

        val bundle = PromptBuilder.buildOptimizationPrompt(code, targetAPI, model.contextLength)
        val request = buildRequest(model, bundle)

        try {
            val response = runInference(model.provider, cacheKey, request)
            Log.d(TAG, "Received inference response for optimizeForARM64")
            response
        } catch (e: InferenceException) {
            Log.e(TAG, "Inference error during optimizeForARM64", e)
            formatInferenceError(e)
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during optimizeForARM64", e)
            code
        }
    }

    /**
     * Scan code for security vulnerabilities
     */
    suspend fun scanForSecurity(code: String): List<SecurityIssue> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Scanning code for security issues")

            val issues = mutableListOf<SecurityIssue>()

            if (code.contains("System.out.print") || code.contains("Log.d")) {
                issues.add(SecurityIssue("Information Disclosure", "Avoid logging sensitive information"))
            }

            if (code.contains("setJavaScriptEnabled(true)") && !code.contains("allowFileAccessFromFileURLs")) {
                issues.add(SecurityIssue("WebView Security", "Configure WebView security settings properly"))
            }

            issues
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning for security issues", e)
            emptyList()
        }
    }

    /**
     * Get AI model information
     */
    fun getModelInfo(): Map<String, Any> {
        return mapOf(
            "current_model" to currentModel,
            "available_models" to aiModels.keys.toList(),
            "cache_size" to modelCache.size(),
            "arm64_optimized" to true
        )
    }

    /**
     * Switch to different AI model
     */
    fun switchModel(modelName: String): Boolean {
        return if (aiModels.containsKey(modelName)) {
            currentModel = modelName
            Log.i(TAG, "Switched to model: $modelName")
            true
        } else {
            Log.e(TAG, "Model not available: $modelName")
            false
        }
    }

    /**
     * Data class for AI model configuration
     */
    data class AIModel(
        val name: String,
        val provider: String,
        val endpoint: String,
        val type: String,
        val contextLength: Int
    )

    /**
     * Data class for security issues
     */
    data class SecurityIssue(
        val type: String,
        val description: String
    )

    private fun buildRequest(model: AIModel, bundle: PromptBundle): InferenceRequest {
        val prompt = PromptBuilder.renderPrompt(bundle)
        val maxTokens = (model.contextLength / 2).coerceIn(128, DEFAULT_MAX_TOKENS)
        return InferenceRequest(
            provider = model.provider,
            endpoint = model.endpoint,
            model = model.name,
            prompt = prompt,
            maxTokens = maxTokens,
            temperature = DEFAULT_TEMPERATURE
        )
    }

    private suspend fun runInference(provider: String, cacheKey: String, request: InferenceRequest): String {
        val client = inferenceClients.getOrPut(provider.lowercase()) {
            when (provider.lowercase()) {
                "huggingface" -> HuggingFaceInferenceClient(httpClient, credentialsProvider)
                else -> throw IllegalArgumentException("Unsupported AI provider: $provider")
            }
        }

        return client.complete(request).also { response ->
            modelCache.put(cacheKey, response)
        }
    }

    private fun computeCacheKey(vararg parts: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val joined = parts.joinToString(separator = "::")
        val hash = digest.digest(joined.toByteArray())
        return hash.joinToString(separator = "") { byte -> "%02x".format(byte) }
    }

    private fun formatInferenceError(e: InferenceException): String {
        val builder = StringBuilder()
        builder.append("// Inference error: ")
        builder.append(e.message ?: "Unknown error")
        e.statusCode?.let { builder.append(" (HTTP $it)") }
        if (!e.errorBody.isNullOrBlank()) {
            builder.append('\n')
            builder.append("// Provider response: ")
            builder.append(e.errorBody.take(512))
        }
        return builder.toString()
    }
}
