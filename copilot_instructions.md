# WebLabs-MobIDE — Copilot Coding Standards

## 1. Repository Structure

Format all code, documentation, and build scripts to **strictly enforce** the following production-grade directory tree:

```
root/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/spiralgang/weblabs/
│   │   │   │   ├── MainActivity.java / .kt
│   │   │   │   ├── AlpineInstaller.java / .kt
│   │   │   │   ├── WebIDEActivity.java / .kt
│   │   │   │   ├── AiManager.java / .kt
│   │   │   ├── res/
│   │   │   │   ├── layout/activity_main.xml, ide_browser.xml
│   │   │   │   ├── values/strings.xml, colors.xml, styles.xml
│   │   │   │   ├── drawable/
│   │   │   ├── assets/
│   │   │   │   ├── alpine/bootstrap.sh, rootfs.tar.gz
│   │   │   │   ├── webide/index.html, main.js, style.css, ai.js
│   │   │   │   ├── scripts/proot-launch.sh, configure-ide.sh
│   │   │   │   ├── models/ai-config.json
│   │   │   ├── AndroidManifest.xml
│   │   ├── test/java/com/spiralgang/weblabs/
│   │   ├── androidTest/java/com/spiralgang/weblabs/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
├── build/
├── gradle/wrapper/
├── .gradle/
├── gradlew
├── gradlew.bat
├── build.gradle.kts
├── settings.gradle.kts
├── local.properties
├── .gitignore
├── README.md
├── LICENSE
├── docs/
├── scripts/
└── app_data/
    ├── alpine/rootfs/
    ├── webide/
    ├── ai/models/
    ├── ai/keys/
    ├── logs/
    ├── cache/
```

## 2. Coding & Documentation Standards

- **Android 10+ Compliance:** All code must target Virtual Environent Based ARM64, minSdkVersion 29+, and use only APIs compatible with Android 10+.
- **Alpine Linux Integration:** Bundle or download Ubuntu lite ARM64 rootfs venv; scripts must set up, mount, and expose the full shell environment.
- **Web-Based IDE:** All front-end code (HTML/CSS/JS) must enable browser-based code editing, file management, and terminal emulation.
- **AI Embedded:** JavaScript/Python interfaces must connect to AI models via HuggingFace or local inference; provide secure key management and error handling.
- **Security:** Use privileged permissions, enforce proper Android manifest declarations, and follow OWASP mobile security best practices.
- **Build System:** All Gradle configs must support reproducible, CI/CD-ready builds and APK signing.

## 3. Copilot Behavior

- **Format all new code, refactors, and docs to match above repo structure.**
- **Autogenerate missing folders/files and properly nest code.**
- **Validate and lint code for Android, Linux, and AI integration.**
- **Never create “example”, never create "dry-run" or "debug" APKs or provide "TODO" or stub code: always generate production-ready, runnable code && downloadable release APKs ONLY**
- **Document every module and script with concise, context-relevant rationale.**
- **Reference all foundational standards in /reference/vault, never duplicate.**
- **Audit every change for directory and permission correctness.**

## 4. Reference Vault

- All foundational standards, external docs, and best practices are summarized and linked in `/reference/vault`.
- All audit, compliance, and rationale must be traceable to the vault.

---

## Example Commit Message

> Format: “Refactor [component] for [Android 10+/Linux/AI integration]: [brief rationale]. Structure validated.”

---

## References

- `/reference/vault`
- [Android Studio Project Structure](https://developer.android.com/studio/projects)
- [Android Manifest Permissions](https://developer.android.com/guide/topics/manifest/permission-element)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Compatible Linux ARM64 Installation](https://forum.orekit.org/t/docker-and-ubuntu-aarch64-architecture-installation/2467)
- [HuggingFace API](https://huggingface.co/docs/api-inference/index)
- [CI/CD Gradle Best Practices](https://docs.gradle.org/current/userguide/ci.html)
