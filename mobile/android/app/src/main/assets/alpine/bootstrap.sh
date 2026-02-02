#!/bin/sh

# WebLabs MobIDE Alpine Linux Startup Script with AI Integration
# Automatically executed when Alpine Linux environment starts
# Configures development environment and downloads AI model

set -e

# Configuration
WEBLABS_HOME="/home/developer"
AI_MODEL_DIR="/home/developer/ai"
LOG_FILE="/var/log/weblabs-startup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[WebLabs-Startup]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if we're in Alpine Linux
check_alpine() {
    if [ ! -f /etc/alpine-release ]; then
        error "This script requires Alpine Linux"
        exit 1
    fi
    log "Alpine Linux $(cat /etc/alpine-release) detected"
}

# Update system and install base packages
setup_base_system() {
    log "Setting up base system..."
    
    # Update package index
    apk update
    
    # Install essential development packages
    apk add --no-cache \
        bash \
        curl \
        wget \
        git \
        nano \
        vim \
        htop \
        tree \
        build-base \
        linux-headers \
        musl-dev \
        gcc \
        g++ \
        make \
        cmake \
        pkgconfig \
        autoconf \
        automake \
        libtool
    
    success "Base system setup completed"
}

# Setup Python environment
setup_python() {
    log "Setting up Python development environment..."
    
    # Install Python and related packages
    apk add --no-cache \
        python3 \
        python3-dev \
        py3-pip \
        py3-wheel \
        py3-setuptools \
        py3-numpy \
        py3-scipy
    
    # Create symbolic links for convenience
    ln -sf python3 /usr/bin/python
    ln -sf pip3 /usr/bin/pip
    
    success "Python environment setup completed"
}

# Setup Node.js environment
setup_nodejs() {
    log "Setting up Node.js development environment..."
    
    # Install Node.js and npm
    apk add --no-cache \
        nodejs \
        npm \
        yarn
    
    # Install global development tools
    npm install -g \
        typescript \
        webpack \
        webpack-cli \
        @babel/core \
        @babel/cli \
        eslint \
        prettier
    
    success "Node.js environment setup completed"
}

# Setup development user and workspace
setup_developer_workspace() {
    log "Setting up developer workspace..."
    
    # Create developer user if doesn't exist
    if ! id developer >/dev/null 2>&1; then
        adduser -D -s /bin/bash developer
    fi
    
    # Create workspace directories
    mkdir -p "$WEBLABS_HOME"/{projects,downloads,scripts,config}
    mkdir -p "$AI_MODEL_DIR"/{models,cache,logs}
    
    # Set proper ownership
    chown -R developer:developer "$WEBLABS_HOME"
    
    # Create .bashrc for developer user
    cat > "$WEBLABS_HOME/.bashrc" << 'EOF'
# WebLabs MobIDE Developer Environment

# Prompt customization
export PS1='\[\033[01;32m\]developer@alpine-arm64\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Environment variables
export EDITOR=nano
export PAGER=less
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Development aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias python=python3
alias pip=pip3

# WebLabs MobIDE specific
export WEBLABS_HOME="/home/developer"
export AI_MODEL_DIR="/home/developer/ai"
export PATH="$PATH:$WEBLABS_HOME/scripts:$AI_MODEL_DIR"

# Load AI commands if available
if [ -f "$AI_MODEL_DIR/shell_ai_commands.sh" ]; then
    source "$AI_MODEL_DIR/shell_ai_commands.sh"
fi

# Welcome message
echo "🚀 Welcome to WebLabs MobIDE Alpine Linux ARM64 Environment"
echo "📱 Mobile-First Development Platform with AI Assistance"
echo "🏔️  Alpine Linux $(cat /etc/alpine-release)"
echo "💻 Type 'help' for available commands"

# Show system info
echo "📊 System Info:"
echo "   Architecture: $(uname -m)"
echo "   Kernel: $(uname -r)"
echo "   Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "   Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
EOF

    success "Developer workspace setup completed"
}

# Download and setup AI model
setup_ai_model() {
    log "Setting up AI model environment..."
    
    # Check if AI installer exists
    if [ -f "/usr/local/bin/install_ai_model.sh" ]; then
        log "Running AI model installer..."
        chmod +x /usr/local/bin/install_ai_model.sh
        
        # Run AI installer in background
        nohup /usr/local/bin/install_ai_model.sh > "$AI_MODEL_DIR/logs/ai_install.log" 2>&1 &
        
        success "AI model installation initiated in background"
    else
        warn "AI model installer not found, skipping AI setup"
    fi
}

# Setup development tools and IDEs
setup_development_tools() {
    log "Setting up development tools..."
    
    # Install additional development tools
    apk add --no-cache \
        docker \
        docker-compose \
        rsync \
        tmux \
        screen \
        openssh-client \
        openssh-server \
        gnupg
    
    # Install code quality tools via pip
    pip install --no-cache-dir \
        black \
        flake8 \
        mypy \
        pytest \
        jupyter
    
    success "Development tools setup completed"
}

# Setup services
setup_services() {
    log "Setting up system services..."
    
    # Enable SSH service
    rc-update add sshd default
    
    # Start essential services
    service sshd start || true
    
    success "Services setup completed"
}

# Create helpful scripts
create_helper_scripts() {
    log "Creating helper scripts..."
    
    # Create project creation script
    cat > "$WEBLABS_HOME/scripts/new-project" << 'EOF'
#!/bin/sh
# Create new development project

if [ $# -eq 0 ]; then
    echo "Usage: new-project <project-name> [type]"
    echo "Types: python, nodejs, android, cpp, mixed"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_TYPE="${2:-mixed}"
PROJECT_DIR="$WEBLABS_HOME/projects/$PROJECT_NAME"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

case "$PROJECT_TYPE" in
    python)
        echo "# $PROJECT_NAME" > README.md
        echo "Python project created in $PROJECT_DIR"
        ;;
    nodejs)
        npm init -y
        echo "# $PROJECT_NAME" > README.md
        echo "Node.js project created in $PROJECT_DIR"
        ;;
    android)
        echo "# $PROJECT_NAME Android Project" > README.md
        mkdir -p {app/src/main/{java,res,assets},gradle}
        echo "Android project structure created in $PROJECT_DIR"
        ;;
    cpp)
        echo "# $PROJECT_NAME" > README.md
        cat > CMakeLists.txt << 'EOFCMAKE'
cmake_minimum_required(VERSION 3.10)
project($PROJECT_NAME)
set(CMAKE_CXX_STANDARD 17)
add_executable($PROJECT_NAME main.cpp)
EOFCMAKE
        echo '#include <iostream>\nint main() {\n    std::cout << "Hello from $PROJECT_NAME!" << std::endl;\n    return 0;\n}' > main.cpp
        echo "C++ project created in $PROJECT_DIR"
        ;;
    *)
        echo "# $PROJECT_NAME" > README.md
        echo "Mixed project created in $PROJECT_DIR"
        ;;
esac

echo "Project $PROJECT_NAME created successfully!"
EOF

    chmod +x "$WEBLABS_HOME/scripts/new-project"
    
    # Create system info script
    cat > "$WEBLABS_HOME/scripts/sysinfo" << 'EOF'
#!/bin/sh
# Display system information

echo "🏔️  WebLabs MobIDE Alpine Linux ARM64 Environment"
echo "================================================="
echo "📊 System Information:"
echo "   OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "   Kernel: $(uname -r)"
echo "   Architecture: $(uname -m)"
echo "   Uptime: $(uptime -p)"
echo ""
echo "💾 Memory Usage:"
free -h
echo ""
echo "💽 Disk Usage:"
df -h /
echo ""
echo "🔧 Development Tools:"
echo "   Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
echo "   Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
echo "   Git: $(git --version 2>/dev/null || echo 'Not installed')"
echo "   Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo ""
echo "🤖 AI Model Status:"
if [ -f "$AI_MODEL_DIR/ai_model_manager.py" ]; then
    python3 "$AI_MODEL_DIR/ai_model_manager.py" --info 2>/dev/null || echo "   AI model not ready"
else
    echo "   AI model not installed"
fi
EOF

    chmod +x "$WEBLABS_HOME/scripts/sysinfo"
    
    success "Helper scripts created"
}

# Main startup sequence
main() {
    log "🚀 Starting WebLabs MobIDE Alpine Linux Environment Setup"
    
    check_alpine
    setup_base_system
    setup_python
    setup_nodejs
    setup_developer_workspace
    setup_ai_model
    setup_development_tools
    setup_services
    create_helper_scripts
    
    success "🎉 WebLabs MobIDE Alpine Linux Environment Setup Complete!"
    log "Environment ready for mobile development with AI assistance"
    log "Switch to developer user: su - developer"
    log "Run system info: $WEBLABS_HOME/scripts/sysinfo"
}

# Run main function
main "$@" 2>&1 | tee -a "$LOG_FILE"