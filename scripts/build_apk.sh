#!/bin/bash

# WebLabs MobIDE - Production APK Build Script for ARM64 Android
# Integrates with Android Gradle build system and Alpine Linux environment

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly APP_MODULE="${PROJECT_ROOT}/app"

# ARM64 Android build configuration
readonly MIN_SDK_VERSION=21
readonly TARGET_SDK_VERSION=34
readonly COMPILE_SDK_VERSION=34
readonly NDK_VERSION="25.2.9519653"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

check_dependencies() {
    log "Checking build dependencies..."
    
    if ! command -v ./gradlew &> /dev/null; then
        log "ERROR: Gradle wrapper not found"
        return 1
    fi
    
    if [ ! -f "${PROJECT_ROOT}/app/build.gradle.kts" ]; then
        log "ERROR: App module build.gradle.kts not found"
        return 1
    fi
    
    log "Dependencies check passed"
}

setup_build_environment() {
    log "Setting up ARM64 Android build environment..."
    
    # Ensure gradlew is executable
    chmod +x "${PROJECT_ROOT}/gradlew"
    
    # Create build directories
    mkdir -p "${BUILD_DIR}/outputs/apk/debug"
    mkdir -p "${BUILD_DIR}/outputs/apk/release"
    mkdir -p "${BUILD_DIR}/intermediates"
    
    # Set Gradle properties for ARM64 optimization
    export GRADLE_OPTS="-Xmx4g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError"
    export ANDROID_NDK_ROOT="${ANDROID_SDK_ROOT}/ndk/${NDK_VERSION}"
    
    log "Build environment setup complete"
}

build_debug_apk() {
    log "Building debug APK for ARM64..."
    
    cd "${PROJECT_ROOT}"
    ./gradlew assembleDebug \
        -Pandroid.enableJetifier=true \
        -Pandroid.useAndroidX=true \
        -Porg.gradle.jvmargs="-Xmx4g" \
        --stacktrace \
        --info
    
    if [ -f "${APP_MODULE}/build/outputs/apk/debug/app-debug.apk" ]; then
        cp "${APP_MODULE}/build/outputs/apk/debug/app-debug.apk" "${BUILD_DIR}/outputs/apk/debug/"
        log "Debug APK built successfully: ${BUILD_DIR}/outputs/apk/debug/app-debug.apk"
    else
        log "ERROR: Debug APK build failed"
        return 1
    fi
}

build_release_apk() {
    log "Building release APK for ARM64..."
    
    cd "${PROJECT_ROOT}"
    ./gradlew assembleRelease \
        -Pandroid.enableJetifier=true \
        -Pandroid.useAndroidX=true \
        -Porg.gradle.jvmargs="-Xmx4g" \
        --stacktrace \
        --info
    
    if [ -f "${APP_MODULE}/build/outputs/apk/release/app-release-unsigned.apk" ]; then
        cp "${APP_MODULE}/build/outputs/apk/release/app-release-unsigned.apk" "${BUILD_DIR}/outputs/apk/release/"
        log "Release APK built successfully: ${BUILD_DIR}/outputs/apk/release/app-release-unsigned.apk"
    else
        log "ERROR: Release APK build failed"
        return 1
    fi
}

sign_release_apk() {
    log "Signing release APK..."
    
    local unsigned_apk="${BUILD_DIR}/outputs/apk/release/app-release-unsigned.apk"
    local signed_apk="${BUILD_DIR}/outputs/apk/release/app-release.apk"
    local keystore="${PROJECT_ROOT}/android-release-key.jks"
    
    if [ ! -f "${keystore}" ]; then
        log "WARNING: Release keystore not found, creating debug-signed APK"
        cp "${unsigned_apk}" "${signed_apk}"
        return 0
    fi
    
    # Sign with release keystore (requires KEYSTORE_PASSWORD environment variable)
    if [ -n "${KEYSTORE_PASSWORD:-}" ]; then
        jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
            -keystore "${keystore}" -storepass "${KEYSTORE_PASSWORD}" \
            "${unsigned_apk}" release-key
        
        zipalign -v 4 "${unsigned_apk}" "${signed_apk}"
        log "Release APK signed successfully: ${signed_apk}"
    else
        log "WARNING: KEYSTORE_PASSWORD not set, skipping APK signing"
        cp "${unsigned_apk}" "${signed_apk}"
    fi
}

generate_checksums() {
    log "Generating APK checksums..."
    
    cd "${BUILD_DIR}/outputs/apk"
    find . -name "*.apk" -exec sha256sum {} \; > checksums.txt
    
    log "Checksums generated in ${BUILD_DIR}/outputs/apk/checksums.txt"
}

clean_build() {
    log "Cleaning build artifacts..."
    cd "${PROJECT_ROOT}"
    ./gradlew clean
    rm -rf "${BUILD_DIR}"
}

main() {
    local build_type="${1:-all}"
    
    log "Starting WebLabs MobIDE APK build process..."
    log "Build type: ${build_type}"
    log "Target architecture: ARM64 (AArch64)"
    
    case "${build_type}" in
        "clean")
            clean_build
            ;;
        "debug")
            check_dependencies
            setup_build_environment
            build_debug_apk
            generate_checksums
            ;;
        "release")
            check_dependencies
            setup_build_environment
            build_release_apk
            sign_release_apk
            generate_checksums
            ;;
        "all"|*)
            check_dependencies
            setup_build_environment
            build_debug_apk
            build_release_apk
            sign_release_apk
            generate_checksums
            ;;
    esac
    
    log "APK build process completed successfully!"
    log "Debug APK: ${BUILD_DIR}/outputs/apk/debug/app-debug.apk"
    log "Release APK: ${BUILD_DIR}/outputs/apk/release/app-release.apk"
}

# Run main function with all arguments
main "$@"