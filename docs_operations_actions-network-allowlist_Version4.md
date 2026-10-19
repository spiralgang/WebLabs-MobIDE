## Android Build Process: Required Domains for Network Access

To successfully download all dependencies for Android builds, the following domains must be accessible:

- `dl.google.com` — Android SDK and build tools.
- `maven.google.com` — Official Maven repository for Android components.
- `repo1.maven.org` — Maven Central repository for Gradle dependencies.
- `services.gradle.org` — Gradle initialization and wrapper scripts.
- `storage.googleapis.com` — Android build tool mirrors.
- `github.com` and `objects.githubusercontent.com` — Repository source checkout, actions, and artifact releases.
- `actions.githubusercontent.com` — CI runner-based token exchange for action workflows.

### Verification Checklist

- Ensure these domains are reachable from self-hosted runners, or configure network/firewall settings to allow access.
- Monitor workflow logs for blocked domains and update the list as necessary.