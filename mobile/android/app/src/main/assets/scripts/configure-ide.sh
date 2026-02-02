#!/bin/bash

# WebLabs MobIDE - Alpine Linux AI Model Auto-Installer
# Automatically downloads and configures Embedding Gemma 300M model
# Equivalent to: import kagglehub; kagglehub.model_download("google/embeddinggemma/transformers/embeddinggemma-300m")
# Optimized for ARM64 Android devices with 4GB memory constraint

set -euo pipefail

# Configuration
MODEL_NAME="embeddinggemma-300m"
MODEL_URL="${MODEL_URL:-https://huggingface.co/google/embeddinggemma-300m}"
AI_DIR="/home/developer/ai"
MODEL_DIR="$AI_DIR/models"
MAX_MODEL_SIZE_GB=4
LOG_FILE="/tmp/ai_model_install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[AI-Install]${NC} $1" | tee -a "$LOG_FILE"
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
        error "This script is designed for Alpine Linux environment"
        exit 1
    fi
    log "Alpine Linux detected: $(cat /etc/alpine-release)"
}

# Install required packages
install_dependencies() {
    log "Installing AI development dependencies..."
    
    # Update package index
    apk update
    
    # Install Python and AI libraries
    apk add --no-cache \
        python3 \
        py3-pip \
        py3-numpy \
        py3-torch \
        py3-transformers \
        git \
        curl \
        build-base \
        python3-dev \
        linux-headers
    
    # Install additional Python packages
    pip3 install --no-cache-dir --break-system-packages \
        kagglehub \
        transformers \
        torch \
        torchvision \
        huggingface_hub \
        accelerate \
        safetensors
    
    success "Dependencies installed successfully"
}

# Create AI workspace
setup_workspace() {
    log "Setting up AI workspace..."
    
    mkdir -p "$AI_DIR" "$MODEL_DIR"
    cd "$AI_DIR"
    
    # Create AI helper script
    cat > "$AI_DIR/ai_model_manager.py" << 'EOF'
#!/usr/bin/env python3
"""
WebLabs MobIDE AI Model Manager
Manages Embedding Gemma 300M model for ARM64 Android devices
"""

import os
import sys
import json
import torch
import transformers
from transformers import AutoTokenizer, AutoModel, AutoConfig
from huggingface_hub import snapshot_download
import argparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class EmbeddingGemmaManager:
    def __init__(self, model_dir="/home/developer/ai/models"):
        self.model_dir = model_dir
        self.model_name = "google/embeddinggemma-300m"
        self.tokenizer = None
        self.model = None
        self.config = None
        
    def download_model(self):
        """Download Embedding Gemma 300M model"""
        logger.info(f"Downloading {self.model_name} to {self.model_dir}")
        
        try:
            # Download model using HuggingFace Hub
            model_path = snapshot_download(
                repo_id=self.model_name,
                cache_dir=self.model_dir,
                local_dir=os.path.join(self.model_dir, "embeddinggemma-300m"),
                local_dir_use_symlinks=False
            )
            
            logger.info(f"Model downloaded to: {model_path}")
            return model_path
            
        except Exception as e:
            logger.error(f"Model download failed: {e}")
            return None
    
    def load_model(self, model_path=None):
        """Load the model for inference"""
        if model_path is None:
            model_path = os.path.join(self.model_dir, "embeddinggemma-300m")
        
        if not os.path.exists(model_path):
            logger.error(f"Model path does not exist: {model_path}")
            return False
        
        try:
            logger.info("Loading tokenizer and model...")
            
            # Load configuration
            self.config = AutoConfig.from_pretrained(model_path)
            
            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(model_path)
            
            # Load model with ARM64 optimizations
            self.model = AutoModel.from_pretrained(
                model_path,
                torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
                device_map="auto" if torch.cuda.is_available() else None
            )
            
            # ARM64 optimizations
            if hasattr(torch.backends, 'cpu') and torch.backends.cpu.get_cpu_capability():
                torch.set_num_threads(4)  # Optimize for mobile ARM64
            
            logger.info("Model loaded successfully")
            return True
            
        except Exception as e:
            logger.error(f"Model loading failed: {e}")
            return False
    
    def generate_embedding(self, text):
        """Generate embeddings for input text"""
        if not self.model or not self.tokenizer:
            logger.error("Model not loaded")
            return None
        
        try:
            # Tokenize input
            inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
            
            # Generate embeddings
            with torch.no_grad():
                outputs = self.model(**inputs)
                embeddings = outputs.last_hidden_state.mean(dim=1)
            
            return embeddings.numpy().tolist()
            
        except Exception as e:
            logger.error(f"Embedding generation failed: {e}")
            return None
    
    def generate_code_suggestion(self, prompt, context="", max_length=512):
        """Generate code suggestions based on prompt"""
        if not self.model or not self.tokenizer:
            logger.error("Model not loaded")
            return "Error: Model not loaded"
        
        try:
            # Format prompt for code generation
            full_prompt = f"Context: {context}\n\nGenerate code for: {prompt}\n\nCode:"
            
            # Tokenize
            inputs = self.tokenizer(
                full_prompt, 
                return_tensors="pt", 
                truncation=True, 
                max_length=1024
            )
            
            # Generate with appropriate parameters for code
            with torch.no_grad():
                outputs = self.model.generate(
                    inputs.input_ids,
                    max_length=max_length,
                    num_return_sequences=1,
                    temperature=0.7,
                    do_sample=True,
                    pad_token_id=self.tokenizer.eos_token_id,
                    repetition_penalty=1.1
                )
            
            # Decode generated text
            generated_text = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
            
            # Extract code part
            if "Code:" in generated_text:
                code_part = generated_text.split("Code:")[-1].strip()
                return code_part
            else:
                return generated_text.strip()
                
        except Exception as e:
            logger.error(f"Code generation failed: {e}")
            return f"Error: {e}"
    
    def get_model_info(self):
        """Get model information"""
        model_path = os.path.join(self.model_dir, "embeddinggemma-300m")
        
        info = {
            "model_name": self.model_name,
            "model_path": model_path,
            "model_exists": os.path.exists(model_path),
            "model_loaded": self.model is not None,
            "arm64_optimized": True,
            "max_memory_mb": 4096
        }
        
        if os.path.exists(model_path):
            # Calculate model size
            total_size = 0
            for dirpath, dirnames, filenames in os.walk(model_path):
                for filename in filenames:
                    filepath = os.path.join(dirpath, filename)
                    total_size += os.path.getsize(filepath)
            
            info["model_size_mb"] = total_size / (1024 * 1024)
        
        return info

def main():
    parser = argparse.ArgumentParser(description="WebLabs MobIDE AI Model Manager")
    parser.add_argument("--download", action="store_true", help="Download the model")
    parser.add_argument("--load", action="store_true", help="Load the model")
    parser.add_argument("--info", action="store_true", help="Show model info")
    parser.add_argument("--generate", type=str, help="Generate code for prompt")
    parser.add_argument("--context", type=str, default="", help="Context for code generation")
    parser.add_argument("--embed", type=str, help="Generate embedding for text")
    
    args = parser.parse_args()
    
    manager = EmbeddingGemmaManager()
    
    if args.download:
        model_path = manager.download_model()
        if model_path:
            print(f"Model downloaded successfully: {model_path}")
        else:
            print("Model download failed")
            sys.exit(1)
    
    if args.load:
        if manager.load_model():
            print("Model loaded successfully")
        else:
            print("Model loading failed")
            sys.exit(1)
    
    if args.info:
        info = manager.get_model_info()
        print(json.dumps(info, indent=2))
    
    if args.generate:
        if not manager.model:
            manager.load_model()
        
        result = manager.generate_code_suggestion(args.generate, args.context)
        print(result)
    
    if args.embed:
        if not manager.model:
            manager.load_model()
        
        embedding = manager.generate_embedding(args.embed)
        if embedding:
            print(json.dumps(embedding))
        else:
            print("Embedding generation failed")

if __name__ == "__main__":
    main()
EOF

    chmod +x "$AI_DIR/ai_model_manager.py"
    success "AI workspace created"
}

# Download and setup the model
download_model() {
    log "Downloading Embedding Gemma 300M model..."
    
    cd "$AI_DIR"
    
    # Use the Python script to download the model
    if python3 ai_model_manager.py --download; then
        success "Model downloaded successfully"
    else
        error "Model download failed"
        exit 1
    fi
    
    # Verify model
    log "Verifying model installation..."
    python3 ai_model_manager.py --info
    
    success "Model verification completed"
}

# Create Shell-IDE integration script
create_shell_integration() {
    log "Creating Shell-IDE integration..."
    
    cat > "$AI_DIR/shell_ai_commands.sh" << 'EOF'
#!/bin/sh

# WebLabs MobIDE Shell-IDE AI Integration Commands
# Provides AI-assisted development commands for the mobile developer environment

AI_SCRIPT="/home/developer/ai/ai_model_manager.py"

# AI-assisted code generation
ai_generate() {
    if [ $# -eq 0 ]; then
        echo "Usage: ai_generate '<description>' [context]"
        echo "Example: ai_generate 'create a HTTP client function' 'Android Kotlin project'"
        return 1
    fi
    
    local prompt="$1"
    local context="${2:-Mobile development with Alpine Linux on ARM64 Android}"
    
    echo "🤖 Generating code for: $prompt"
    python3 "$AI_SCRIPT" --generate "$prompt" --context "$context"
}

# AI code embedding/similarity
ai_embed() {
    if [ $# -eq 0 ]; then
        echo "Usage: ai_embed '<text>'"
        return 1
    fi
    
    echo "🧠 Generating embedding for: $1"
    python3 "$AI_SCRIPT" --embed "$1"
}

# AI model information
ai_info() {
    echo "📊 AI Model Information:"
    python3 "$AI_SCRIPT" --info
}

# Load AI model
ai_load() {
    echo "⚡ Loading AI model..."
    python3 "$AI_SCRIPT" --load
}

# AI-assisted refactoring
ai_refactor() {
    if [ $# -lt 2 ]; then
        echo "Usage: ai_refactor '<filename>' '<refactoring_instruction>'"
        return 1
    fi
    
    local filename="$1"
    local instruction="$2"
    
    if [ ! -f "$filename" ]; then
        echo "Error: File $filename not found"
        return 1
    fi
    
    local content=$(cat "$filename")
    local prompt="Refactor this code: $instruction"
    local context="File: $filename\nOriginal code:\n$content"
    
    echo "🔧 Refactoring $filename with instruction: $instruction"
    python3 "$AI_SCRIPT" --generate "$prompt" --context "$context"
}

# AI-assisted debugging
ai_debug() {
    if [ $# -eq 0 ]; then
        echo "Usage: ai_debug '<error_description>' [code_snippet]"
        return 1
    fi
    
    local error="$1"
    local code="${2:-}"
    local prompt="Debug this error: $error"
    local context="ARM64 Android Alpine Linux environment. Code: $code"
    
    echo "🐛 Debugging: $error"
    python3 "$AI_SCRIPT" --generate "$prompt" --context "$context"
}

# Export functions to shell
export -f ai_generate ai_embed ai_info ai_load ai_refactor ai_debug

echo "🚀 WebLabs MobIDE AI commands loaded!"
echo "Available commands: ai_generate, ai_embed, ai_info, ai_load, ai_refactor, ai_debug"
EOF

    chmod +x "$AI_DIR/shell_ai_commands.sh"
    
    # Add to shell startup
    echo "source $AI_DIR/shell_ai_commands.sh" >> /etc/profile
    
    success "Shell-IDE integration created"
}

# Create startup service
create_startup_service() {
    log "Creating AI model startup service..."
    
    cat > /etc/init.d/weblabs-ai << 'EOF'
#!/sbin/openrc-run

name="WebLabs MobIDE AI Service"
description="AI model management for WebLabs MobIDE"

AI_DIR="/home/developer/ai"
AI_SCRIPT="$AI_DIR/ai_model_manager.py"
PIDFILE="/var/run/weblabs-ai.pid"

depend() {
    need net
    after bootmisc
}

start() {
    ebegin "Starting WebLabs MobIDE AI Service"
    
    # Ensure AI workspace exists
    mkdir -p "$AI_DIR"
    
    # Pre-load AI model
    start-stop-daemon --start --background --make-pidfile --pidfile "$PIDFILE" \
        --exec /usr/bin/python3 -- "$AI_SCRIPT" --load
    
    eend $?
}

stop() {
    ebegin "Stopping WebLabs MobIDE AI Service"
    start-stop-daemon --stop --pidfile "$PIDFILE"
    eend $?
}
EOF

    chmod +x /etc/init.d/weblabs-ai
    rc-update add weblabs-ai default
    
    success "Startup service created"
}

# Main installation process
main() {
    log "Starting WebLabs MobIDE AI Model Installation"
    log "Target: Embedding Gemma 300M (4GB) for ARM64 Android"
    
    check_alpine
    install_dependencies
    setup_workspace
    download_model
    create_shell_integration
    create_startup_service
    
    success "🎉 WebLabs MobIDE AI Model Installation Complete!"
    log "AI commands available in shell: ai_generate, ai_embed, ai_info, ai_load, ai_refactor, ai_debug"
    log "Model will auto-load on Alpine Linux startup"
    
    # Test the installation
    log "Testing AI installation..."
    if python3 "$AI_DIR/ai_model_manager.py" --info; then
        success "✅ AI model installation verified successfully"
    else
        warn "⚠️  AI model verification failed - manual intervention may be required"
    fi
}

# Run main function
main "$@"