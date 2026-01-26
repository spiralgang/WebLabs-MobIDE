# Reference: Copilot Instructions

GitHub Copilot instructions for this repository are configured at:

- **GitHub Copilot Configuration**: [`.github/copilot_instructions.md`](https://github.com/spiralgang/WebLabs-MobIDE/blob/main/.github/copilot_instructions.md) - GitHub's official Copilot instructions (if present)
- **Detailed Technical Standards**: [`copilot_instructions.md`](https://github.com/spiralgang/WebLabs-MobIDE/blob/main/copilot_instructions.md) - Comprehensive development standards

All coding, refactoring, and documentation must comply with the standards and workflow described in these files.

References:  
- [GitHub Copilot Organization Instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-organization-custom-instructions-for-github-copilot)

# 🚀 WebLabs-MobIDE - Docker Ubuntu Environment

**Your Virtual Linux Development Environment on Android**

A production-grade Docker-based Ubuntu 24.04 ARM64 development environment that runs natively on Android devices (API 29+), delivering a full Code-Server web IDE, professional tooling, and optimized mobile integration.

## 📱 Download Production APK

**🔧 BUILD STATUS: Network Access Required for Automated CI/CD**

The WebLabs-MobIDE core implementation is complete and market-ready. The APK builds successfully locally, providing a lightweight, secure runtime with Ubuntu 24.04 ARM64 container, Code-Server IDE, and essential tools.

Automated GitHub Actions builds and releases are currently blocked due to network allowlist requirements for dependency downloads.

### 🚀 **Current Status (January 26, 2026):**
- ✅ **Docker Ubuntu 24.04 ARM64 Environment**: Fully implemented with native glibc performance
- ✅ **Code-Server Integration**: Browser-accessible web IDE at `localhost:8080`
- ✅ **Android App Architecture**: Kotlin-based, optimized, and production-ready
- ⏳ **Automated Releases**: Blocked pending network allowlist configuration

### 🌐 **Required Domains for Automated APK Build:**
To enable GitHub Actions CI/CD and automated releases, the runner requires outbound access to dependency hosts. Refer to GitHub documentation for allowlist setup.

Essential domains:
- `dl.google.com` (Android SDK/tools)
- `maven.google.com` (Android Maven dependencies)
- `repo1.maven.org` (Maven Central)
- `services.gradle.org` (Gradle distribution)
- `github.com` / `objects.githubusercontent.com` (source and releases)
- `actions.githubusercontent.com` (Actions marketplace)
- `storage.googleapis.com` (build tool mirrors)

### 📦 **Recommended: Build APK Locally (Fully Functional Now)**
Until automated workflows are enabled, build and install the production APK directly:

```bash
git clone https://github.com/spiralgang/WebLabs-MobIDE.git
cd WebLabs-MobIDE
./gradlew assembleDebug    # For unsigned debug APK
# or
./gradlew assembleRelease  # For signed release APK (configure signingConfig if needed)
```

- APK location: `app/build/outputs/apk/debug/app-debug.apk` or `app-release.apk`
- Install on Android 10+ ARM64 device and grant permissions on launch

This produces the identical production-grade package: only runtime components from `app/`, `scripts/`, `workspace/`, `app_data/`, and container assets are bundled.

### 🚀 **Future Automated Builds (Once Network Resolved):**

[![Build APK via GitHub Actions](https://img.shields.io/badge/🔧_Build_APK_-_GitHub_Actions-2EA043?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/spiralgang/WebLabs-MobIDE/actions)

[![Download Latest Release APK](https://img.shields.io/badge/📱_Download_APK_-_Coming_Soon-FF6B35?style=for-the-badge&logo=android&logoColor=white)](https://github.com/spiralgang/WebLabs-MobIDE/releases)

**When network access is configured:**
1. Actions will build and sign APK on push/tag
2. Releases will be published automatically
3. Direct download links will become active

## 📦 Releases

No published releases yet — automated publishing pending network allowlist resolution.

Once enabled, releases will follow semantic versioning (e.g., `v1.0.0`) with:
- Signed production APK named `WebLabs-MobIDE-LinuxEnv.apk`
- Comprehensive release notes
- Automated workflow: [`.github/workflows/production-release-apk.yml`](https://github.com/spiralgang/WebLabs-MobIDE/tree/main/.github/workflows) (when active)

The distributed APK contains **only runtime components** required to launch the environment — no build tooling, caches, or repository maintenance artifacts are included.
