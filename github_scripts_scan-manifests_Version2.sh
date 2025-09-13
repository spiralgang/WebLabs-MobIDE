#!/usr/bin/env bash
# scan-manifests.sh
# Repo-wide manifest discovery + scan driver. Writes per-module outputs to ./scans.
set -euo pipefail
ROOT="$(pwd)"
OUTDIR="${ROOT}/scans"
mkdir -p "$OUTDIR"

sanitize() { echo "$1" | sed 's/^\.\///; s/[^A-Za-z0-9._-]/_/g'; }

# quick trivy/grype if available (fast broad scan)
if command -v trivy >/dev/null 2>&1; then
  trivy fs --format json -o "${OUTDIR}/trivy-root.json" . || echo '{"trivy":"error"}' > "${OUTDIR}/trivy-root.json"
else
  echo '{"trivy":"not-installed"}' > "${OUTDIR}/trivy-root.json"
fi

if command -v grype >/dev/null 2>&1; then
  grype dir:. -o json > "${OUTDIR}/grype-root.json" 2>/dev/null || echo '{"grype":"error"}' > "${OUTDIR}/grype-root.json"
else
  echo '{"grype":"not-installed"}' > "${OUTDIR}/grype-root.json"
fi

# Node per-package.json
git ls-files -- 'package.json' | while read -r pkg; do
  dir="$(dirname "$pkg")"
  safe="$(sanitize "$dir")"
  out="${OUTDIR}/npm-audit-${safe}.json"
  if [ -f "${dir}/package-lock.json" ]; then
    (cd "$dir" && npm ci --no-audit --no-fund >/dev/null 2>&1 || true; npm audit --json > "$out" 2>&1) || echo '{"npm_audit":"error"}' > "$out"
  else
    echo '{"npm_audit":"no-lockfile"}' > "$out"
  fi
done

# Python per-requirements/pyproject
git ls-files -- 'requirements.txt' 'pyproject.toml' 'Pipfile' | while read -r pyf; do
  dir="$(dirname "$pyf")"
  safe="$(sanitize "$dir")"
  out="${OUTDIR}/pip-audit-${safe}.json"
  (
    cd "$dir" || exit 0
    python3 -m venv .scan-venv >/dev/null 2>&1 || true
    source .scan-venv/bin/activate || true
    pip install --upgrade pip pip-audit >/dev/null 2>&1 || true
    if [ -f requirements.txt ]; then
      pip-audit -r requirements.txt -f json -o "$out" || echo '{"pip_audit":"error"}' > "$out"
    else
      pip-audit -f json -o "$out" || echo '{"pip_audit":"error"}' > "$out"
    fi
    deactivate || true
  ) || echo '{"pip_audit":"execution_failed"}' > "$out"
done

# Java/Gradle per build files - use owasp/dependency-check docker if docker exists
git ls-files -- 'pom.xml' 'build.gradle' 'build.gradle.kts' | while read -r jf; do
  dir="$(dirname "$jf")"
  safe="$(sanitize "$dir")"
  out="${OUTDIR}/dependency-check-${safe}.json"
  if command -v docker >/dev/null 2>&1; then
    docker run --rm -v "$ROOT":/src -v "$OUTDIR":/report owasp/dependency-check:latest \
      --project "repo-scan-${safe}" --scan "/src/${dir}" --format JSON --out /report 2>/dev/null || echo '{"dependency_check":"error"}' > "${out}"
    # dependency-check writes to /report/dependency-check-report.json
    if [ -f "${OUTDIR}/dependency-check-report.json" ]; then
      mv "${OUTDIR}/dependency-check-report.json" "${out}" || true
    fi
  else
    echo '{"dependency_check":"docker-not-present"}' > "${out}"
  fi
done

echo "Scans complete. Outputs: $(ls -1 ${OUTDIR} | wc -l) files"
exit 0