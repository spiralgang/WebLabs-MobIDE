/**
 * WebLabs MobIDE - ARM64 Mobile Utility Functions
 * Optimized utilities for Android ARM64 mobile development environment
 */

class ARM64MobileUtils {
    constructor() {
        this.isAndroid = /Android/i.test(navigator.userAgent);
        this.isARM64 = /aarch64|arm64/i.test(navigator.userAgent);
        this.isMobile = /Mobi|Android/i.test(navigator.userAgent);
        this.deviceInfo = this.getDeviceInfo();
    }
    
    /**
     * Enhanced Android compatibility check for ARM64 devices
     */
    androidCompatCheck() {
        const ua = navigator.userAgent;
        const checks = {
            android: /Android/i.test(ua),
            android10Plus: /Android\s+(1[0-9]|[2-9][0-9])/i.test(ua),
            arm64: /aarch64|arm64/i.test(ua),
            linux: /Linux/i.test(ua),
            webview: /wv/i.test(ua),
            chrome: /Chrome/i.test(ua)
        };
        
        return {
            compatible: checks.android && (checks.android10Plus || checks.arm64),
            details: checks,
            score: Object.values(checks).filter(Boolean).length,
            recommendation: this.getCompatibilityRecommendation(checks)
        };
    }
    
    getCompatibilityRecommendation(checks) {
        if (checks.android && checks.android10Plus && checks.arm64) {
            return 'Fully compatible - Optimal ARM64 Android environment';
        } else if (checks.android && checks.arm64) {
            return 'Compatible - ARM64 Android detected';
        } else if (checks.android) {
            return 'Partially compatible - Android detected but may lack ARM64 optimizations';
        } else {
            return 'Limited compatibility - Non-Android environment';
        }
    }
    
    /**
     * Get comprehensive ARM64 device information
     */
    getDeviceInfo() {
        return {
            architecture: this.isARM64 ? 'aarch64' : 'x86_64',
            platform: navigator.platform,
            userAgent: navigator.userAgent,
            isMobile: this.isMobile,
            isAndroid: this.isAndroid,
            isARM64: this.isARM64,
            memory: navigator.deviceMemory || 'unknown',
            cores: navigator.hardwareConcurrency || 'unknown',
            language: navigator.language,
            cookieEnabled: navigator.cookieEnabled,
            onLine: navigator.onLine,
            screen: {
                width: screen.width,
                height: screen.height,
                pixelRatio: window.devicePixelRatio || 1
            }
        };
    }
    
    /**
     * ARM64 optimized memory management for mobile
     */
    optimizeMemoryUsage() {
        if (this.isMobile) {
            // Force garbage collection for mobile devices
            if (window.gc) {
                window.gc();
            }
            
            // Limit cache sizes for mobile ARM64 optimization
            this.setCacheLimit('codeCache', 50);
            this.setCacheLimit('aiCache', 20);
            
            // Clear unnecessary data
            this.clearOldCacheEntries();
        }
    }
    
    setCacheLimit(cacheType, limit) {
        const cacheKey = `${cacheType}_limit`;
        localStorage.setItem(cacheKey, limit.toString());
    }
    
    clearOldCacheEntries() {
        const maxAge = 24 * 60 * 60 * 1000; // 24 hours
        const now = Date.now();
        
        for (let key in localStorage) {
            if (key.endsWith('_timestamp')) {
                const timestamp = parseInt(localStorage.getItem(key) || '0');
                if (now - timestamp > maxAge) {
                    const dataKey = key.replace('_timestamp', '');
                    localStorage.removeItem(key);
                    localStorage.removeItem(dataKey);
                }
            }
        }
    }
    
    /**
     * ARM64 performance monitoring
     */
    getPerformanceMetrics() {
        const performance = window.performance;
        const memory = performance.memory || {};
        
        return {
            timing: {
                navigationStart: performance.timing?.navigationStart || 0,
                loadEventEnd: performance.timing?.loadEventEnd || 0,
                domContentLoaded: performance.timing?.domContentLoadedEventEnd || 0,
                loadTime: (performance.timing?.loadEventEnd || 0) - (performance.timing?.navigationStart || 0)
            },
            memory: {
                used: memory.usedJSHeapSize || 0,
                total: memory.totalJSHeapSize || 0,
                limit: memory.jsHeapSizeLimit || 0,
                usedMB: Math.round((memory.usedJSHeapSize || 0) / 1024 / 1024),
                totalMB: Math.round((memory.totalJSHeapSize || 0) / 1024 / 1024),
                usagePercent: memory.totalJSHeapSize ? Math.round((memory.usedJSHeapSize / memory.totalJSHeapSize) * 100) : 0
            },
            navigation: performance.navigation?.type || 0,
            arm64Optimized: this.isARM64
        };
    }
}

// Create singleton instance
const arm64Utils = new ARM64MobileUtils();

// Legacy and enhanced compatibility functions
export function androidCompatCheck() {
    return arm64Utils.androidCompatCheck();
}

export function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text || '';
    return div.innerHTML;
}

export function formatTime(date) {
    return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    }).format(date || new Date());
}

export function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
}

export function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

export function throttle(func, limit) {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// ARM64 specific exports
export const ARM64Utils = arm64Utils;
export const deviceInfo = arm64Utils.deviceInfo;
export const isARM64 = arm64Utils.isARM64;
export const isMobile = arm64Utils.isMobile;
export const isAndroid = arm64Utils.isAndroid;

// Performance and optimization
export const getPerformanceMetrics = () => arm64Utils.getPerformanceMetrics();
export const optimizeMemoryUsage = () => arm64Utils.optimizeMemoryUsage();

// Default export
export default arm64Utils;