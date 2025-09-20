#!/bin/bash

# WebLabs-MobIDE Docker Container Manager
# Manages Docker-based Ubuntu development environment

set -euo pipefail

# Configuration
CONTAINER_NAME="weblabs-mobide"
IMAGE_NAME="weblabs-mobide:latest"
IDE_PORT="8080"
WORKSPACE_VOLUME="weblabs-workspace"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Build Docker image
build_image() {
    log "Building WebLabs-MobIDE Docker image..."
    
    if [ ! -f "Dockerfile" ]; then
        log "ERROR: Dockerfile not found in current directory"
        exit 1
    fi
    
    docker build -t "$IMAGE_NAME" .
    log "Docker image built successfully"
}

# Start container
start_container() {
    log "Starting WebLabs-MobIDE container..."
    
    # Check if container is already running
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log "Container $CONTAINER_NAME is already running"
        return 0
    fi
    
    # Remove existing stopped container
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        log "Removing existing container..."
        docker rm "$CONTAINER_NAME"
    fi
    
    # Create and start new container
    docker run -d \
        --name "$CONTAINER_NAME" \
        --platform linux/arm64 \
        -p "$IDE_PORT:8080" \
        -v "$WORKSPACE_VOLUME:/home/developer/workspace" \
        -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        --env DISPLAY="$DISPLAY" \
        --restart unless-stopped \
        "$IMAGE_NAME"
    
    log "Container started successfully"
    log "Access the IDE at: http://localhost:$IDE_PORT"
}

# Show help
show_help() {
    cat << EOF
WebLabs-MobIDE Docker Manager

Usage: $0 [COMMAND]

Commands:
    build       Build the Docker image
    start       Start the development container
    stop        Stop the development container
    restart     Restart the development container
    status      Show container status
    logs        Show container logs
    shell       Open interactive shell in container
    exec CMD    Execute command in container
    help        Show this help message

Examples:
    $0 build                    # Build the Docker image
    $0 start                    # Start the development environment
    $0 shell                    # Open shell in running container
    $0 exec python3 --version  # Check Python version in container

The development environment will be available at:
http://localhost:$IDE_PORT
EOF
}

# Main command handler
main() {
    case "${1:-help}" in
        build)
            build_image
            ;;
        start)
            start_container
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"