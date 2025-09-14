#!/bin/bash
set -e
echo "==> AGENTIC APK BUILD STARTED"

# Install dependencies if needed
if ! command -v java &> /dev/null; then
  echo "Java not found, installing..."
  sudo apt-get update
  sudo apt-get install -y openjdk-17-jdk
fi

# Setup Android SDK path (if needed)
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# Build the APK using Gradle
cd QuantumAIIDE
./gradlew assembleRelease

echo "==> APK BUILD COMPLETE"
ls -l app/build/outputs/apk/release/

# Optionally upload artifact (if running on a CI runner with artifact upload support)
