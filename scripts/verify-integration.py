#!/usr/bin/env python3
"""
Frontend-Backend Integration Verification Script
Ensures all frontend components are properly assimilated with backend partners
"""

import os
import json
import sys
from pathlib import Path

def check_integration_mapping():
    """Verify all frontend files have corresponding backend integrations"""
    
    # Load integration configuration
    config_path = Path(__file__).resolve().parent / "app/src/main/assets/models/auth-integration-config.json"
    if not config_path.exists():
        print(f"❌ Integration config not found: {config_path}")
        return False
    
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    mapping = config.get("frontend_backend_mapping", {})
    if not mapping:
        print("❌ No frontend-backend mapping found in config")
        return False
    
    print("🔍 Checking Frontend-Backend Integration...")
    print("=" * 60)
    
    all_assimilated = True
    results = {}
    
    for component, integration in mapping.items():
        frontend_path = integration.get("frontend", "")
        backend_path = integration.get("backend", "")
        auth_bridge = integration.get("auth_bridge", "")
        status = integration.get("integration_status", "unknown")
        
        # Check if paths exist
        frontend_exists = os.path.exists(frontend_path) if frontend_path else False
        backend_exists = os.path.exists(backend_path) if backend_path else False
        
        # Determine integration status
        if frontend_exists and backend_exists:
            actual_status = "✅ ASSIMILATED"
            is_assimilated = True
        elif frontend_exists and not backend_exists:
            actual_status = "❌ BACKEND MISSING"
            is_assimilated = False
            all_assimilated = False
        elif not frontend_exists and backend_exists:
            actual_status = "❌ FRONTEND MISSING"
            is_assimilated = False
            all_assimilated = False
        else:
            actual_status = "❌ BOTH MISSING"
            is_assimilated = False
            all_assimilated = False
        
        results[component] = {
            "status": actual_status,
            "frontend_exists": frontend_exists,
            "backend_exists": backend_exists,
            "auth_bridge": auth_bridge,
            "assimilated": is_assimilated
        }
        
        print(f"📦 {component.upper()}")
        print(f"   Frontend: {frontend_path} {'✅' if frontend_exists else '❌'}")
        print(f"   Backend:  {backend_path} {'✅' if backend_exists else '❌'}")
        print(f"   Bridge:   {auth_bridge}")
        print(f"   Status:   {actual_status}")
        print()
    
    print("=" * 60)
    
    if all_assimilated:
        print("🎉 ALL FRONTEND-BACKEND INTEGRATIONS ASSIMILATED!")
        print("✅ Repository structure is fully compliant")
        return True
    else:
        failed_components = [k for k, v in results.items() if not v["assimilated"]]
        print(f"❌ INTEGRATION FAILURES DETECTED: {len(failed_components)} components")
        print(f"   Failed components: {', '.join(failed_components)}")
        print()
        print("🔧 REQUIRED ACTIONS:")
        for component, result in results.items():
            if not result["assimilated"]:
                if not result["frontend_exists"]:
                    print(f"   • Create missing frontend: {mapping[component]['frontend']}")
                if not result["backend_exists"]:
                    print(f"   • Create missing backend: {mapping[component]['backend']}")
        return False

def check_authentication_tokens():
    """Verify authentication tokens are properly configured"""
    print("\n🔐 Checking Authentication Configuration...")
    print("=" * 60)
    
    required_tokens = [
        ("GITHUB_TOKEN", "GitHub API access"),
        ("HUGGINGFACE_TOKEN", "HuggingFace AI models"),
        ("AGENT_API_KEY", "Agent authentication"),
        ("SESSION_SECRET", "Session management")
    ]
    
    missing_tokens = []
    
    for token_name, description in required_tokens:
        if os.getenv(token_name):
            print(f"✅ {token_name}: Configured")
        else:
            print(f"❌ {token_name}: Missing - {description}")
            missing_tokens.append(token_name)
    
    print("=" * 60)
    
    if missing_tokens:
        print(f"❌ MISSING AUTHENTICATION TOKENS: {len(missing_tokens)}")
        print("🔧 Configure these environment variables:")
        for token in missing_tokens:
            print(f"   • {token}")
        return False
    else:
        print("🎉 ALL AUTHENTICATION TOKENS CONFIGURED!")
        return True

def main():
    """Main verification function"""
    print("🚀 WebLabs-MobIDE Integration Verification")
    print("🔍 Checking Frontend-Backend Assimilation Status")
    print()
    
    # Check integration mapping
    integration_ok = check_integration_mapping()
    
    # Check authentication
    auth_ok = check_authentication_tokens()
    
    print("\n" + "=" * 60)
    print("📊 FINAL VERIFICATION RESULTS")
    print("=" * 60)
    
    if integration_ok and auth_ok:
        print("🎉 ✅ FULL INTEGRATION SUCCESS!")
        print("   • All frontends assimilated with backend partners")
        print("   • All authentication tokens configured")
        print("   • Repository ready for production deployment")
        sys.exit(0)
    else:
        print("❌ INTEGRATION VERIFICATION FAILED!")
        if not integration_ok:
            print("   • Frontend-backend integration issues detected")
        if not auth_ok:
            print("   • Authentication configuration incomplete")
        print("   • Review errors above and fix before deployment")
        sys.exit(1)

if __name__ == "__main__":
    main()