#!/bin/sh

# WebLabs MobIDE - PRoot Launch Script for Alpine Linux
# Provides secure containerized Alpine Linux environment on ARM64 Android

set -e

# Configuration
ALPINE_ROOT="/data/data/com.spiralgang.weblabs/files/alpine/rootfs"
WEBLABS_HOME="/home/developer/weblabs"
PROOT_BINARY="/data/data/com.spiralgang.weblabs/files/proot"

# ARM64 environment variables
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin"
export HOME="$WEBLABS_HOME"
export USER="developer"
export SHELL="/bin/sh"
export TERM="xterm-256color"
export LANG="en_US.UTF-8"

# ARM64 optimization
export CFLAGS="-march=armv8-a -mtune=cortex-a53"
export CXXFLAGS="$CFLAGS"

log() {
    echo "[PRoot-Launch] $*"
}

check_requirements() {
    if [ ! -d "$ALPINE_ROOT" ]; then
        log "ERROR: Alpine rootfs not found at $ALPINE_ROOT"
        exit 1
    fi
    
    if [ ! -f "$PROOT_BINARY" ]; then
        log "ERROR: PRoot binary not found at $PROOT_BINARY"
        exit 1
    fi
    
    log "Requirements check passed"
}

setup_environment() {
    # Create necessary directories if they don't exist
    mkdir -p "$ALPINE_ROOT/proc"
    mkdir -p "$ALPINE_ROOT/sys"
    mkdir -p "$ALPINE_ROOT/dev"
    mkdir -p "$ALPINE_ROOT/tmp"
    mkdir -p "$ALPINE_ROOT$WEBLABS_HOME"
    
    # Set up developer environment
    if [ ! -f "$ALPINE_ROOT$WEBLABS_HOME/.bashrc" ]; then
        cat > "$ALPINE_ROOT$WEBLABS_HOME/.bashrc" << 'EOF'
# WebLabs MobIDE Developer Environment
export PS1='\[\033[01;32m\]developer@weblabs-arm64\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export EDITOR=nano
export PYTHONDONTWRITEBYTECODE=1

# ARM64 development aliases
alias ll='ls -alF'
alias la='ls -A'
alias python=python3
alias pip=pip3

# WebLabs MobIDE shortcuts
alias ide='cd $HOME/weblabs && python3 -m http.server 8080'
alias projects='cd $HOME/weblabs/projects'
alias ai='python3 $HOME/weblabs/ai/ai_model_manager.py'

echo "🏔️  Welcome to WebLabs MobIDE Alpine Linux ARM64 Environment"
echo "📱 ARM64 Android development environment ready"
echo "🚀 Type 'projects' to navigate to projects directory"
echo "🤖 Type 'ai --help' for AI assistance commands"
EOF
    fi
    
    log "Environment setup completed"
}

launch_alpine() {
    log "Launching Alpine Linux environment with PRoot..."
    
    # PRoot command with ARM64 optimizations
    exec "$PROOT_BINARY" \
        --rootfs="$ALPINE_ROOT" \
        --bind=/proc \
        --bind=/sys \
        --bind=/dev \
        --bind=/data/data/com.spiralgang.weblabs/files/alpine:/opt/weblabs \
        --working-directory="$WEBLABS_HOME" \
        --change-id=1000:1000 \
        /bin/sh -l
}

main() {
    log "Starting WebLabs MobIDE Alpine Linux container..."
    
    check_requirements
    setup_environment
    launch_alpine
}

# Execute main function with all arguments
main "$@"