package com.spiralgang.weblabs

import com.spiralgang.weblabs.ai.PromptBuilder
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PromptBuilderTest {

    @Test
    fun `renderPrompt includes chunk headers and trims context`() {
        val context = buildString {
            repeat(200) {
                append("line-$it ")
            }
        }

        val bundle = PromptBuilder.buildCodeGenerationPrompt(
            prompt = "Create a networking helper",
            context = context,
            language = "Kotlin",
            maxContextLength = 512
        )

        val rendered = PromptBuilder.renderPrompt(bundle)

        assertTrue(rendered.contains("Context chunk 1:"))
        assertFalse("Rendered prompt should limit chunk count", rendered.contains("Context chunk 5:"))
        assertTrue(rendered.contains("Generate production-ready kotlin code"))
    }

    @Test
    fun `debug prompt contains error message`() {
        val bundle = PromptBuilder.buildDebugPrompt(
            code = "fun broken() = error(\"boom\")",
            error = "NullPointerException",
            maxContextLength = 256
        )

        val rendered = PromptBuilder.renderPrompt(bundle)

        assertTrue(rendered.contains("Error message:"))
        assertTrue(rendered.contains("NullPointerException"))
    }
}
