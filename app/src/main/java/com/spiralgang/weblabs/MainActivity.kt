package com.spiralgang.weblabs

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.util.Log
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
    
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.i(TAG, "🚀 Starting WebLabs-MobIDE with Docker Ubuntu environment")
        
        // Initialize managers
        permissionManager = PermissionManager(this)
        repositoryDownloader = RepositoryDownloader(this) 
        dockerManager = DockerManager(this)
        
        // Setup WebView
        setupWebView()
        
        // Show welcome and initialize
        showWelcomeScreen()
        
        activityScope.launch {
            initializeEnvironment()
        }
    }
    
    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        webView = WebView(this).apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                allowFileAccess = true
                allowContentAccess = true
                allowFileAccessFromFileURLs = true
                allowUniversalAccessFromFileURLs = true
                userAgentString = "WebLabs-MobIDE/2.0-Docker"
            }
            
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url.toString()
                    
                    when {
                        url.startsWith("webide://") -> {
                            launchWebIDE()
                            return true
                        }
                        url.startsWith("docker://") -> {
                            handleDockerCommand(url)
                            return true
                        }
                    }
                    
                    return false
                }
            }
            
            addJavaScriptInterface(WebLabsJSInterface(), "WebLabs")
        }
        
        setContentView(webView)
    }
    
    private suspend fun initializeEnvironment() {
        try {
            val dockerSuccess = dockerManager.initializeDocker()
            
            if (dockerSuccess) {
                showDockerInterface()
            } else {
                showLocalInterface()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing environment", e)
            showLocalInterface()
        }
    }
    
    private fun showWelcomeScreen() {
        val html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        background: linear-gradient(135deg, #0f0f23, #1a1a2e);
                        color: #00ff41;
                        font-family: 'Courier New', monospace;
                        margin: 0;
                        padding: 20px;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: center;
                        min-height: 100vh;
                        text-align: center;
                    }
                    .logo {
                        font-size: 2.5em;
                        font-weight: bold;
                        margin-bottom: 20px;
                        text-shadow: 0 0 20px #00ff41;
                    }
                    .feature {
                        background: rgba(0, 255, 65, 0.1);
                        border: 1px solid #00ff41;
                        border-radius: 10px;
                        padding: 15px;
                        margin: 10px;
                    }
                    .button {
                        background: #00ff41;
                        color: #000;
                        border: none;
                        padding: 15px 30px;
                        font-size: 1.1em;
                        font-weight: bold;
                        border-radius: 25px;
                        cursor: pointer;
                        margin: 10px;
                        text-decoration: none;
                        display: inline-block;
                    }
                    .spinner {
                        border: 3px solid #1a1a2e;
                        border-top: 3px solid #00ff41;
                        border-radius: 50%;
                        width: 40px;
                        height: 40px;
                        animation: spin 1s linear infinite;
                        margin: 20px auto;
                    }
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                </style>
            </head>
            <body>
                <div class="logo">🚀 WebLabs-MobIDE</div>
                <div>Mobile-First Quantum Development Environment</div>
                
                <div class="feature">🐳 Docker Ubuntu 24.04 ARM64</div>
                <div class="feature">⚡ Code-Server IDE</div>
                <div class="feature">🤖 AI Integration</div>
                <div class="feature">📱 Mobile Optimized</div>
                
                <div class="spinner"></div>
                <p>Initializing environment...</p>
                
                <a href="webide://" class="button">🌐 Launch Web IDE</a>
            </body>
            </html>
        """.trimIndent()
        
        runOnUiThread {
            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
        }
    }
    
    private fun showDockerInterface() {
        runOnUiThread {
            val html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body {
                            background: linear-gradient(135deg, #0f0f23, #1a1a2e);
                            color: #00ff41;
                            font-family: 'Courier New', monospace;
                            margin: 0;
                            padding: 20px;
                            text-align: center;
                        }
                        .header {
                            font-size: 2em;
                            margin-bottom: 20px;
                            text-shadow: 0 0 10px #00ff41;
                        }
                        .status {
                            background: rgba(0, 255, 65, 0.2);
                            border: 1px solid #00ff41;
                            border-radius: 10px;
                            padding: 20px;
                            margin: 20px 0;
                        }
                        .button {
                            background: #00ff41;
                            color: #000;
                            border: none;
                            padding: 15px 30px;
                            font-size: 1.1em;
                            font-weight: bold;
                            border-radius: 25px;
                            cursor: pointer;
                            margin: 10px;
                        }
                    </style>
                </head>
                <body>
                    <div class="header">🐳 Docker Environment Ready</div>
                    
                    <div class="status">
                        <h3>✅ Ubuntu 24.04 ARM64 Container</h3>
                        <p>Code-Server IDE accessible at localhost:8080</p>
                        <p>Docker container is running and ready for development</p>
                    </div>
                    
                    <button class="button" onclick="location.href='http://localhost:8080'">
                        🌐 Open Code-Server IDE
                    </button>
                    
                    <button class="button" onclick="WebLabs.launchWebIDE()">
                        🚀 Launch WebLabs IDE
                    </button>
                </body>
                </html>
            """.trimIndent()
            
            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
        }
    }
    
    private fun showLocalInterface() {
        runOnUiThread {
            webView.loadUrl("file:///android_asset/webide/index.html")
        }
    }
    
    private fun launchWebIDE() {
        val intent = Intent(this, WebIDEActivity::class.java)
        startActivity(intent)
    }
    
    private fun handleDockerCommand(url: String) {
        activityScope.launch {
            try {
                val command = url.removePrefix("docker://")
                val result = when (command) {
                    "status" -> dockerManager.getContainerStatus()
                    "start" -> dockerManager.startContainerPublic()
                    "stop" -> dockerManager.stopContainer()
                    else -> "Unknown command: $command"
                }
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Docker: $result", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Docker error: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }
    }
    
    private inner class WebLabsJSInterface {
        @JavascriptInterface
        fun launchWebIDE() {
            runOnUiThread {
                this@MainActivity.launchWebIDE()
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        dockerManager.cleanup()
    }
}