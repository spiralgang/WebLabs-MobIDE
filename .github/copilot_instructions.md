# WebLabs-MobIDE — GitHub Copilot Instructions

## Overview

WebLabs-MobIDE is a production-grade mobile IDE with Docker Ubuntu environment, targeting Android 10+ ARM64 devices. This file provides GitHub Copilot with specific instructions for code generation, refactoring, and development standards.

## Code Generation Guidelines

### Always Generate Production-Ready Code
- **Never create example, stub, or placeholder code**
- Generate fully functional, production-ready implementations only
- Include proper error handling, security considerations, and ARM64 optimizations
- All code must be suitable for app store deployment

### Repository Structure Compliance
Strictly enforce the following directory structure:

```
├── app/
│   ├── src/main/java/com/spiralgang/weblabs/
│   │   ├── MainActivity.kt
│   │   ├── DockerManager.kt
│   │   ├── WebIDEActivity.kt
│   │   └── AiManager.kt
│   ├── src/main/res/
│   │   ├── layout/
│   │   ├── values/
│   │   └── drawable/
│   ├── src/main/assets/
│   │   ├── scripts/
│   │   ├── webide/
│   │   └── models/
│   └── build.gradle.kts
├── .github/
│   ├── workflows/
│   ├── scripts/
│   └── copilot_instructions.md (this file)
├── docs/
├── scripts/
├── reference/vault/
└── build.gradle.kts
```

## Platform-Specific Requirements

### Android Development
- **Target Platform**: Android 10+ (API 29+) ARM64 exclusively
- **Package Structure**: `com.spiralgang.weblabs`
- **Build System**: Gradle 8.7 with Kotlin DSL
- **Security**: Follow OWASP mobile security best practices
- **Performance**: Optimize for ARM64 processors throughout

### Docker Environment
- **Base Image**: Ubuntu 24.04 ARM64 (NOT Alpine Linux)
- **Containerization**: Docker-based (NO proot virtualization)
- **IDE**: Code-Server web-based VS Code environment
- **Tools**: Android SDK, NDK, Python 3, Node.js, build tools

### AI Integration
- **Models**: HuggingFace API with local inference capability
- **Security**: Secure key management and error handling
- **Performance**: ARM64-optimized AI model integration
- **Interface**: JavaScript/Python interfaces for model interaction

## Code Quality Standards

### Documentation
- Document every module and script with concise, context-relevant rationale
- Reference `/reference/vault` for foundational standards
- Include ARM64-specific optimizations in comments

### Security
- Implement production-grade security measures
- Use proper Android manifest declarations
- Include certificate pinning for ARM64 hardware security
- Follow GDPR, CCPA, and app store security requirements

### Testing and CI/CD
- All code must support reproducible, CI/CD-ready builds
- Include proper APK signing configuration
- Integrate with existing GitHub Actions workflows
- Support automated security scanning

## Behavioral Instructions

### What TO Do
- Format all code to match the repository structure above
- Use Docker and Ubuntu 24.04 ARM64 instead of Alpine Linux
- Validate and lint code for Android, Linux, and AI integration
- Audit every change for directory and permission correctness
- Generate production-ready, runnable code only
- Reference standards from `/reference/vault`

### What NOT To Do
- Never create example or stub code
- Never use Alpine Linux or proot virtualization
- Never place workflow YAMLs outside `.github/workflows/`
- Never duplicate foundational standards (reference vault instead)
- Never compromise on ARM64 optimization
- Never generate code without proper error handling

## Commit Message Format

Use this format for all commits:
```
Refactor [component] for [Android 10+/Docker/AI integration]: [brief rationale]. Structure validated.
```

## Reference Materials

All foundational standards, external documentation, and best practices are located in:
- `/reference/vault/` - Central repository standards
- `/docs/COMPLIANCE_REPORT.md` - Current compliance status
- Root `copilot_instructions.md` - Detailed technical specifications

## Validation

Before generating code, ensure:
- [ ] Targets Android 10+ ARM64 exclusively
- [ ] Follows repository directory structure
- [ ] Includes production-grade security
- [ ] Optimized for ARM64 performance
- [ ] References vault materials appropriately
- [ ] Includes proper error handling
- [ ] Suitable for app store deployment

## External References

- [GitHub Copilot Organization Instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-organization-custom-instructions-for-github-copilot)
- [Android Studio Project Structure](https://developer.android.com/studio/projects)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Docker Documentation](https://docs.docker.com/)
- [HuggingFace API](https://huggingface.co/docs/api-inference/index)