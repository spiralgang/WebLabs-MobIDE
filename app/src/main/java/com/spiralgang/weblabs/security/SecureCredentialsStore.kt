package com.spiralgang.weblabs.security

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.spiralgang.weblabs.ai.CredentialsProvider

class SecureCredentialsStore(context: Context) : CredentialsProvider {

    private val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        PREFS_NAME,
        MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    override fun getApiKey(provider: String): String? {
        return sharedPreferences.getString(apiKeyKey(provider), null)
    }

    override fun saveApiKey(provider: String, apiKey: String) {
        sharedPreferences.edit().putString(apiKeyKey(provider), apiKey).apply()
    }

    override fun getEndpoint(provider: String, fallback: String): String {
        return sharedPreferences.getString(endpointKey(provider), fallback) ?: fallback
    }

    override fun saveEndpoint(provider: String, endpoint: String) {
        sharedPreferences.edit().putString(endpointKey(provider), endpoint).apply()
    }

    private fun apiKeyKey(provider: String) = "api_key_${provider.lowercase()}"

    private fun endpointKey(provider: String) = "endpoint_${provider.lowercase()}"

    companion object {
        private const val PREFS_NAME = "ai_credentials"
    }
}
