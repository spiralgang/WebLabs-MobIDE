# WebLabs-MobIDE Linux Environment v1.0.0 Release Notes

## Overview
The WebLabs-MobIDE Linux Environment v1.0.0 release packages the complete Android application that provisions a full Ubuntu 24.04 ARM64 container workspace on mobile devices. This build ships the production-ready workflow with Dockerized tooling, Code-Server integration, AI assistance, and the curated developer stack required for day-to-day work directly from an Android handset.

## Download
- **Direct APK:** [WebLabs-MobIDE-LinuxEnv.apk](https://github.com/WebLabs-MobIDE/WebLabs-MobIDE/releases/download/v1.0.0/WebLabs-MobIDE-LinuxEnv.apk)
- **Release page:** [v1.0.0 Release](https://github.com/WebLabs-MobIDE/WebLabs-MobIDE/releases/tag/v1.0.0)
- **Automated CI build:** [`production-release-apk.yml`](../../.github/workflows/production-release-apk.yml)

> ℹ️ Upload the signed production APK with the exact filename `WebLabs-MobIDE-LinuxEnv.apk` when drafting the GitHub release. The direct link above will become active automatically once the asset is attached.

### Production build through GitHub Actions

> 📘 Ensure the [GitHub Actions network allowlist](../operations/actions-network-allowlist.md) is configured before triggering the build so dependency downloads succeed on GitHub-hosted runners.

1. **Generate release keystore** (Android Studio ▸ Build ▸ Generate Signed Bundle / APK) and export it to Base64: `base64 your-release-key.jks > keystore.b64`.
2. **Add repository secrets** under *Settings ▸ Secrets and variables ▸ Actions* using the following keys:
   - `KEYSTORE_BASE64` – full contents of `keystore.b64`
   - `KEYSTORE_PASSWORD` – password chosen for the keystore
   - `KEY_ALIAS` – alias specified during keystore creation
   - `KEY_PASSWORD` – password assigned to the alias
3. **Create and push a semantic version tag**, for example:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```
4. The [Build and Release Production APK workflow](../../.github/workflows/production-release-apk.yml) assembles the signed `WebLabs-MobIDE-LinuxEnv.apk`, publishes a GitHub Release, and attaches the artifact for direct download.

### Runtime payload

The CI workflow strips build-time tooling before publishing. The shipped APK contains only the runtime components required to provision the WebLabs-MobIDE environment—Gradle wrappers, caches, or auxiliary build scripts are never packaged inside the release artifact.

## Highlights
- **Full Docker Ubuntu 24.04 ARM64 environment** with persistent workspace volumes and bundled container tooling.
- **Code-Server web IDE** preconfigured for remote editing, terminal access, and extension marketplace support.
- **AI-assisted development** powered by the repository's integrated automation workflows.
- **Android-native management interface** with monitoring dashboards, deployment orchestration, and secure secret handling.
- **Pre-bundled developer toolchain** (Android SDK/NDK, Node.js, Python, Git, build essentials) optimized for mobile hardware.

## Installation
1. Download the APK using the direct link above once the release asset is published.
2. Transfer the APK to the target Android 10+ ARM64 device if necessary.
3. Enable **Install unknown apps** for the file manager or browser used for installation.
4. Open the APK and follow the Android package installer prompts to complete installation.
5. Launch **WebLabs MobIDE** and complete the first-run provisioning wizard to start the Docker environment and Code-Server IDE.

## Verification
Provide the checksum values from the signed artifact on the release page to allow users to validate integrity before installation. Recommended commands:

```bash
# After downloading WebLabs-MobIDE-LinuxEnv.apk
echo "SHA-256: $(sha256sum WebLabs-MobIDE-LinuxEnv.apk | cut -d' ' -f1)"
echo "SHA-512: $(sha512sum WebLabs-MobIDE-LinuxEnv.apk | cut -d' ' -f1)"
```

Publish the resulting hashes in the release description to give users a verifiable trust anchor.

## Support & Feedback
- Report installation or runtime issues through the repository's Issues tab with device model, Android version, and reproduction steps.
- For security concerns, follow the responsible disclosure practices documented in `docs/security_tools_compilation.json`.
- Enhancement proposals are welcome—open a discussion thread or draft PR referencing this release.

## Release Management Checklist
- [ ] Build the production APK via the documented CI workflow.
- [ ] Sign the APK with the official release keystore.
- [ ] Upload `WebLabs-MobIDE-LinuxEnv.apk` as a GitHub release asset.
- [ ] Add SHA-256 and SHA-512 checksums to the release description.
- [ ] Link back to this document from the release notes for comprehensive guidance.
