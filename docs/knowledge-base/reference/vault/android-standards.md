# Android Development Standards

## Project Structure
- **Namespace**: `com.spiralgang.weblabs`
- **Min SDK**: 29 (Android 10+)
- **Target SDK**: 34 (Android 14)
- **Architecture**: ARM64 (AArch64) exclusive

## Build System
- **Gradle**: 8.7 with Kotlin DSL
- **Android Gradle Plugin**: 8.4.1
- **Kotlin**: 1.9.22

## Security
- OWASP Mobile Security compliance
- Certificate pinning for production
- ProGuard/R8 optimization for release builds
- Secure storage for sensitive data

## References
- [Android Studio Project Structure](https://developer.android.com/studio/projects)
- [Android Manifest Permissions](https://developer.android.com/guide/topics/manifest/permission-element)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)