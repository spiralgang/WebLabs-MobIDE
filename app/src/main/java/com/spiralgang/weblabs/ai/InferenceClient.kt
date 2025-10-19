package com.spiralgang.weblabs.ai

data class InferenceRequest(
    val provider: String,
    val endpoint: String,
    val model: String,
    val prompt: String,
    val maxTokens: Int,
    val temperature: Double
)

interface InferenceClient {
    suspend fun complete(request: InferenceRequest): String
}

class InferenceException(
    message: String,
    val statusCode: Int? = null,
    val errorBody: String? = null,
    cause: Throwable? = null
) : Exception(message, cause)
