package com.spiralgang.weblabs

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.webkit.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

/**
 * WebIDEActivity - Browser-based Code Editor Interface
 * 
 * Provides a full-screen web-based IDE interface with:
 * - Code editing with syntax highlighting
 * - File management system
 * - Terminal emulation
 * - AI-assisted development features
 * - ARM64 optimization for mobile development
 */
class WebIDEActivity : AppCompatActivity() {
    
    companion object {
        private const val TAG = "WebIDEActivity"
        private const val IDE_URL = "file:///android_asset/webide/index.html"
    }
    
    private lateinit var webView: WebView
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable immersive full-screen mode
        enableFullScreenMode()
        
        setupWebView()
        
        Log.i(TAG, "WebIDE Activity initialized for ARM64 development")
    }
    
    /**
     * Enable immersive full-screen mode for better development experience
     */
    private fun enableFullScreenMode() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.hide(WindowInsetsCompat.Type.systemBars())
        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }
    
    /**
     * Set up WebView for IDE interface
     */
    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        webView = WebView(this)
        setContentView(webView)
        
        // Configure WebView for optimal IDE performance
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            allowFileAccessFromFileURLs = true
            allowUniversalAccessFromFileURLs = true
            cacheMode = WebSettings.LOAD_DEFAULT
            
            // ARM64 optimization settings
            setSupportZoom(true)
            builtInZoomControls = true
            displayZoomControls = false
            useWideViewPort = true
            loadWithOverviewMode = true
            
            // Performance optimizations for mobile
            setRenderPriority(WebSettings.RenderPriority.HIGH)
            cacheMode = WebSettings.LOAD_CACHE_ELSE_NETWORK
        }
        
        // Set up JavaScript interface for native integration
        webView.addJavaScriptInterface(WebIDEJavaScriptInterface(), "WebLabsIDE")
        
        // Configure WebView client
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                Log.i(TAG, "WebIDE loaded successfully: $url")
                
                // Inject ARM64 device information
                injectDeviceInfo()
            }
            
            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                super.onReceivedError(view, request, error)
                Log.e(TAG, "WebIDE error: ${error?.description}")
            }
        }
        
        // Configure Chrome client for enhanced features
        webView.webChromeClient = object : WebChromeClient() {
            override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                Log.d(TAG, "IDE Console: ${consoleMessage?.message()}")
                return true
            }
            
            override fun onPermissionRequest(request: PermissionRequest?) {
                // Grant necessary permissions for file access and features
                request?.grant(request.resources)
            }
        }
        
        // Load the IDE interface
        webView.loadUrl(IDE_URL)
    }
    
    /**
     * Inject ARM64 device information into the IDE
     */
    private fun injectDeviceInfo() {
        val deviceInfo = """
            window.WebLabsDevice = {
                arch: 'arm64',
                android: true,
                apiLevel: ${android.os.Build.VERSION.SDK_INT},
                manufacturer: '${android.os.Build.MANUFACTURER}',
                model: '${android.os.Build.MODEL}',
                isEmulator: ${isEmulator()},
                cores: ${Runtime.getRuntime().availableProcessors()},
                memory: ${getAvailableMemory()}
            };
            
            // Notify IDE that device info is available
            if (typeof window.onDeviceInfoReady === 'function') {
                window.onDeviceInfoReady(window.WebLabsDevice);
            }
        """.trimIndent()
        
        webView.evaluateJavascript(deviceInfo, null)
    }
    
    /**
     * Check if running on emulator
     */
    private fun isEmulator(): Boolean {
        return (android.os.Build.FINGERPRINT.startsWith("generic") ||
                android.os.Build.FINGERPRINT.startsWith("unknown") ||
                android.os.Build.MODEL.contains("google_sdk") ||
                android.os.Build.MODEL.contains("Emulator") ||
                android.os.Build.MODEL.contains("Android SDK built for x86") ||
                android.os.Build.MANUFACTURER.contains("Genymotion") ||
                android.os.Build.BRAND.startsWith("generic") && android.os.Build.DEVICE.startsWith("generic") ||
                "google_sdk" == android.os.Build.PRODUCT)
    }
    
    /**
     * Get available memory in MB
     */
    private fun getAvailableMemory(): Long {
        val actManager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
        val memInfo = android.app.ActivityManager.MemoryInfo()
        actManager.getMemoryInfo(memInfo)
        return memInfo.availMem / (1024 * 1024) // Convert to MB
    }
    
    /**
     * JavaScript interface for native Android integration
     */
    inner class WebIDEJavaScriptInterface {
        
        @JavascriptInterface
        fun openFile(path: String): String {
            // Interface for file operations from JavaScript
            Log.d(TAG, "File operation requested: $path")
            return ""
        }
        
        @JavascriptInterface
        fun saveFile(path: String, content: String): Boolean {
            // Interface for saving files from JavaScript
            Log.d(TAG, "Save operation requested: $path")
            return true
        }
        
        @JavascriptInterface
        fun executeShellCommand(command: String): String {
            // Interface for shell command execution
            Log.d(TAG, "Shell command requested: $command")
            return ""
        }
        
        @JavascriptInterface
        fun getProjectList(): String {
            // Interface for getting project list
            Log.d(TAG, "Project list requested")
            return "[]"
        }
        
        @JavascriptInterface
        fun invokeAI(prompt: String, context: String): String {
            // Interface for AI assistance
            Log.d(TAG, "AI assistance requested: $prompt")
            return ""
        }
    }
    
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
    
    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }
}