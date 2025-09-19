#!/bin/bash

# WebLabs MobIDE - SymTools Agent for ARM64 Alpine Linux Development Environment
# Manages symbolic links, development tools, and ARM64 optimization utilities

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ALPINE_ROOT="${SCRIPT_DIR}/alpine"
readonly TOOLS_DIR="${ALPINE_ROOT}/usr/local/bin"
readonly LIB_DIR="${ALPINE_ROOT}/usr/local/lib"
readonly CONFIG_DIR="${ALPINE_ROOT}/etc/weblabs"

# ARM64 architecture detection and optimization
readonly ARCH="$(uname -m)"
readonly IS_ARM64="$(if [[ "${ARCH}" == "aarch64" || "${ARCH}" == "arm64" ]]; then echo "true"; else echo "false"; fi)"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SymToolsAgent] $*" >&2
}

create_directory_structure() {
    log "Creating ARM64 Alpine Linux directory structure..."
    
    local dirs=(
        "${ALPINE_ROOT}/usr/local/bin"
        "${ALPINE_ROOT}/usr/local/lib/arm64"
        "${ALPINE_ROOT}/usr/local/include"
        "${ALPINE_ROOT}/etc/weblabs"
        "${ALPINE_ROOT}/var/lib/weblabs"
        "${ALPINE_ROOT}/opt/weblabs/tools"
        "${ALPINE_ROOT}/home/developer/workspace"
        "${ALPINE_ROOT}/tmp/build"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "${dir}"
        log "Created directory: ${dir}"
    done
}

install_arm64_toolchain() {
    log "Installing ARM64 development toolchain..."
    
    if [[ "${IS_ARM64}" == "true" ]]; then
        log "Detected ARM64 architecture, using native toolchain"
        
        # Create symbolic links for native ARM64 tools
        local tools=(
            "gcc:gcc"
            "g++:g++"
            "clang:clang"
            "clang++:clang++"
            "make:make"
            "cmake:cmake"
            "ninja:ninja"
            "pkg-config:pkg-config"
            "strip:strip"
            "objdump:objdump"
            "readelf:readelf"
        )
        
        for tool_mapping in "${tools[@]}"; do
            local tool_name="${tool_mapping%%:*}"
            local target_name="${tool_mapping##*:}"
            
            if command -v "${tool_name}" &> /dev/null; then
                ln -sf "$(command -v "${tool_name}")" "${TOOLS_DIR}/${target_name}"
                log "Linked ARM64 tool: ${tool_name} -> ${TOOLS_DIR}/${target_name}"
            else
                log "WARNING: ARM64 tool not found: ${tool_name}"
            fi
        done
    else
        log "Non-ARM64 architecture detected, setting up cross-compilation"
        
        # Setup cross-compilation toolchain for ARM64
        local cross_tools=(
            "aarch64-linux-gnu-gcc:gcc"
            "aarch64-linux-gnu-g++:g++"
            "aarch64-linux-gnu-strip:strip"
            "aarch64-linux-gnu-objdump:objdump"
            "aarch64-linux-gnu-readelf:readelf"
        )
        
        for tool_mapping in "${cross_tools[@]}"; do
            local tool_name="${tool_mapping%%:*}"
            local target_name="${tool_mapping##*:}"
            
            if command -v "${tool_name}" &> /dev/null; then
                ln -sf "$(command -v "${tool_name}")" "${TOOLS_DIR}/${target_name}"
                log "Linked cross-compilation tool: ${tool_name} -> ${TOOLS_DIR}/${target_name}"
            fi
        done
    fi
}

setup_arm64_optimization_flags() {
    log "Setting up ARM64 optimization flags..."
    
    local config_file="${CONFIG_DIR}/arm64-optimization.conf"
    
    cat > "${config_file}" << 'EOF'
# WebLabs MobIDE ARM64 Optimization Configuration

# Compiler flags for ARM64 optimization
export CFLAGS="-march=armv8-a -mtune=cortex-a75 -O3 -ffast-math -funroll-loops"
export CXXFLAGS="${CFLAGS} -std=c++17"
export LDFLAGS="-Wl,-O1 -Wl,--as-needed -Wl,--sort-common"

# ARM64 specific optimizations
export ARM64_SIMD_FLAGS="-mfpu=neon-fp-armv8 -mfloat-abi=hard"
export ARM64_CACHE_FLAGS="-mcpu=cortex-a75 -mtune=cortex-a75"

# Android NDK integration
export ANDROID_NDK_ARM64_FLAGS="-target aarch64-linux-android21"
export ANDROID_SYSROOT="/opt/android-ndk/sysroot"

# Memory optimization for mobile
export MALLOC_ARENA_MAX=2
export MALLOC_MMAP_THRESHOLD_=131072

# Node.js ARM64 optimization
export NODE_OPTIONS="--max-old-space-size=2048 --optimize-for-size"

# Python ARM64 optimization
export PYTHONOPTIMIZE=2
export PYTHON_ARM64_FLAGS="-march=armv8-a"

# Rust ARM64 target
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="aarch64-linux-gnu-gcc"
export RUSTFLAGS="-C target-cpu=cortex-a75 -C opt-level=3"
EOF
    
    log "ARM64 optimization configuration saved to: ${config_file}"
}

main() {
    local action="${1:-setup}"
    
    log "Starting SymToolsAgent for WebLabs MobIDE ARM64 environment..."
    log "Action: ${action}"
    log "Architecture: ${ARCH} (ARM64: ${IS_ARM64})"
    
    case "${action}" in
        "setup"|"install")
            create_directory_structure
            install_arm64_toolchain
            setup_arm64_optimization_flags
            log "ARM64 development environment setup completed successfully!"
            ;;
        "clean")
            log "Cleaning ARM64 development environment..."
            rm -rf "${ALPINE_ROOT}"
            log "ARM64 environment cleaned"
            ;;
        *)
            log "Usage: $0 [setup|clean]"
            log "  setup - Setup ARM64 development environment"
            log "  clean - Clean ARM64 environment"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
