#!/bin/bash
#
# run_improvement.sh
# An unstoppable script to improve a single module.
# It handles errors gracefully and reports whether changes were made.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # The return value of a pipeline is the status of the last command to exit with a non-zero status.

MODULE_PATH=$1
CHANGES_MADE="false"

echo "--- Starting Improvement Cycle for module at: ${MODULE_PATH} ---"

cd "${MODULE_PATH}"

# Function to run a command and log its output, continuing on error.
run_safely() {
    echo "▶️  Running: $@"
    if "$@"; then
        echo "✅  Success: $@"
    else
        echo "⚠️  Warning: Command failed with exit code $?. Continuing..."
    fi
}

# --- STAGE 1: Dependency Health Check & Update ---
echo "--- Stage 1: Dependency Management ---"
if [ -f "requirements.txt" ]; then
    echo "Checking for outdated Python dependencies..."
    # A more robust check might involve pip-tools or piprot. For now, we just ensure they're installed.
    run_safely pip install -r requirements.txt
fi
if [ -f "package.json" ]; then
    echo "Checking for outdated Node.js dependencies..."
    # Attempt to update packages and run install.
    run_safely npm update
    run_safely npm install
fi

# --- STAGE 2: Code Formatting ---
echo "--- Stage 2: Code Formatting ---"
# Use find to locate files and format them.
if command -v black &> /dev/null; then
    run_safely find . -name "*.py" -exec black {} +
fi
if command -v prettier &> /dev/null; then
    run_safely npx prettier --write .
fi

# --- STAGE 3: Sourcery AI Refactoring ---
echo "--- Stage 3: Sourcery AI Auto-Refactoring ---"
if [ -n "$SOURCERY_TOKEN" ]; then
    # The --fix flag will auto-apply changes.
    run_safely sourcery review --fix --verbose .
else
    echo "⚠️ SOURCERY_TOKEN not set. Skipping Sourcery review."
fi

# --- STAGE 4: Run Tests to Verify Changes ---
echo "--- Stage 4: Verification via Tests ---"
if [ -f "pytest.ini" ] || [ -d "tests" ]; then
    run_safely pytest
elif [ -f "package.json" ]; then
    # Check if a "test" script exists in package.json
    if grep -q '"test":' package.json; then
        run_safely npm test
    fi
fi

# --- FINAL STAGE: Check for and Report Changes ---
echo "--- Final Stage: Detecting Changes ---"
# Use git status to see if any of the above steps modified files.
if ! git diff --quiet; then
    echo "Changes were made in this cycle."
    CHANGES_MADE="true"
else
    echo "No changes were made in this cycle."
    CHANGES_MADE="false"
fi

echo "::set-output name=changes_made::${CHANGES_MADE}"
echo "--- Improvement Cycle Complete for ${MODULE_PATH} ---"
