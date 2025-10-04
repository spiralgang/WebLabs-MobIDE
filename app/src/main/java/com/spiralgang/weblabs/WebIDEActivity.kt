package com.spiralgang.weblabs

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.webkit.*
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

/**
 * WebIDEActivity - Code-Server Docker Ubuntu Interface
 * 
 * Provides access to the Code-Server web IDE running in Docker Ubuntu container.
 * Falls back to local WebIDE assets if Docker environment is not available.
 */
class WebIDEActivity : AppCompatActivity() {
    
    companion object {
        const val TAG = "WebIDEActivity"
    }
    
    private lateinit var webView: WebView
    private lateinit var dockerManager: DockerManager
    
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.i(TAG, "🌐 Starting WebIDE Activity")
        
        dockerManager = DockerManager(this)
        
        setupWebView()
        loadWebIDE()
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
                userAgentString = "WebLabs-MobIDE/2.0-Docker-IDE"
                loadWithOverviewMode = true
                useWideViewPort = true
                builtInZoomControls = true
                displayZoomControls = false
            }
            
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url.toString()
                    
                    when {
                        url.startsWith("file://") -> return false
                        url.startsWith("http://localhost:8080") -> return false
                        url.startsWith("https://localhost:8080") -> return false
                    }
                    
                    return true
                }
                
                override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                    super.onReceivedError(view, request, error)
                    
                    if (request?.url.toString().contains("localhost:8080")) {
                        Log.w(TAG, "Code-Server not accessible, loading local WebIDE")
                        loadLocalWebIDE()
                    }
                }
            }
            
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                    Log.d(TAG, "WebIDE Console: ${consoleMessage?.message()}")
                    return true
                }
            }
        }
        
        setContentView(webView)
    }
    
    private fun loadWebIDE() {
        try {
            // First try to load Code-Server
            Log.i(TAG, "🐳 Attempting to load Code-Server at localhost:8080")
            webView.loadUrl("http://localhost:8080")
            
            // Set a timeout to fallback to local IDE
            webView.postDelayed({
                if (webView.url == "http://localhost:8080" && webView.progress < 100) {
                    Log.w(TAG, "Code-Server timeout, loading local WebIDE")
                    loadLocalWebIDE()
                }
            }, 5000)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error loading WebIDE", e)
            loadLocalWebIDE()
        }
    }
    
    private fun loadLocalWebIDE() {
        try {
            Log.i(TAG, "📱 Loading local WebIDE interface")
            
            val html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>WebLabs-MobIDE - Local Interface</title>
                    <style>
                        body {
                            background: linear-gradient(135deg, #0f0f23, #1a1a2e);
                            color: #00ff41;
                            font-family: 'Courier New', monospace;
                            margin: 0;
                            padding: 20px;
                            min-height: 100vh;
                        }
                        .header {
                            text-align: center;
                            font-size: 2em;
                            margin-bottom: 30px;
                            text-shadow: 0 0 10px #00ff41;
                        }
                        .panel {
                            background: rgba(0, 255, 65, 0.1);
                            border: 1px solid #00ff41;
                            border-radius: 10px;
                            padding: 20px;
                            margin: 20px 0;
                        }
                        .button {
                            background: #00ff41;
                            color: #000;
                            border: none;
                            padding: 12px 25px;
                            font-size: 1em;
                            font-weight: bold;
                            border-radius: 20px;
                            cursor: pointer;
                            margin: 10px 5px;
                            display: inline-block;
                            text-decoration: none;
                        }
                        .terminal {
                            background: #000;
                            color: #00ff41;
                            padding: 15px;
                            border-radius: 8px;
                            font-family: 'Courier New', monospace;
                            margin: 10px 0;
                            min-height: 200px;
                            overflow-y: auto;
                        }
                        .file-editor {
                            background: #1a1a2e;
                            border: 1px solid #00ff41;
                            border-radius: 8px;
                            min-height: 300px;
                            margin: 10px 0;
                        }
                        textarea {
                            width: 100%;
                            height: 280px;
                            background: #1a1a2e;
                            color: #00ff41;
                            border: none;
                            padding: 15px;
                            font-family: 'Courier New', monospace;
                            border-radius: 8px;
                            resize: vertical;
                        }
                        .status {
                            color: #ff6b35;
                            font-weight: bold;
                        }
                    </style>
                </head>
                <body>
                    <div class="header">🌐 WebLabs-MobIDE - Local Interface</div>
                    
                    <div class="panel">
                        <h3>📊 Environment Status</h3>
                        <p class="status">🐳 Docker: Not Available (using local fallback)</p>
                        <p>📱 Platform: Android Mobile IDE</p>
                        <p>🔧 Mode: Local Development Environment</p>
                        
                        <button class="button" onclick="location.reload()">🔄 Retry Docker</button>
                        <button class="button" onclick="toggleTerminal()">💻 Terminal</button>
                        <button class="button" onclick="toggleEditor()">📝 Editor</button>
                    </div>
                    
                    <div class="panel" id="terminal-panel" style="display: none;">
                        <h3>💻 Local Terminal</h3>
                        <div class="terminal" id="terminal">
                            <div>WebLabs-MobIDE Local Terminal v2.0</div>
                            <div>Docker Ubuntu environment not available</div>
                            <div>Running in local Android mode</div>
                            <div>&gt; Type 'help' for available commands</div>
                            <div id="terminal-output"></div>
                            <div>
                                <span>&gt; </span>
                                <input type="text" id="terminal-input" style="background: transparent; border: none; color: #00ff41; outline: none; width: 80%;" onkeypress="handleCommand(event)">
                            </div>
                        </div>
                    </div>
                    
                    <div class="panel" id="editor-panel" style="display: none;">
                        <h3>📝 File Editor</h3>
                        <p>Filename: <input type="text" id="filename" value="project.txt" style="background: #1a1a2e; color: #00ff41; border: 1px solid #00ff41; padding: 5px; border-radius: 5px;"></p>
                        <div class="file-editor">
                            <textarea id="editor" placeholder="Enter your code here...">// WebLabs-MobIDE Local Editor
// Docker Ubuntu environment not available
// This is a fallback local editor

console.log("Hello from WebLabs-MobIDE!");

// To access full Docker environment:
// 1. Ensure Docker is installed
// 2. Restart the application
// 3. Wait for container initialization
</textarea>
                        </div>
                        <button class="button" onclick="saveFile()">💾 Save</button>
                        <button class="button" onclick="loadFile()">📂 Load</button>
                    </div>
                    
                    <div class="panel">
                        <h3>🚀 Quick Actions</h3>
                        <button class="button" onclick="showInfo()">ℹ️ Info</button>
                        <button class="button" onclick="showHelp()">❓ Help</button>
                        <button class="button" onclick="goBack()">⬅️ Back</button>
                    </div>
                    
                    <script>
                        function toggleTerminal() {
                            const panel = document.getElementById('terminal-panel');
                            panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
                        }
                        
                        function toggleEditor() {
                            const panel = document.getElementById('editor-panel');
                            panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
                        }
                        
                        function handleCommand(event) {
                            if (event.key === 'Enter') {
                                const input = document.getElementById('terminal-input');
                                const output = document.getElementById('terminal-output');
                                const command = input.value;
                                
                                const response = executeCommand(command);
                                output.innerHTML += '<div>&gt; ' + command + '</div>';
                                output.innerHTML += '<div>' + response + '</div>';
                                
                                input.value = '';
                                document.getElementById('terminal').scrollTop = document.getElementById('terminal').scrollHeight;
                            }
                        }
                        
                        function executeCommand(cmd) {
                            switch(cmd.toLowerCase()) {
                                case 'help':
                                    return 'Available commands: help, status, docker, clear, info';
                                case 'status':
                                    return 'Status: Local Android mode, Docker unavailable';
                                case 'docker':
                                    return 'Docker: Not available on Android platform';
                                case 'clear':
                                    document.getElementById('terminal-output').innerHTML = '';
                                    return '';
                                case 'info':
                                    return 'WebLabs-MobIDE v2.0 - Local fallback mode';
                                default:
                                    return 'Command not found: ' + cmd;
                            }
                        }
                        
                        function saveFile() {
                            const content = document.getElementById('editor').value;
                            const filename = document.getElementById('filename').value;
                            localStorage.setItem('weblabs_' + filename, content);
                            alert('File saved locally: ' + filename);
                        }
                        
                        function loadFile() {
                            const filename = document.getElementById('filename').value;
                            const content = localStorage.getItem('weblabs_' + filename);
                            if (content) {
                                document.getElementById('editor').value = content;
                                alert('File loaded: ' + filename);
                            } else {
                                alert('File not found: ' + filename);
                            }
                        }
                        
                        function showInfo() {
                            alert('WebLabs-MobIDE Local Interface\\n\\nDocker Ubuntu environment not available.\\nUsing local Android fallback mode.\\n\\nFeatures:\\n- Local file editing\\n- Basic terminal emulation\\n- Mobile-optimized interface');
                        }
                        
                        function showHelp() {
                            alert('WebLabs-MobIDE Help\\n\\n1. Terminal: Basic command simulation\\n2. Editor: Local file editing with localStorage\\n3. Retry Docker: Attempt to reconnect to Docker\\n\\nFor full Docker Ubuntu environment:\\n- Ensure Docker is available\\n- Restart the application');
                        }
                        
                        function goBack() {
                            window.history.back();
                        }
                    </script>
                </body>
                </html>
            """.trimIndent()
            
            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error loading local WebIDE", e)
            Toast.makeText(this, "Failed to load WebIDE", Toast.LENGTH_LONG).show()
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
        dockerManager.cleanup()
    }
}