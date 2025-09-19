#!/bin/bash

# WebLabs-MobIDE Userland Flow Tracer - Fixed Version
# Tracks system state changes and allows rollback for development environment

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_ARCHIVES="${SCRIPT_DIR}/../../app_data/logs/state_archives"
LOG_FILE="${SCRIPT_DIR}/../../app_data/logs/userland_tracer.log"

# Create required directories
mkdir -p "$STATE_ARCHIVES"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Save current system state
save_state() {
    local state_name="${1:-$(date +%Y%m%d_%H%M%S)}"
    local state_dir="${STATE_ARCHIVES}/${state_name}"
    
    mkdir -p "$state_dir"
    
    log "Saving system state: $state_name"
    
    # Save package information
    dpkg --get-selections > "${state_dir}/packages.list" 2>/dev/null || true
    apt-mark showmanual > "${state_dir}/manual_packages.list" 2>/dev/null || true
    
    log "State saved: $state_name"
    echo "$state_name"
} 

# Rollback function - restore system state
rollback() {
    local state_name="$1"
    local state_dir="${STATE_ARCHIVES}/${state_name}"
    
    if [ ! -d "$state_dir" ]; then
        log "ERROR: State not found: $state_name"
        return 1
    fi
    
    log "Rolling back to: $state_name"
    
    # Restore package state
    if [ -f "${state_dir}/packages.list" ]; then
        dpkg --clear-selections
        dpkg --set-selections < "${state_dir}/packages.list"
        apt-get update
        apt-get install -y --allow-downgrades $(awk '{print $1}' "${state_dir}/packages.list" | grep -v deinstall) || true
    fi
    
    log "Rollback completed: $state_name"
}

# Check for conflicts but don't block
check_conflicts() {
    local package="$1"
    log "Checking conflicts for: $package"
    
    local conflicts=$(apt-cache show "$package" 2>/dev/null | grep -i "^Conflicts:" | cut -d: -f2- || true)
    
    if [ -n "$conflicts" ]; then
        log "WARNING: Package $package has conflicts: $conflicts"
    fi
}

# Main execution
case "${1:-help}" in
    save)
        save_state "$2"
        ;;
    rollback)
        if [ -z "$2" ]; then
            echo "Usage: $0 rollback <state_name>"
            exit 1
        fi
        rollback "$2"
        ;;
    list)
        log "Available states:"
        ls -1 "$STATE_ARCHIVES" 2>/dev/null || echo "No states found"
        ;;
    check)
        if [ -z "$2" ]; then
            echo "Usage: $0 check <package_name>"
            exit 1
        fi
        check_conflicts "$2"
        ;;
    help|*)
        echo "WebLabs-MobIDE Userland Flow Tracer"
        echo "Usage: $0 {save|rollback|list|check|help} [arguments]"
        echo ""
        echo "Commands:"
        echo "  save [name]     - Save current system state"
        echo "  rollback <name> - Rollback to saved state"
        echo "  list            - List available states"
        echo "  check <package> - Check package conflicts"
        echo "  help            - Show this help"
        ;;
esac
