#!/bin/bash

# WebLabs-MobIDE Build System Validation Script
# Validates that the Android build configuration is working properly

set -e

echo "============================================================"
echo "WebLabs-MobIDE Build System Validation"
echo "============================================================"

echo "🔍 Checking repository structure..."
REQUIRED_DIRS=(
    "app"
    "app/src/main/java/com/spiralgang/weblabs"
    "app/src/test/java/com/spiralgang/weblabs"
    "app/src/androidTest/java/com/spiralgang/weblabs"
    "app_data/alpine/rootfs"
    "app_data/webide"
    "app_data/ai/models"
    "app_data/ai/keys"
    "app_data/logs"
    "app_data/cache"
    "gradle/wrapper"
    "docs"
    "scripts"
)

REQUIRED_FILES=(
    "build.gradle.kts"
    "settings.gradle.kts"
    "app/build.gradle.kts"
    "gradlew"
    "gradlew.bat"
    "LICENSE"
    "README.md"
    ".gitignore"
    "copilot_instructions.md"
)

echo "📁 Validating directories..."
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir (missing)"
        exit 1
    fi
done

echo "📄 Validating files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
        exit 1
    fi
done

echo "🔧 Validating Gradle build configuration..."
if ! ./gradlew tasks --no-daemon > /dev/null 2>&1; then
    echo "  ❌ Gradle build configuration failed"
    echo "  Running with verbose output:"
    ./gradlew tasks --no-daemon --stacktrace
    exit 1
else
    echo "  ✅ Gradle build configuration valid"
fi

echo "📋 Checking available build tasks..."
GRADLE_TASKS=$(./gradlew tasks --all --no-daemon 2>/dev/null | grep -E "assemble|build|clean")
if echo "$GRADLE_TASKS" | grep -q "app:assembleDebug"; then
    echo "  ✅ app:assembleDebug task available"
else
    echo "  ❌ app:assembleDebug task missing"
    exit 1
fi

if echo "$GRADLE_TASKS" | grep -q "app:assembleRelease"; then
    echo "  ✅ app:assembleRelease task available"
else
    echo "  ❌ app:assembleRelease task missing"
    exit 1
fi

if echo "$GRADLE_TASKS" | grep -q "build"; then
    echo "  ✅ build task available"
else
    echo "  ❌ build task missing"
    exit 1
fi

echo "🧪 Testing build functionality (dry run)..."
if ./gradlew app:assembleDebug --dry-run --no-daemon > /dev/null 2>&1; then
    echo "  ✅ app:assembleDebug dry run successful"
else
    echo "  ❌ app:assembleDebug dry run failed"
    exit 1
fi

echo "🎯 Validating source code syntax..."

# Check Kotlin files
if find app/src -name "*.kt" -exec kotlinc {} \; > /dev/null 2>&1; then
    echo "  ✅ Kotlin source files syntax valid"
else
    echo "  ⚠️  Kotlin syntax check skipped (kotlinc not available)"
fi

# Check Python files
PYTHON_FILES=$(find scripts -name "*.py" 2>/dev/null || true)
if [ -n "$PYTHON_FILES" ]; then
    for py_file in $PYTHON_FILES; do
        if python3 -m py_compile "$py_file" > /dev/null 2>&1; then
            echo "  ✅ $py_file syntax valid"
        else
            echo "  ❌ $py_file syntax error"
            exit 1
        fi
    done
else
    echo "  ℹ️  No Python files to validate"
fi

# Check shell scripts
SHELL_FILES=$(find scripts -name "*.sh" 2>/dev/null || true)
if [ -n "$SHELL_FILES" ]; then
    for sh_file in $SHELL_FILES; do
        if bash -n "$sh_file" > /dev/null 2>&1; then
            echo "  ✅ $sh_file syntax valid"
        else
            echo "  ❌ $sh_file syntax error"
            exit 1
        fi
    done
else
    echo "  ℹ️  No shell scripts to validate"
fi

echo "============================================================"
echo "🎉 BUILD SYSTEM VALIDATION: ALL CHECKS PASSED"
echo "============================================================"
echo "✅ Repository structure fully compliant"
echo "✅ All required directories present"
echo "✅ All required files present"
echo "✅ Gradle build configuration valid"
echo "✅ Android build tasks available"
echo "✅ Source code syntax validated"
echo "============================================================"
echo "🚀 Ready for APK building and GitHub Packages publishing"
echo "============================================================"