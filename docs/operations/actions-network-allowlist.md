# GitHub Actions Network Allowlist

The production APK workflow depends on outbound access to Android build services. If your organization or repository limits GitHub Actions network egress, configure an allowlist that covers every endpoint required to build and notarize the WebLabs-MobIDE release artifact.

## Required domains

Add the following hostnames to the Actions network allowlist:

- `dl.google.com` – Android SDK command line tools and platform packages
- `maven.google.com` – Google Maven repository hosting AndroidX and Play Services artifacts
- `repo1.maven.org` – Maven Central repository hosting third-party dependencies
- `services.gradle.org` – Gradle distributions used only during CI builds
- `github.com` / `objects.githubusercontent.com` – Source fetches and release publishing
- `actions.githubusercontent.com` – Workflow token exchange for dependent actions
- `storage.googleapis.com` – Mirror hosting of Android build tools

> ℹ️ Granting access to these domains affects only GitHub-hosted runners. Self-hosted runners should rely on the local firewall instead of the Actions allowlist feature.

## Organization or repository settings

1. Navigate to **Settings ▸ Actions ▸ General** for your organization or repository.
2. Under **Workflow permissions**, select **Allow all actions and reusable workflows** so the release pipeline can call marketplace actions.
3. Scroll to **Workflow permissions ▸ Workflow runs** and enable **Allow GitHub Actions to create and approve pull requests** if your compliance policy permits artifact publishing.
4. Locate the **Actions network** section (currently in limited beta) and add the domains above to the **Allowed outbound hosts** list. When the feature is unavailable, coordinate with your network security team to ensure these hosts are reachable from GitHub-hosted runners.
5. Save the configuration.

## Automating allowlist updates

If you manage the allowlist via the GitHub API, the [`gh` CLI](https://cli.github.com/) can apply the policy consistently. Replace placeholders with your organization name:

```bash
ORG="your-org"
TOKEN="$(gh auth token)"
API="https://api.github.com/orgs/${ORG}/actions/permissions/workflow/allowances"

jq -n '{hostnames: [
  "dl.google.com",
  "maven.google.com",
  "repo1.maven.org",
  "services.gradle.org",
  "github.com",
  "objects.githubusercontent.com",
  "actions.githubusercontent.com",
  "storage.googleapis.com"
]}' \
| curl -sS -X PUT "$API" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -d @-
```

> ⚠️ The allowlist API is available only to GitHub Enterprise Cloud organizations enrolled in the Actions network controls beta. For other accounts, perform the configuration manually via the Settings UI.

## Verification checklist

- [ ] Trigger the **Build and Release Production APK** workflow from a `v*.*.*` tag.
- [ ] Confirm that dependency downloads succeed without manual retries.
- [ ] Verify that the workflow uploads `WebLabs-MobIDE-LinuxEnv.apk` to the corresponding GitHub Release.
- [ ] Revisit the allowlist whenever dependencies change or new release automation is introduced.
