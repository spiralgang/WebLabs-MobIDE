#!/bin/bash

# WebLabs-MobIDE Docker Environment Startup Script
# Starts the web-based IDE and development services in Ubuntu container

set -euo pipefail

# Configuration
IDE_PORT="${IDE_PORT:-8080}"
WORKSPACE_DIR="/home/developer/workspace"
AI_DIR="/home/developer/ai"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Initialize workspace
init_workspace() {
    log "Initializing WebLabs-MobIDE workspace..."
    
    # Create essential directories
    mkdir -p "$WORKSPACE_DIR"/{projects,downloads,scripts,config}
    mkdir -p "$AI_DIR"/{models,cache,logs}
    
    # Create welcome project
    if [ ! -f "$WORKSPACE_DIR/README.md" ]; then
        cat > "$WORKSPACE_DIR/README.md" << 'EOF'
# WebLabs-MobIDE Development Environment

Welcome to your Ubuntu-based development environment!

## Available Tools
- **Android SDK & NDK**: Full Android development toolkit
- **Code-Server**: Web-based VS Code editor
- **Python 3**: With AI/ML libraries (transformers, torch, etc.)
- **Node.js & NPM**: JavaScript development
- **Build Tools**: gcc, cmake, ninja, pkg-config

## Getting Started
1. Open the web IDE at http://localhost:8080
2. Create a new project: `./scripts/new-project my-app android`
3. Start coding!

## AI Features
- AI model management in ~/ai/
- Code generation and completion
- Integrated development assistance

Enjoy coding! 🚀
EOF
    fi
    
    log "Workspace initialized"
}

# Start AI services
start_ai_services() {
    log "Starting AI services..."
    
    # Check if AI models directory exists
    if [ -d "$AI_DIR/models" ]; then
        log "AI models directory found"
    else
        log "AI models directory not found, creating..."
        mkdir -p "$AI_DIR/models"
    fi
    
    # Start AI service in background if available
    if command -v python3 >/dev/null 2>&1; then
        log "Python3 available for AI services"
    fi
}

# Start code-server
start_ide() {
    log "Starting WebLabs-MobIDE Code-Server..."
    
    # Start code-server with custom configuration
    exec code-server \
        --bind-addr "0.0.0.0:$IDE_PORT" \
        --auth none \
        --disable-telemetry \
        --disable-update-check \
        --log info \
        "$WORKSPACE_DIR"
}

# Main startup sequence
main() {
    log "🚀 Starting WebLabs-MobIDE Ubuntu Development Environment"
    log "Port: $IDE_PORT"
    log "Workspace: $WORKSPACE_DIR"
    
    init_workspace
    start_ai_services
    start_ide
}

# Handle signals gracefully
trap 'log "Shutting down WebLabs-MobIDE..."; exit 0' SIGTERM SIGINT

# Execute main function
main "$@"