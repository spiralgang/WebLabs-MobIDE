# Self-Hosted GitHub Actions Runner Setup (Linux ARM64)

This guide provides step-by-step, production-grade instructions for deploying a self-hosted GitHub Actions runner on an ARM64 Linux machine. All configuration steps are traceable and reference best practices from the canonical [GitHub Actions Runner Docs](/reference/vault).

---

## 1. Create Runner Directory

```bash
mkdir actions-runner && cd actions-runner
```
*Rationale: Isolates runner files, simplifies upgrades/audits, aligns with [file system hygiene](/reference/vault).*

---

## 2. Download Latest Runner Package

```bash
curl -o actions-runner-linux-arm64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-arm64-2.328.0.tar.gz
```
*Rationale: Always use the official GitHub release URL for authenticity. See [GitHub Releases](/reference/vault).*

---

## 3. (Optional) Validate Package Integrity

```bash
echo "b801b9809c4d9301932bccadf57ca13533073b2aa9fa9b8e625a8db905b5d8eb actions-runner-linux-arm64-2.328.0.tar.gz" | shasum -a 256 -c
```
*Rationale: Verifies download integrity, ensuring supply-chain security. See [hash validation practices](/reference/vault).*

---

## 4. Extract Installer

```bash
tar xzf ./actions-runner-linux-arm64-2.328.0.tar.gz
```
*Rationale: Standard extraction command for tar.gz archives. Follows [Linux archive handling](/reference/vault).*

---

## 5. Configure Runner

```bash
./config.sh --url https://github.com/spiralgang/DevUl-Army--__--Living-Sriracha-AGI --token BOBRGNXMDZYALIFQV3FU6DDIYACGY
```
*Rationale: Binds runner to specific repo using a one-time registration token. Token should be rotated for security. See [GitHub Actions Registration](/reference/vault).*

---

## 6. Start Runner

```bash
./run.sh
```
*Rationale: Enters the runner daemon mode, ready to accept workflow jobs.*

---

## 7. Reference in Workflow YAML

In your `.github/workflows/*.yaml` files, set runner targeting:

```yaml
runs-on: self-hosted
```
*Rationale: Ensures jobs are scheduled on your self-hosted runner. See [workflow syntax](/reference/vault).*

---

## 8. Status Badges (Optional)

Embed workflow status badges in your README for visibility:

```markdown
[![Continuous Integration - Main/Release](https://github.com/spiralgang/DevUl-Army--__--Living-Sriracha-AGI/actions/workflows/load-generator.yaml/badge.svg)](https://github.com/spiralgang/DevUl-Army--__--Living-Sriracha-AGI/actions/workflows/load-generator.yaml)
[![Continuous Integration - Main/Release](https://github.com/spiralgang/DevUl-Army--__--Living-Sriracha-AGI/actions/workflows/load-generator.yaml/badge.svg?event=deployment_status)](https://github.com/spiralgang/DevUl-Army--__--Living-Sriracha-AGI/actions/workflows/load-generator.yaml)
```
*Rationale: Surfacing CI status increases transparency and reliability monitoring.*

---

## References

- [GitHub Actions Runner Documentation](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [Canonical Vault: Self-Hosted Runners](/reference/vault)
- [Linux Security Best Practices](/reference/vault)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)