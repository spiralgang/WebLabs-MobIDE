#!/bin/bash
# Codet5.sh - Setup and import Salesforce/codet5-small model locally.

set -e

MODEL_REPO="Salesforce/codet5-small"
MODEL_URL="https://huggingface.co/${MODEL_REPO}"
PYTHON_VERSION="3.8"

echo "=== Setting up Python environment ==="
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

echo "=== Installing git-lfs and HuggingFace CLI ==="
git lfs install
pip install huggingface_hub

echo "=== Cloning Codet5 model from HuggingFace ==="
git clone ${MODEL_URL}.git

echo "=== Downloading model files with HuggingFace CLI ==="
huggingface-cli download ${MODEL_REPO}

echo "=== Importing model via import_model.py (if exists) ==="
if [ -f import_model.py ]; then
    python import_model.py
fi

echo "=== Setup Complete ==="

# References:
# - /reference/vault
# - https://huggingface.co/Salesforce/codet5-small
# - https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
# - https://tldp.org/LDP/Bash-Beginners-Guide/html/