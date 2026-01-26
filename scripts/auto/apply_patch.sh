#!/bin/bash
# WebLabs-MobIDE Patch Application Script
# Apply generated patches for high-priority fixes
# Usage: ./scripts/auto/apply_patch.sh [patch-name]

set -euo pipefail

SCRIPT_DIR="$(cd ""+"$(dirname "");
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)
PATCH_DIR="$REPO_ROOT/scripts/auto/patches"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to apply Dockerfile patch
apply_dockerfile_patch() {
  log_info "Applying Dockerfile patch..."
  if [ -f "$PATCH_DIR/dockerfile.patch" ]; then
    patch -p0 < "$PATCH_DIR/dockerfile.patch"
    log_info "✅ Dockerfile patched"
  else
    log_warn "No Dockerfile patch found"
  fi
}

# Function to apply build.gradle.kts patch
apply_gradle_patch() {
  log_info "Applying Gradle configuration patch..."
  if [ -f "$PATCH_DIR/gradle-config.patch" ]; then
    patch -p0 < "$PATCH_DIR/gradle-config.patch"
    log_info "✅ Gradle patched"
  else
    log_warn "No Gradle patch found"
  fi
}

# Function to apply docker-compose patch
apply_compose_patch() {
  log_info "Applying docker-compose.yml patch..."
  if [ -f "$PATCH_DIR/docker-compose.patch" ]; then
    patch -p0 < "$PATCH_DIR/docker-compose.patch"
    log_info "✅ docker-compose.yml patched"
  else
    log_warn "No docker-compose patch found"
  fi
}

# Function to apply code-server startup script
apply_codeserver_patch() {
  log_info "Applying code-server startup script..."
  if [ -f "$PATCH_DIR/start-code-server.sh" ]; then
    cp "$PATCH_DIR/start-code-server.sh" "$REPO_ROOT/scripts/docker/start-code-server.sh"
    chmod +x "$REPO_ROOT/scripts/docker/start-code-server.sh"
    log_info "✅ code-server startup script deployed"
  else
    log_warn "No code-server startup script found"
  fi
}

# Function to apply all patches
apply_all() {
  log_info "Applying all patches..."
  apply_dockerfile_patch
  apply_gradle_patch
  apply_compose_patch
  apply_codeserver_patch
  log_info "✅ All patches applied successfully"
}

# Main logic
if [ $# -eq 0 ]; then
  log_warn "No patch specified. Usage: ./apply_patch.sh [dockerfile|gradle|compose|codeserver|all]"
  exit 1
}

case "$1" in
dockerfile)
    apply_dockerfile_patch
    ;;
gradle)
    apply_gradle_patch
    ;;
compose)
    apply_compose_patch
    ;;;
codeserver)
    apply_codeserver_patch
    ;;;
all)
    apply_all
    ;;;
*)
    log_error "Unknown patch: $1"
    exit 1
    ;;
esac

log_info "Patch application complete!"