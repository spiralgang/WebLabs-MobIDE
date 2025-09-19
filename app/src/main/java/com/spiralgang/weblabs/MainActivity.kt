package com.spiralgang.weblabs

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import android.view.KeyEvent
import android.webkit.*
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.spiralgang.weblabs.utils.PermissionManager
import com.spiralgang.weblabs.utils.RepositoryDownloader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * MainActivity - Docker Ubuntu Development Environment Launcher
 * 
 * This activity provides the main interface and launches:
 * - Docker Ubuntu 24.04 ARM64 development environment
 * - Code-Server web IDE interface
 * - AI-assisted development commands
 * - Production-grade mobile development workspace
 */
class MainActivity : AppCompatActivity() {
    
    companion object {
        const val TAG = "MainActivity"
    }
    
    private lateinit var webView: WebView
    private lateinit var permissionManager: PermissionManager
    private lateinit var repositoryDownloader: RepositoryDownloader
    private lateinit var dockerManager: DockerManager
    private val activityScope = CoroutineScope(Dispatchers.Main)
    
    // Service connections
    private val alpineServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as AlpineLinuxService.LocalBinder
            alpineService = binder.getService()
            Log.i(TAG, "Alpine Linux service connected")
            initializeShellIDE()
        }
        
        override fun onServiceDisconnected(name: ComponentName?) {
            alpineService = null
            Log.w(TAG, "Alpine Linux service disconnected")
        }
    }
    
    private val shellServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as ShellTerminalService.LocalBinder
            shellService = binder.getService()
            Log.i(TAG, "Shell terminal service connected")
        }
        
        override fun onServiceDisconnected(name: ComponentName?) {
            shellService = null
            Log.w(TAG, "Shell terminal service disconnected")
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.i(TAG, "Starting WebLabs MobIDE MainActivity")
        
        // Initialize permission manager
        permissionManager = PermissionManager(this)
        
        // Setup full-screen immersive mode
        setupFullScreenMode()
        
        // Initialize WebView
        setupWebView()
        
        // Request necessary permissions
        requestPermissions()
        
        // Connect to services
        connectToServices()
    }
    
    private fun setupFullScreenMode() {
        // Enable edge-to-edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Hide system bars for immersive experience
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.systemBarsBehavior = 
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        windowInsetsController.hide(WindowInsetsCompat.Type.systemBars())
    }
    
    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        webView = WebView(this).apply {
            settings.apply {
                // Enable JavaScript for Shell-IDE functionality
                javaScriptEnabled = true
                domStorageEnabled = true
                allowFileAccess = true
                allowContentAccess = true
                allowFileAccessFromFileURLs = true
                allowUniversalAccessFromFileURLs = true
                
                // Enable caching for better performance
                cacheMode = WebSettings.LOAD_DEFAULT
                
                // Enable zoom controls but hide them
                builtInZoomControls = true
                displayZoomControls = false
                
                // Set user agent for mobile optimization
                userAgentString = "$userAgentString WebLabsMobIDE/1.0"
                
                // Enable hardware acceleration for ARM64
                setRenderPriority(WebSettings.RenderPriority.HIGH)
                
                // Mobile-specific settings
                useWideViewPort = true
                loadWithOverviewMode = true
                setSupportZoom(true)
                
                // Database settings for development environment
                databaseEnabled = true
                
                // Geolocation (for development features)
                setGeolocationEnabled(true)
            }
            
            // Set WebView client for handling navigation
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    // Handle custom weblabs:// URLs for shell commands
                    request?.url?.let { uri ->
                        if (uri.scheme == "weblabs") {
                            handleShellCommand(uri.toString())
                            return true
                        }
                    }
                    return false
                }
                
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    Log.i(TAG, "Shell-IDE page loaded: $url")
                    
                    // Inject Alpine Linux interface
                    injectAlpineInterface()
                }
                
                override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                    super.onReceivedError(view, request, error)
                    Log.e(TAG, "WebView error: ${error?.description}")
                }
            }
            
            // Set WebChrome client for enhanced functionality
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                    Log.d(TAG, "JS Console: ${consoleMessage?.message()}")
                    return true
                }
                
                override fun onPermissionRequest(request: PermissionRequest?) {
                    // Grant permissions for development features
                    request?.grant(request.resources)
                }
            }
            
            // Add JavaScript interface for Alpine Linux integration
            addJavascriptInterface(AlpineLinuxJSInterface(), "AlpineLinux")
            addJavascriptInterface(ShellTerminalJSInterface(), "ShellTerminal")
            addJavascriptInterface(AIAssistantJSInterface(), "AIAssistant")
        }
        
        setContentView(webView)
    }
    
    private fun requestPermissions() {
        activityScope.launch {
            permissionManager.requestAllPermissions { granted ->
                if (granted) {
                    Log.i(TAG, "All permissions granted")
                    loadShellIDE()
                } else {
                    Log.w(TAG, "Some permissions denied")
                    Toast.makeText(this@MainActivity, 
                        "Some features may not work without permissions", 
                        Toast.LENGTH_LONG).show()
                    loadShellIDE()
                }
            }
        }
    }
    
    private fun connectToServices() {
        // Connect to Alpine Linux service
        val alpineIntent = Intent(this, AlpineLinuxService::class.java)
        bindService(alpineIntent, alpineServiceConnection, BIND_AUTO_CREATE)
        
        // Connect to Shell Terminal service
        val shellIntent = Intent(this, ShellTerminalService::class.java)
        bindService(shellIntent, shellServiceConnection, BIND_AUTO_CREATE)
    }
    
    private fun loadShellIDE() {
        Log.i(TAG, "Loading Shell-IDE interface...")
        
        // Load the enhanced WebLabs MobIDE with Alpine Linux integration
        webView.loadUrl("file:///android_asset/weblabs_mobide_alpine.html")
    }
    
    private fun initializeShellIDE() {
        Log.i(TAG, "Initializing Shell-IDE with Alpine Linux...")
        
        activityScope.launch {
            try {
                // Initialize Alpine Linux environment
                alpineService?.initializeEnvironment()
                
                // Setup development tools
                alpineService?.setupDevelopmentTools()
                
                // Start shell terminal
                shellService?.startShell()
                
                Log.i(TAG, "Shell-IDE initialized successfully")
                
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize Shell-IDE", e)
                Toast.makeText(this@MainActivity, 
                    "Failed to initialize development environment: ${e.message}", 
                    Toast.LENGTH_LONG).show()
            }
        }
    }
    
    private fun injectAlpineInterface() {
        // Inject JavaScript to connect WebView with Alpine Linux
        val js = """
            // Alpine Linux integration
            window.Alpine = {
                executeCommand: function(command) {
                    return AlpineLinux.executeCommand(command);
                },
                getSystemInfo: function() {
                    return AlpineLinux.getSystemInfo();
                },
                installPackage: function(package) {
                    return AlpineLinux.installPackage(package);
                }
            };
            
            // Shell Terminal integration
            window.Shell = {
                execute: function(command) {
                    return ShellTerminal.execute(command);
                },
                getHistory: function() {
                    return ShellTerminal.getHistory();
                },
                getCurrentDirectory: function() {
                    return ShellTerminal.getCurrentDirectory();
                }
            };
            
            // AI Assistant integration
            window.AI = {
                askAssistant: function(prompt) {
                    return AIAssistant.askAssistant(prompt);
                },
                generateCode: function(description) {
                    return AIAssistant.generateCode(description);
                },
                refactorCode: function(code, instructions) {
                    return AIAssistant.refactorCode(code, instructions);
                }
            };
            
            // Notify that native interfaces are ready
            if (typeof onNativeInterfaceReady === 'function') {
                onNativeInterfaceReady();
            }
        """.trimIndent()
        
        webView.evaluateJavascript(js) { result ->
            Log.d(TAG, "Alpine interface injected: $result")
        }
    }
    
    private fun handleShellCommand(url: String) {
        Log.i(TAG, "Handling shell command: $url")
        
        activityScope.launch {
            try {
                // Parse weblabs://mobide/command?params URL
                val uri = android.net.Uri.parse(url)
                val command = uri.path?.removePrefix("/")
                val params = uri.queryParameterNames.associateWith { uri.getQueryParameter(it) }
                
                when (command) {
                    "execute" -> {
                        val cmd = params["cmd"] ?: return@launch
                        shellService?.executeCommand(cmd)
                    }
                    "install" -> {
                        val pkg = params["package"] ?: return@launch
                        alpineService?.installPackage(pkg)
                    }
                    "ai" -> {
                        val prompt = params["prompt"] ?: return@launch
                        // Handle AI assistant request
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Failed to handle shell command", e)
            }
        }
    }
    
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Handle back button for WebView navigation
        if (keyCode == KeyEvent.KEYCODE_BACK && webView.canGoBack()) {
            webView.goBack()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Unbind services
        unbindService(alpineServiceConnection)
        unbindService(shellServiceConnection)
        
        // Cleanup WebView
        webView.destroy()
    }
    
    // JavaScript Interface Classes
    inner class AlpineLinuxJSInterface {
        @JavascriptInterface
        fun executeCommand(command: String): String {
            return alpineService?.executeCommand(command) ?: "Service not available"
        }
        
        @JavascriptInterface
        fun getSystemInfo(): String {
            return alpineService?.getSystemInfo() ?: "{\"status\":\"unavailable\"}"
        }
        
        @JavascriptInterface
        fun installPackage(packageName: String): Boolean {
            return alpineService?.installPackage(packageName) ?: false
        }
    }
    
    inner class ShellTerminalJSInterface {
        @JavascriptInterface
        fun execute(command: String): String {
            return shellService?.executeCommand(command) ?: "Terminal not available"
        }
        
        @JavascriptInterface
        fun getHistory(): String {
            return shellService?.getCommandHistory() ?: "[]"
        }
        
        @JavascriptInterface
        fun getCurrentDirectory(): String {
            return shellService?.getCurrentDirectory() ?: "/data/data/com.spiralgang.weblabs.mobide"
        }
    }
    
    inner class AIAssistantJSInterface {
        @JavascriptInterface
        fun askAssistant(prompt: String): String {
            // Integrate with AI assistant service
            return "AI response placeholder for: $prompt"
        }
        
        @JavascriptInterface
        fun generateCode(description: String): String {
            // Generate code using AI
            return "// Generated code for: $description"
        }
        
        @JavascriptInterface
        fun refactorCode(code: String, instructions: String): String {
            // Refactor code using AI
            return "// Refactored code based on: $instructions"
        }
    }
}