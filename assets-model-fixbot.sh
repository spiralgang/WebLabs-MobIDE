#!/bin/bash
# WebLabs-MobIDE: Automated Model & Repo Hygiene Bot (Android 10+/Aarch64 Safe)
# Purpose: One-step remediation for Hugging Face model download, .git/.cache hygiene, permissions, and audit logging.
# Usage: ./assets-model-fixbot.sh [MODEL_REPO] [TARGET_DIR]
# Defaults: MODEL_REPO="Salesforce/codet5-small", TARGET_DIR="app/src/main/assets/models/codet5-small"
# Layered rationale: See end-of-file References.

set -e

MODEL_REPO="${1:-Salesforce/codet5-small}"
TARGET_DIR="${2:-app/src/main/assets/models/codet5-small}"
LOG_FILE="${TARGET_DIR}/_fixbot_audit.log"
TIME_NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$TARGET_DIR" 2>/dev/null || true

audit() {
  echo "[$TIME_NOW] $*" | tee -a "$LOG_FILE"
}

audit "Starting fixbot: Model=$MODEL_REPO Target=$TARGET_DIR"

# Check/Install git-lfs (Android 10+ safe)
if ! command -v git-lfs >/dev/null 2>&1; then
  audit "git-lfs missing: attempting install (may require root)"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y || audit "apt-get update failed"
    sudo apt-get install -y git-lfs || audit "git-lfs install failed"
    git lfs install --system || audit "git-lfs system install failed"
  else
    audit "apt-get unavailable: git-lfs must be installed manually"
  fi
else
  audit "git-lfs present"
fi

# Download model from Hugging Face (ignore failures, but log)
audit "Cloning model repo: https://huggingface.co/${MODEL_REPO}"
git clone "https://huggingface.co/${MODEL_REPO}" "$TARGET_DIR" 2>>"$LOG_FILE" || audit "Model clone failed (may already exist)"

# Clean up .git/.cache (directory hygiene)
for DIR in ".git" ".cache"; do
  if find "$TARGET_DIR" -name "$DIR" -type d | grep -q .; then
    audit "Cleaning $DIR from $TARGET_DIR"
    find "$TARGET_DIR" -name "$DIR" -type d -exec rm -rf {} + 2>>"$LOG_FILE" || audit "Failed to remove $DIR"
  fi
done

# Fix file permissions (Android 10+ safe)
audit "Standardizing file permissions (0644)"
find "$TARGET_DIR" -type f -exec chmod 0644 {} + 2>>"$LOG_FILE" || audit "chmod failed"

# Audit summary
audit "Done. Model files (if any) in: $TARGET_DIR"
audit "References: /reference vault, Hugging Face Doc, Android Dev Doc, WebLabs-MobIDE README"

# End of script

# References:
# - /reference vault: Engineering standards, shell scripting, Android compatibility
# - https://huggingface.co/docs/hub/repositories-downloading
# - https://developer.android.com/ndk/guides
# - https://github.com/spiralgang/WebLabs-MobIDE
