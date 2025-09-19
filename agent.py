#!/usr/bin/env python3
"""
QuantumAIIDE Agent: Mobile-First, Privileged AI System Builder
Industry standards, agentic orchestration, Android/Aarch64 ready.
References: /reference vault, ai_dev_system.py, OWASP, GitHub API docs, DeepSeek, HuggingFace
"""
import asyncio, json, os, aiohttp, logging
from github import Github
from shell import run_shell_command
from ai import query_ai
from audit import log_action

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger("QuantumAIIDE-Agent")

class QuantumAgent:
    def __init__(self, github_token=None, ai_token=None):
        # Enhanced authentication with fallback
        self.github_token = github_token or os.getenv('GITHUB_TOKEN')
        self.ai_token = ai_token or os.getenv('HUGGINGFACE_TOKEN') 
        self.agent_api_key = os.getenv('AGENT_API_KEY')
        self.session_secret = os.getenv('SESSION_SECRET')
        
        if not self.github_token:
            logger.error("GITHUB_TOKEN not found - GitHub operations will fail")
        if not self.ai_token:
            logger.error("HUGGINGFACE_TOKEN not found - AI operations will fail")
        if not self.agent_api_key:
            logger.warning("AGENT_API_KEY not found - using default authentication")
            
        # Initialize GitHub client if token available
        self.github = Github(self.github_token) if self.github_token else None
        
        # Load authentication configuration
        self.auth_config = self.load_auth_config()
        
    def load_auth_config(self):
        """Load authentication and integration configuration"""
        config_path = os.path.join(os.path.dirname(__file__), 
                                   'app/src/main/assets/models/auth-integration-config.json')
        try:
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError, OSError) as e:
            logger.warning(f"Could not load auth config ({type(e).__name__}): {e}")

        # Return default configuration
        return {
            "authentication": {"enabled": True},
            "integration_endpoints": {},
            "frontend_backend_mapping": {},
            "error_handling": {}
        }
    
    def validate_authentication(self):
        """Validate all required authentication tokens"""
        validation_results = {
            "github": bool(self.github_token),
            "huggingface": bool(self.ai_token),
            "agent": bool(self.agent_api_key),
            "session": bool(self.session_secret)
        }
        
        missing_tokens = [k for k, v in validation_results.items() if not v]
        if missing_tokens:
            logger.error(f"Missing authentication tokens: {missing_tokens}")
            return False, missing_tokens
        
        logger.info("All authentication tokens validated successfully")
        return True, []
    
    async def authenticate_request(self, endpoint_type):
        """Get appropriate authentication for different endpoint types"""
        endpoints = self.auth_config.get("integration_endpoints", {})
        endpoint_config = endpoints.get(endpoint_type, {})
        
        token_source = endpoint_config.get("token_source")
        auth_method = endpoint_config.get("auth_method", "bearer_token")
        
        if token_source == "github":
            token = self.github_token
        elif token_source == "huggingface":
            token = self.ai_token
        elif token_source == "agent":
            token = self.agent_api_key
        else:
            logger.error(f"Unknown token source: {token_source}")
            return None
            
        if not token:
            logger.error(f"Token not available for {endpoint_type}")
            return None
            
        if auth_method == "bearer_token":
            return {"Authorization": f"Bearer {token}"}
        elif auth_method == "api_key":
            return {"X-API-Key": token}
        else:
            return {"Authorization": token}

    async def handle_request(self, req):
        """Dispatch agentic requests: build, refactor, run, push, etc."""
        action = req.get("action")
        params = req.get("params", {})
        
        # Validate authentication first
        auth_valid, missing = self.validate_authentication()
        if not auth_valid:
            return {
                "status": "error", 
                "msg": f"Authentication failed - missing tokens: {missing}",
                "error_code": "AUTH_MISSING"
            }
        
        log_action(action, params)
        
        try:
            if action == "refactor_file":
                if not self.github:
                    return {"status": "error", "msg": "GitHub client not initialized", "error_code": "GITHUB_AUTH_FAILED"}
                    
                repo = self.github.get_repo(params["repo"])
                file = repo.get_contents(params["path"])
                code = file.decoded_content.decode()
                instructions = params["instructions"]
                prompt = f"Refactor this code for {params['path']}:\n{code}\nInstructions: {instructions}\nOutput only final code."
                
                # Authenticate AI request
                auth_headers = await self.authenticate_request("ai_backend")
                if not auth_headers:
                    return {"status": "error", "msg": "AI authentication failed", "error_code": "AI_AUTH_FAILED"}
                
                new_code = await query_ai(prompt, self.ai_token, headers=auth_headers)
                repo.update_file(params["path"], "Agentic AI refactor", new_code, file.sha)
                return {"status": "ok", "msg": "File refactored"}
                
            elif action == "generate_file":
                if not self.github:
                    return {"status": "error", "msg": "GitHub client not initialized", "error_code": "GITHUB_AUTH_FAILED"}
                    
                repo = self.github.get_repo(params["repo"])
                prompt = f"Generate code for {params['path']}:\n{params['description']}\nOutput only final code."
                
                # Authenticate AI request
                auth_headers = await self.authenticate_request("ai_backend")
                if not auth_headers:
                    return {"status": "error", "msg": "AI authentication failed", "error_code": "AI_AUTH_FAILED"}
                    
                code = await query_ai(prompt, self.ai_token, headers=auth_headers)
                repo.create_file(params["path"], "Agentic AI generate", code)
                return {"status": "ok", "msg": "File generated"}
                
            elif action == "run_shell":
                result = run_shell_command(params["command"])
                return {"status": "ok", "output": result}
                
            elif action == "check_integration":
                # New action to verify frontend-backend integration
                mapping = self.auth_config.get("frontend_backend_mapping", {})
                results = {}
                
                for component, config in mapping.items():
                    frontend_path = config.get("frontend")
                    backend_path = config.get("backend")
                    auth_bridge = config.get("auth_bridge")
                    
                    frontend_exists = os.path.exists(frontend_path) if frontend_path else False
                    backend_exists = os.path.exists(backend_path) if backend_path else False
                    
                    results[component] = {
                        "frontend_exists": frontend_exists,
                        "backend_exists": backend_exists,
                        "auth_bridge": auth_bridge,
                        "integration_status": config.get("integration_status", "unknown"),
                        "assimilated": frontend_exists and backend_exists
                    }
                
                return {"status": "ok", "integration_check": results}
                
            # Extend for more agentic ops: build, deploy, proxy, etc.
            else:
                return {"status": "error", "msg": "Unknown action", "error_code": "UNKNOWN_ACTION"}
                
        except Exception as e:
            logger.error(f"Error handling request {action}: {str(e)}")
            return {
                "status": "error", 
                "msg": f"Request handling failed: {str(e)}",
                "error_code": "REQUEST_FAILED"
            }

# FastAPI or Flask app to expose agent endpoints (omitted for brevity)
# See /reference vault, ai_dev_system.py for full server reference