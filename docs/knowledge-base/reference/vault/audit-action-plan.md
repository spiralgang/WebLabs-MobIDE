# WebLabs-MobIDE Auto Audit & Action Plan

**Generated:** 2026-01-26 13:48:05  
**Repository:** spiralgang/WebLabs-MobIDE  
**Current Completion:** ~83% → **Target: 100%**

---

## Executive Summary

This document outlines the remaining tasks to reach 100% project completion. All items are **actionable**, **traceable**, and mapped to specific files and vault references.

---

## 📋 Action Items by Priority

### 🔴 CRITICAL (Must Fix)

#### 1. Verify & Finalize Docker (Ubuntu 24.04 ARM64)
- **Status:** Partial (base image OK, buildx verification needed)
- **Files:**
  - `Dockerfile` (exists, base = `ubuntu:24.04`)
  - `docker-compose.yml` (⚠️ needs verification or creation)
  - `scripts/docker/` (docker-manager.sh, startup scripts)
- **Actions:**
  ```bash
  # Verify arm64 buildx support
  docker buildx create --use
  docker buildx build --platform linux/arm64 -t weblabs-mobide:test .
  
  # Verify compose up
  docker-compose up --no-build
  ```
- **Expected Outcome:** Clean arm64 image with code-server, Android SDK/NDK, Python, Node.js
- **Vault Link:** `/reference/vault/docker-standards.md`
- **Deliverable:** Reproducible arm64 Docker image + passing `docker-compose up`

---

#### 2. Android Build Configuration & Reproducibility
- **Status:** Partial (manifest OK, gradle config needs audit)
- **Files:**
  - `app/build.gradle.kts` (verify minSdk, targetSdk, abiFilters)
  - `app/src/main/AndroidManifest.xml` (ARM64 requirement present)
  - `gradle/wrapper/gradle-wrapper.properties` (version control)
- **Actions:**
  ```bash
  # Build debug APK
  ./gradlew assembleDebug --no-daemon
  
  # Build release APK
  ./gradlew assembleRelease --no-daemon
  
  # Check ABI output
  file app/build/outputs/apk/debug/*.apk
  ```
- **Expected Outcome:** Debug + release APKs built for arm64-v8a
- **Vault Link:** `/reference/vault/android-build-standards.md`
- **Checklist:**
  - [ ] minSdk >= 29 (confirmed for Android 10+)
  - [ ] targetSdk >= 33 (or document if higher)
  - [ ] abiFilters includes `arm64-v8a`
  - [ ] gradle-wrapper.properties checked in
  - [ ] Local build succeeds without network calls

---

#### 3. Secrets & API Key Security Audit
- **Status:** ⚠️ Missing secure implementation
- **Files:**
  - `ai/` (server-side HF integration)
  - `app/src/main/assets/webide/ai.js` (client-side AI calls)
  - `.github/workflows/*.yml` (secrets references)
- **Actions:**
  ```bash
  # Verify no API keys in repo
  grep -r "api.key\|API_KEY\|hf_\|huggingface_token" . --include="*.kt" --include="*.js" --include="*.py" | grep -v node_modules || echo "✅ No hardcoded keys found"
  
  # Verify no model weights in ai/models/
  du -sh ai/models/ && find ai/models/ -type f -exec file {} \;
  ```
- **Expected Outcome:** 
  - No API keys in code or history
  - ai/models/ contains only config files, not weights
  - HF_API_KEY loaded from GitHub Secrets
- **Vault Link:** `/reference/vault/secrets-handling.md`
- **Implementation:**
  - [ ] Add `HF_API_KEY` to GitHub repository secrets
  - [ ] Create `.env.example` (no real values)
  - [ ] Implement server-side env var loading
  - [ ] Add safe-fail message if secrets missing

---

#### 4. code-server Hardening & Authentication
- **Status:** ⚠️ Installed but auth not explicitly hardened
- **Files:**
  - `Dockerfile` (code-server installation)
  - `scripts/docker/start-code-server.sh` (startup script with password)
  - `docker-compose.yml` (PORT mapping, auth env)
- **Actions:**
  ```bash
  # Test code-server startup with hashed password
  docker run -e CODE_SERVER_PASSWORD_HASH="$(openssl passwd -6 'mypassword')" ...
  
  # Verify auth required
  curl -i http://localhost:8443/ 2>&1 | grep -i auth
  ```
- **Expected Outcome:** code-server requires authentication (hashed password or OAuth)
- **Vault Link:** `/reference/vault/code-server-hardening.md`
- **Checklist:**
  - [ ] Hashed password mechanism in startup script
  - [ ] PASSWORD_HASH or config file injection documented
  - [ ] No auth bypass in network binding
  - [ ] HTTPS configured or documented as future task

---

### 🟡 HIGH PRIORITY (Complete Soon)

#### 5. CI/CD Secrets Wiring & Signing Automation
- **Status:** Workflows present but signing secrets not fully configured
- **Files:**
  - `.github/workflows/build-and-release-apk.yml`
  - `.github/workflows/build-weblabs-apk.yml`
- **Actions:**
  ```bash
  # Set secrets in GitHub UI
  # Settings → Secrets → New repository secret
  #   - KEYSTORE_BASE64 (base64-encoded .jks)
  #   - KEYSTORE_PASSWORD
  #   - KEY_ALIAS
  #   - KEY_PASSWORD
  #   - HF_API_KEY
  
  # Test signing locally
  jarsigner -verify -verbose app/build/outputs/apk/release/*.apk
  ```
- **Expected Outcome:** CI can sign APK without storing keystore in repo
- **Vault Link:** `/reference/vault/ci-signing-automation.md`
- **Checklist:**
  - [ ] Keystore secrets configured in GitHub
  - [ ] Workflow reads secrets and applies to build
  - [ ] Release artifacts signed and verifiable
  - [ ] APK checksum logged in artifacts

---

#### 6. CodeQL & Security Scanning Fixes
- **Status:** Workflow exists, code-injection alert referenced
- **Files:**
  - `.github/workflows/codeql.yml`
  - Code files with potential code-injection vulnerability
- **Actions:**
  ```bash
  # Run CodeQL locally or review GitHub Security tab
  # Validate fix for code-injection alert (#3)
  ```
- **Expected Outcome:** CodeQL scan clean or all findings documented + mitigated
- **Vault Link:** `/reference/vault/codeql-remediation.md`
- **Checklist:**
  - [ ] CodeQL workflow updated for all languages
  - [ ] Code-injection fix validated (e.g., input sanitization)
  - [ ] No open high-risk findings
  - [ ] Remediation documented in vault

---

#### 7. Linting & Test Pipeline Integration
- **Status:** Linters referenced in CI.yml but may need fuller coverage
- **Files:**
  - `.github/workflows/CI.yml` (linting job)
  - `package.json` (npm lint script)
  - `app/build.gradle.kts` (Android lint)
- **Actions:**
  ```bash
  npm run lint
  ./gradlew lint
  shellcheck scripts/**/*.sh
  ```
- **Expected Outcome:** All code passes linting, tests run in CI
- **Vault Link:** `/reference/vault/linting-standards.md`
- **Checklist:**
  - [ ] eslint configured for JS/TS
  - [ ] Android lint runs in Gradle
  - [ ] Python linting (flake8) integrated
  - [ ] shellcheck for shell scripts
  - [ ] Unit tests in CI pipeline

---

#### 8. Permission Audit & Scoped Storage Migration
- **Status:** Manifest has MANAGE_EXTERNAL_STORAGE with tools:ignore
- **Files:**
  - `app/src/main/AndroidManifest.xml`
  - Code using file I/O (scoped storage fallback needed)
- **Actions:**
  - Document why MANAGE_EXTERNAL_STORAGE is required
  - Implement scoped storage fallback for API 30+
  - Test on Android 11+ device
- **Expected Outcome:** Justified permissions + runtime fallback for scoped storage
- **Vault Link:** `/reference/vault/android-permissions-audit.md`

---

### 🟢 MEDIUM PRIORITY (Complete Before Release)

#### 9. Reference Vault Finalization
- **Status:** Structure exists, needs consolidation
- **Files:**
  - `/reference/vault/` (all .md files)
  - `docs/` (supporting documentation)
- **Actions:**
  ```bash
  # Consolidate all standards into vault
  ls -la /reference/vault/
  # Ensure each vault file cites external standards
  ```
- **Expected Outcome:** Single canonical vault with mappings to all code + external docs
- **Vault Link:** `/reference/vault/vault-index.md`

---

#### 10. Test Coverage & Instrumentation
- **Status:** Minimal test structure
- **Files:**
  - `app/src/test/` (unit tests)
  - `app/src/androidTest/` (instrumentation tests)
- **Actions:**
  ```bash
  ./gradlew test
  ./gradlew connectedAndroidTest  # Requires emulator/device
  ```
- **Expected Outcome:** Core business logic tested, CI runs tests
- **Checklist:**
  - [ ] Unit tests for Android activities
  - [ ] Instrumentation tests for WebIDE integration
  - [ ] Code coverage > 50% for critical paths

---

## 🗂️ File Mapping

| File | Responsible For | Status | Priority |
|------|---|---|---|
| `Dockerfile` | Docker base + tooling | ✅ 95% | High |
| `docker-compose.yml` | Multi-service orchestration | ⚠️ Needs verification | Critical |
| `app/build.gradle.kts` | Android build config | ⚠️ Needs minSdk/ABI audit | Critical |
| `app/src/main/AndroidManifest.xml` | Permissions & features | ✅ OK | High |
| `ai/` | HF integration + secrets | ⚠️ Secrets handling | Critical |
| `.github/workflows/` | CI/CD automation | ✅ 80% | High |
| `/reference/vault/` | Standards & audit trail | ⚠️ Needs consolidation | Medium |

---

## ✅ Verification Checklist

### Local Verification (Before PR)
- [ ] `docker buildx build --platform linux/arm64 -t test:arm64 .` succeeds
- [ ] `docker-compose up` starts all services
- [ ] `./gradlew assembleDebug` builds APK
- [ ] `npm run lint` passes
- [ ] `./gradlew lint` passes
- [ ] No hardcoded secrets in code/history
- [ ] No large model weights in repo
- [ ] `file app/build/outputs/apk/debug/*.apk` shows arm64 architecture

### CI Verification (In Workflow)
- [ ] CodeQL scan runs and clean
- [ ] All linters pass
- [ ] APK builds and signs (with mock secrets for CI)
- [ ] Artifacts uploaded with checksums

### Final Sign-off
- [ ] All 10 action items completed
- [ ] Reference vault consolidated
- [ ] README updated with build instructions
- [ ] Completion checklist attached to issue #50

---

## 📚 Reference Standards

| Topic | Vault Document | External Standard |
|---|---|---|
| Docker | `/reference/vault/docker-standards.md` | [Ubuntu 24.04 Docs](https://ubuntu.com) |
| Android | `/reference/vault/android-build-standards.md` | [Android Developers](https://developer.android.com) |
| Secrets | `/reference/vault/secrets-handling.md` | [OWASP Mobile Top 10](https://owasp.org) |
| CodeQL | `/reference/vault/codeql-remediation.md` | [GitHub CodeQL Docs](https://docs.github.com/code-security) |

---

## 🎯 Definition of Done (100% Completion)

✅ All items above completed and verified  
✅ Reference vault consolidated and auditable  
✅ CI/CD fully automated with no manual steps  
✅ No hardcoded secrets or uncommitted binary weights  
✅ ARM64 Docker and APK reproducible  
✅ Security scans clean (CodeQL, SAST)  
✅ Linters and tests passing  
✅ Documentation complete and cross-referenced  

---

**Last Updated:** 2026-01-26 13:48:05  
**Next Review:** After completion of each action item