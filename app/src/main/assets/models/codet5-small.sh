#!/bin/bash
# Minimal Hugging Face model downloader (Android 10+/Aarch64 safe)

MODEL_REPO="${1:-Salesforce/codet5-small}"
TARGET_DIR="${2:-app/src/main/assets/models/codet5-small}"

mkdir -p "$TARGET_DIR" 2>/dev/null || true

# Install git-lfs if missing, ignore errors
command -v git-lfs >/dev/null 2>&1 || {
  sudo apt-get update -y || true
  sudo apt-get install -y git-lfs || true
  git lfs install --system || true
}

# Attempt model download, ignore failures
git clone https://huggingface.co/Salesforce/codet5-small
git clone "https://huggingface.co/${MODEL_REPO}" "$TARGET_DIR" || true

# Strip .git and .cache, ignore errors
find "$TARGET_DIR" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
find "$TARGET_DIR" -name ".cache" -type d -exec rm -rf {} + 2>/dev/null || true
find "$TARGET_DIR" -type f -exec chmod 0644 {} + 2>/dev/null || true

echo "Done. Model files (if any) are in $TARGET_DIR"
