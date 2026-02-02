package com.spiralgang.weblabs

import com.spiralgang.weblabs.ai.CredentialsProvider
import com.spiralgang.weblabs.ai.HuggingFaceInferenceClient
import com.spiralgang.weblabs.ai.InferenceException
import com.spiralgang.weblabs.ai.InferenceRequest
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class HuggingFaceInferenceClientTest {

    private lateinit var server: MockWebServer
    private lateinit var client: HuggingFaceInferenceClient

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        val provider = object : CredentialsProvider {
            override fun getApiKey(provider: String): String? = "test-key"
            override fun saveApiKey(provider: String, apiKey: String) {}
            override fun getEndpoint(provider: String, fallback: String): String = server.url("/").toString()
            override fun saveEndpoint(provider: String, endpoint: String) {}
        }
        client = HuggingFaceInferenceClient(OkHttpClient(), provider)
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun `complete returns generated text on success`() = runTest {
        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setBody("[{\"generated_text\":\"result text\"}]")
        )

        val response = client.complete(
            InferenceRequest(
                provider = "huggingface",
                endpoint = server.url("/").toString(),
                model = "test-model",
                prompt = "Generate something",
                maxTokens = 128,
                temperature = 0.1
            )
        )

        assertEquals("result text", response)
    }

    @Test
    fun `complete throws detailed exception on http error`() = runTest {
        val errorBody = "{\"error\":\"rate limited\"}"
        server.enqueue(
            MockResponse()
                .setResponseCode(429)
                .setBody(errorBody)
        )

        try {
            client.complete(
                InferenceRequest(
                    provider = "huggingface",
                    endpoint = server.url("/").toString(),
                    model = "test-model",
                    prompt = "Generate",
                    maxTokens = 64,
                    temperature = 0.2
                )
            )
        } catch (e: InferenceException) {
            assertEquals(429, e.statusCode)
            assertTrue(e.errorBody?.contains("rate limited") == true)
            return@runTest
        }

        throw AssertionError("Expected InferenceException to be thrown")
    }
}
