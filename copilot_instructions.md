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
│   │   │   │   ├── DockerManager.java / .kt
│   │   │   │   ├── WebIDEActivity.java / .kt
│   │   │   │   ├── AiManager.java / .kt
│   │   │   ├── res/
│   │   │   │   ├── layout/activity_main.xml, ide_browser.xml
│   │   │   │   ├── values/strings.xml, colors.xml, styles.xml
│   │   │   │   ├── drawable/
│   │   │   ├── assets/
│   │   │   │   ├── scripts/start-ide.sh
│   │   │   │   ├── webide/index.html, main.js, style.css, ai.js
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
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── local.properties
├── .gitignore
├── README.md
├── LICENSE
├── docs/
├── scripts/
│   ├── docker/
│   │   ├── docker-manager.sh
│   │   ├── new-project.sh
└── workspace/
    ├── projects/
    ├── ai/models/
    ├── ai/cache/
    ├── logs/
```

## 2. Coding & Documentation Standards

- **Android 10+ Compliance:** All code must target ARM64, minSdkVersion 29+, and use only APIs compatible with Android 10+.
- **Docker Integration:** Bundle Ubuntu 24.04 ARM64 Docker environment; scripts must set up, manage, and expose the full development environment.
- **Web-Based IDE:** All front-end code (HTML/CSS/JS) must enable browser-based code editing, file management, and terminal emulation via Code-Server.
- **AI Embedded:** JavaScript/Python interfaces must connect to AI models via HuggingFace or local inference; provide secure key management and error handling.
- **Security:** Use privileged permissions, enforce proper Android manifest declarations, and follow OWASP mobile security best practices.
- **Build System:** All Gradle configs must support reproducible, CI/CD-ready builds, APK signing, and GitHub Copilot compatibility.

## 3. Docker Environment Standards

- **Base Image:** Ubuntu 24.04 ARM64 with glibc (NO Alpine Linux or musl)
- **Containerization:** Docker-based (NO proot virtualization)
- **Performance:** Native performance without proot overhead
- **IDE:** Code-Server web-based VS Code environment
- **Tools:** Android SDK, NDK, Python 3, Node.js, build tools
- **GitHub Copilot:** Full compatibility with standard Ubuntu environment

## 4. Copilot Behavior

- **Format all new code, refactors, and docs to match above repo structure.**
- **Use Docker and Ubuntu 24.04 ARM64 instead of Alpine Linux or proot.**
- **Validate and lint code for Android, Linux, and AI integration.**
- **Never create "example" or stub code: always generate production-ready, runnable code only.**
- **Document every module and script with concise, context-relevant rationale.**
- **Reference all foundational standards in /reference/vault, never duplicate.**
- **Audit every change for directory and permission correctness.**

## 5. Reference Vault

- All foundational standards, external docs, and best practices are summarized and linked in `/reference/vault`.
- All audit, compliance, and rationale must be traceable to the vault.

---

## Example Commit Message

> Format: "Refactor [component] for [Android 10+/Docker/AI integration]: [brief rationale]. Structure validated."

---

## References

- `/reference/vault`
- [Android Studio Project Structure](https://developer.android.com/studio/projects)
- [Android Manifest Permissions](https://developer.android.com/guide/topics/manifest/permission-element)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Docker Documentation](https://docs.docker.com/)
- [Ubuntu 24.04 ARM64](https://ubuntu.com/download/server/arm)
- [HuggingFace API](https://huggingface.co/docs/api-inference/index)
- [CI/CD Gradle Best Practices](https://docs.gradle.org/current/userguide/ci.html)