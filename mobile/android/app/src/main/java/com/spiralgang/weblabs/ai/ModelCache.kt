package com.spiralgang.weblabs.ai

import java.util.LinkedHashMap
import java.util.concurrent.TimeUnit

/**
 * Thread-safe LRU cache with time-based eviction tailored for inference responses.
 */
class ModelCache(
    private val maxEntries: Int = 48,
    private val maxEntryAgeMillis: Long = TimeUnit.MINUTES.toMillis(10)
) {

    private val lock = Any()
    private val cache = object : LinkedHashMap<String, CacheEntry>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, CacheEntry>?): Boolean {
            return size > maxEntries
        }
    }

    fun get(key: String): String? {
        synchronized(lock) {
            val entry = cache[key] ?: return null
            if (isExpired(entry)) {
                cache.remove(key)
                return null
            }
            return entry.value
        }
    }

    fun put(key: String, value: String) {
        synchronized(lock) {
            cache[key] = CacheEntry(value, System.currentTimeMillis())
            removeExpiredLocked()
        }
    }

    fun clear() {
        synchronized(lock) {
            cache.clear()
        }
    }

    fun size(): Int {
        synchronized(lock) {
            removeExpiredLocked()
            return cache.size
        }
    }

    private fun removeExpiredLocked() {
        val iterator = cache.entries.iterator()
        val now = System.currentTimeMillis()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (now - entry.value.timestamp > maxEntryAgeMillis) {
                iterator.remove()
            }
        }
    }

    private fun isExpired(entry: CacheEntry): Boolean {
        return System.currentTimeMillis() - entry.timestamp > maxEntryAgeMillis
    }

    private data class CacheEntry(val value: String, val timestamp: Long)
}
