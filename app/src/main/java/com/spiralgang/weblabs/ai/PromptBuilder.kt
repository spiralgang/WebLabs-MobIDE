package com.spiralgang.weblabs.ai

internal data class PromptBundle(
    val systemPrompt: String,
    val contextChunks: List<String>,
    val userPrompt: String
)

internal object PromptBuilder {

    private const val SYSTEM_PROMPT = "You are an AI assistant specializing in Android and ARM64 development."

    fun buildCodeGenerationPrompt(
        prompt: String,
        context: String,
        language: String,
        maxContextLength: Int
    ): PromptBundle {
        val normalizedLanguage = language.ifBlank { "kotlin" }.lowercase()
        val userPrompt = buildString {
            appendLine("Generate production-ready $normalizedLanguage code for the user's request.")
            appendLine("The code must run efficiently on Android API 29+ devices with ARM64 (AArch64) processors.")
            appendLine("Follow Android security best practices and highlight any important caveats.")
            appendLine()
            appendLine("User request:")
            appendLine(prompt)
        }.trim()

        return PromptBundle(
            systemPrompt = SYSTEM_PROMPT,
            contextChunks = chunkContext(context, maxContextLength),
            userPrompt = userPrompt
        )
    }

    fun buildDebugPrompt(
        code: String,
        error: String,
        maxContextLength: Int
    ): PromptBundle {
        val userPrompt = buildString {
            appendLine("Analyze the provided code and error output.")
            appendLine("Explain the root cause and provide a concise patch that fixes the issue for ARM64 Android deployments.")
            appendLine()
            appendLine("Error message:")
            appendLine(error)
            appendLine()
            appendLine("Code snippet:")
            appendLine(code)
        }.trim()

        return PromptBundle(
            systemPrompt = "$SYSTEM_PROMPT Focus on diagnosing build/runtime issues.",
            contextChunks = chunkContext(code, maxContextLength),
            userPrompt = userPrompt
        )
    }

    fun buildOptimizationPrompt(
        code: String,
        targetApi: Int,
        maxContextLength: Int
    ): PromptBundle {
        val userPrompt = buildString {
            appendLine("Review the code and provide ARM64-specific optimizations.")
            appendLine("Explain why each recommendation helps on Android API $targetApi and provide code when appropriate.")
            appendLine()
            appendLine("Code snippet:")
            appendLine(code)
        }.trim()

        return PromptBundle(
            systemPrompt = "$SYSTEM_PROMPT Prioritize measurable performance gains.",
            contextChunks = chunkContext(code, maxContextLength),
            userPrompt = userPrompt
        )
    }

    fun renderPrompt(bundle: PromptBundle): String {
        val builder = StringBuilder()
        builder.appendLine(bundle.systemPrompt)
        if (bundle.contextChunks.isNotEmpty()) {
            bundle.contextChunks.forEachIndexed { index, chunk ->
                builder.appendLine()
                builder.appendLine("Context chunk ${index + 1}:")
                builder.appendLine(chunk)
            }
        }
        builder.appendLine()
        builder.appendLine(bundle.userPrompt)
        return builder.toString().trim()
    }

    private fun chunkContext(context: String, maxContextLength: Int): List<String> {
        if (context.isBlank()) return emptyList()
        val sanitized = context.trim()
        val chunkSize = maxContextLength.coerceAtLeast(512)
        val chunks = mutableListOf<String>()
        var index = 0
        while (index < sanitized.length && chunks.size < 4) {
            val end = (index + chunkSize).coerceAtMost(sanitized.length)
            chunks.add(sanitized.substring(index, end))
            index = end
        }
        return chunks
    }
}
