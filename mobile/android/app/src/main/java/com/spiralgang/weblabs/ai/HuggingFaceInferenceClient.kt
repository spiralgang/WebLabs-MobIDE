package com.spiralgang.weblabs.ai

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject

interface CredentialsProvider {
    fun getApiKey(provider: String): String?
    fun saveApiKey(provider: String, apiKey: String)
    fun getEndpoint(provider: String, fallback: String): String
    fun saveEndpoint(provider: String, endpoint: String)
}

class HuggingFaceInferenceClient(
    private val httpClient: OkHttpClient,
    private val credentialsProvider: CredentialsProvider
) : InferenceClient {

    override suspend fun complete(request: InferenceRequest): String = withContext(Dispatchers.IO) {
        val apiKey = credentialsProvider.getApiKey(request.provider)
            ?: throw InferenceException("Missing API key for provider ${request.provider}")

        val endpoint = credentialsProvider.getEndpoint(request.provider, request.endpoint)

        val payload = buildPayload(request.prompt, request.maxTokens, request.temperature)
        val response = httpClient.newCall(
            Request.Builder()
                .url(endpoint)
                .addHeader("Authorization", "Bearer $apiKey")
                .addHeader("Accept", "application/json")
                .post(payload.toString().toRequestBody(JSON_MEDIA_TYPE))
                .build()
        ).execute()

        response.use { httpResponse ->
            val body = httpResponse.body?.string()
            if (!httpResponse.isSuccessful) {
                throw InferenceException(
                    message = "Inference request failed with HTTP ${httpResponse.code}",
                    statusCode = httpResponse.code,
                    errorBody = body
                )
            }

            if (body.isNullOrBlank()) {
                throw InferenceException("Inference response did not include a body", httpResponse.code)
            }

            return@withContext parseResponse(body)
        }
    }

    private fun buildPayload(prompt: String, maxTokens: Int, temperature: Double): JSONObject {
        val parameters = JSONObject().apply {
            put("max_new_tokens", maxTokens)
            put("temperature", temperature)
            put("return_full_text", false)
        }

        return JSONObject().apply {
            put("inputs", prompt)
            put("parameters", parameters)
        }
    }

    private fun parseResponse(body: String): String {
        val json = try {
            JSONArray(body)
        } catch (e: Exception) {
            throw InferenceException("Unable to parse inference response", cause = e, errorBody = body)
        }

        if (json.length() == 0) {
            throw InferenceException("Inference response was empty", errorBody = body)
        }

        val generatedText = json.optJSONObject(0)?.optString("generated_text")
        if (generatedText.isNullOrBlank()) {
            throw InferenceException("Inference response missing generated_text field", errorBody = body)
        }

        return generatedText.trim()
    }

    companion object {
        private val JSON_MEDIA_TYPE = "application/json".toMediaType()
    }
}
