#!/system/bin/sh
# Codet5.sh - Android 10 aarch64 AI model setup, privilege ops

set -e

MODEL_REPO="Salesforce/codet5-small"
MODEL_URL="https://huggingface.co/${MODEL_REPO}"
PYTHON_BIN="/system/bin/python3"
PYTHON_VERSION="3.8"

echo "=== [Android 10] Python venv setup (aarch64) ==="
if [ ! -d venv ]; then
    $PYTHON_BIN -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

echo "=== git-lfs, HuggingFace CLI setup ==="
git lfs install || echo "git-lfs not found, skipping"
pip install huggingface_hub

echo "=== Cloning Codet5 model ==="
git clone ${MODEL_URL}.git

echo "=== Downloading model files ==="
huggingface-cli download ${MODEL_REPO}

echo "=== Import model with Python (if exists) ==="
if [ -f import_model.py ]; then
    $PYTHON_BIN import_model.py
fi

echo "=== [Android 10] Privileged paths ==="
ls -l /system/etc/security/cacerts/ || echo "No CA certs found"
ls -l /data/misc/user/0/cacerts-added/ || echo "No user certs found"

echo "=== Setup Complete ==="
# References:
# - /reference/vault
# - https://developer.android.com/about/versions/10
# - https://huggingface.co/Salesforce/codet5-small
# - https://android.googlesource.com/platform/system/extras/+/master/su/