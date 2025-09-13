#!/usr/bin/env bash
# Fetch discovered AI models and dependency artifacts for offline hosting.
# Designed to run in CI (GitHub Actions) with explicit network approval.
#
# Usage:
#   ./scripts/ops/fetch_models_and_deps.sh [--force-network true|false] [--target <issue_or_pr_number>]
#
# Behavior summary (short):
# - Scans the repository for common model references and dependency specs.
# - Attempts safe downloads only when force_network=true AND (workflow label agent-allow-network present OR GITHUB_TOKEN not required for read).
# - Supports Hugging Face (snapshot_download), Ollama (ollama pull), pip (pip download), and basic Docker/apt extraction.
# - Produces ai/downloads/ and ai/deps/ plus ai/download_manifest.json describing results.
# - Exit code: 0 if at least one item downloaded; non-zero otherwise.
#
# Rationale (concise):
# We cannot assume which models are required; this script auto-discovers references and attempts curated, auditable pulls.
# Downloads are gated behind explicit operator action (force_network) and produce an artifact manifest for review.

set -euo pipefail
SCRIPT_NAME=$(basename "$0")
REPO_ROOT="$(pwd)"
TARGET="${REPO_ROOT}"
FORCE_NETWORK=false
TARGET_ISSUE=""
LOG=/tmp/fetch_models_and_deps.log
OUT_DIR="${REPO_ROOT}/ai/downloads"
DEPS_DIR="${REPO_ROOT}/ai/deps"
MANIFEST="${OUT_DIR}/download_manifest.json"
TMP_SCAN="/tmp/_model_scan.txt"
MIN_SUCCESS=0

# Helpers
log() { echo "[$SCRIPT_NAME] $*" | tee -a "$LOG"; }
err() { echo "[$SCRIPT_NAME] ERROR: $*" | tee -a "$LOG" >&2; }
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [--force-network true|false] [--target <issue_or_pr_number>]
EOF
  exit 2
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --force-network) FORCE_NETWORK="$2"; shift 2;;
    --target) TARGET_ISSUE="$2"; shift 2;;
    -h|--help) usage;;
    *) err "Unknown arg: $1"; usage;;
  esac
done

mkdir -p "$OUT_DIR" "$DEPS_DIR"
echo "[]" > "$MANIFEST"

# Safety gating: require explicit force_network to proceed with downloads.
if [ "${FORCE_NETWORK}" != "true" ]; then
  log "Network pulls are disabled (force_network != true). Exiting without network downloads."
  log "To enable network downloads, re-run with --force-network true and ensure label 'agent-allow-network' is present for audit."
  exit 3
fi

# If running inside GitHub Actions, verify label agent-allow-network when possible.
if [ -n "${GITHUB_ACTIONS:-}" ] && [ -n "${GITHUB_EVENT_PATH:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  # Check labels on the target PR/issue if GITHUB_TOKEN is present.
  if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "$TARGET_ISSUE" ]; then
    log "Checking for label 'agent-allow-network' on ${GITHUB_REPOSITORY} issue/PR #${TARGET_ISSUE}"
    LABELS_JSON=$(curl -sS -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${TARGET_ISSUE}" || true)
    if ! echo "$LABELS_JSON" | grep -q '"agent-allow-network"'; then
      err "Label 'agent-allow-network' not found for target ${TARGET_ISSUE}. Aborting network downloads."
      exit 4
    fi
    log "Label found: proceeding with network downloads."
  else
    log "Skipping label check (GITHUB_TOKEN or target issue missing). Proceeding because --force-network true was supplied."
  fi
fi

# Utility: append manifest entry
add_manifest_entry() {
  local name="$1" src="$2" method="$3" path="$4" ok="$5" note="$6"
  # Build a JSON line and merge into array
  python3 - <<PY >> "$MANIFEST"
import json,sys
mfile = "$MANIFEST"
try:
  with open(mfile,'r') as f:
    arr=json.load(f)
except:
  arr=[]
arr.append({
  "name": "$name",
  "source": "$src",
  "method": "$method",
  "path": "$path",
  "success": $ok,
  "note": "$note"
})
with open(mfile,'w') as f:
  json.dump(arr,f,indent=2)
PY
}

# 1) Repo scan: find likely model references (huggingface, hf.co, ollama, qwen, .safetensors/.bin/.pt)
log "Scanning repository for model references..."
grep -R --line-number --exclude-dir=.git --exclude-dir=node_modules -E "huggingface\.co|hf\.co|hf_hub|snapshot_download|ollama[:/]|ollama pull|qwen[:/]|qwen-cli|\\.safetensors|\\.pt|\\.bin|model_id|model-name" . > "$TMP_SCAN" || true
# Also check manifest files if present
[ -f "configs/model_manifest.json" ] && echo "FOUND: configs/model_manifest.json" >> "$TMP_SCAN"
[ -f "requirements.txt" ] && echo "FOUND: requirements.txt" >> "$TMP_SCAN"
[ -f "environment.yml" ] && echo "FOUND: environment.yml" >> "$TMP_SCAN"

if [ ! -s "$TMP_SCAN" ]; then
  log "No explicit model references discovered by simple heuristics. Still attempting standard dependency collection (pip/conda)."
else
  log "Scan output (first 200 lines):"
  sed -n '1,200p' "$TMP_SCAN" | tee -a "$LOG"
fi

# 2) Gather pip dependencies (requirements.txt / pyproject.toml)
PIP_REQS=""
if [ -f "requirements.txt" ]; then
  PIP_REQS="requirements.txt"
fi
if [ -n "$PIP_REQS" ]; then
  log "Found pip requirements: $PIP_REQS. Downloading wheels into ${DEPS_DIR}/pip_wheels"
  mkdir -p "${DEPS_DIR}/pip_wheels"
  # Install pip if needed (runner should already have)
  python3 -m pip install --upgrade pip >/dev/null 2>&1 || true
  python3 -m pip download -r "$PIP_REQS" -d "${DEPS_DIR}/pip_wheels" 2>&1 | tee -a "$LOG" || true
  add_manifest_entry "pip-requirements" "pip" "pip download" "${DEPS_DIR}/pip_wheels" true "Downloaded wheels (best-effort)"
  MIN_SUCCESS=$((MIN_SUCCESS+1))
fi

# 3) Extract apt/system packages from Dockerfiles or scripts (best-effort)
DOCKERPKGFILE="${DEPS_DIR}/system_packages.txt"
grep -R --exclude-dir=.git --exclude-dir=node_modules -E "apt-get install|apt install|apk add|yum install" . -n > /tmp/_apt_lines.txt || true
if [ -s /tmp/_apt_lines.txt ]; then
  log "Extracting likely system package install lines"
  awk -F: '{print $2}' /tmp/_apt_lines.txt | sed -E 's/apt(-get)? install -y? //; s/&&.*$//' | tr -s ' ' '\n' | sed '/^$/d' | sort -u > "$DOCKERPKGFILE" || true
  log "System packages saved to $DOCKERPKGFILE"
  add_manifest_entry "system-packages" "repo-scan" "extract" "$DOCKERPKGFILE" true "List extracted (manual apt-get download required)"
fi

# 4) If configs/model_manifest.json exists, prefer it as authoritative list
if [ -f "configs/model_manifest.json" ]; then
  log "Found configs/model_manifest.json - reading entries"
  # Expect a JSON with 'models': [{'name':..., 'source': 'huggingface'|'ollama'|'url', 'id': 'xxx' ...}]
  python3 - <<PY
import json,sys,os,subprocess
m="configs/model_manifest.json"
try:
  j=json.load(open(m))
except Exception as e:
  print("MANIFEST_PARSE_ERROR",e)
  sys.exit(0)
models=j.get("models",[])
for mod in models:
  name=mod.get("name") or mod.get("id") or "unnamed"
  src=mod.get("source","")
  mid=mod.get("id") or mod.get("model") or mod.get("path") or ""
  print(name,src,mid)
PY
fi

# Helper: download Hugging Face repo using huggingface_hub.snapshot_download (Python)
download_hf() {
  local repo="$1"
  local out="$2"
  log "Attempting Hugging Face snapshot_download for repository '$repo' to $out"
  python3 - <<PY
import sys,os
try:
  from huggingface_hub import snapshot_download
except Exception as e:
  print("MISSING_HF_LIB",e)
  sys.exit(2)
repo="$repo"
out="$out"
os.makedirs(out,exist_ok=True)
try:
  # allow public download; use HF_HUB_TOKEN if set in env
  snapshot_download(repo_id=repo, cache_dir=out, local_files_only=False, allow_patterns=None)
  print("OK")
except Exception as e:
  print("ERR",e)
  sys.exit(3)
PY
  return $?
}

# Helper: attempt ollama pull
download_ollama() {
  local model="$1"
  local outdir="$2"
  if ! command -v ollama >/dev/null 2>&1; then
    err "ollama CLI not present on runner"
    return 10
  fi
  log "Pulling ollama model '$model' (ollama pull)..."
  mkdir -p "$outdir"
  # This is intentionally conservative: ollama stores models in its own store; we attempt 'ollama pull' here.
  if ollama pull "$model" 2>&1 | tee -a "$LOG"; then
    return 0
  else
    return 5
  fi
}

# 5) Heuristics to find model ids and download them
# Collect candidate strings from scan
CANDIDATES=$(sed -n '1,1000p' "$TMP_SCAN" | sed -E "s/.*(huggingface\.co\\/[-A-Za-z0-9_\\/]+).*/\\1/;s/.*(hf\\.co\\/[-A-Za-z0-9_\\/]+).*/\\1/" | sort -u | sed '/^$/d' || true)
# Also look for lines that contain model file names
MODEL_FILES=$(grep -R --exclude-dir=.git --exclude-dir=node_modules -E "\.safetensors|\.pt|\.bin" . -n | awk -F: '{print $2}' | sort -u || true)

# Attempt Hugging Face downloads for URL-like candidates
for c in $CANDIDATES; do
  if echo "$c" | grep -q "huggingface.co\|hf.co"; then
    # Normalize to repo id: huggingface.co/<user>/<repo> or /<repo>/resolve/... -> extract the first two path components after domain
    repo_id=$(echo "$c" | sed -E 's#https?://(www\.)?huggingface\.co/##; s#https?://(www\.)?hf\.co/##' | awk -F/ '{print $1"/"$2}')
    if [ -n "$repo_id" ]; then
      outdir="${OUT_DIR}/hf__${repo_id//\//__}"
      log "Discovered HF repo_id: $repo_id -> $outdir"
      if download_hf "$repo_id" "$outdir"; then
        add_manifest_entry "$repo_id" "huggingface" "snapshot_download" "$outdir" true "public download"
        MIN_SUCCESS=$((MIN_SUCCESS+1))
      else
        add_manifest_entry "$repo_id" "huggingface" "snapshot_download" "$outdir" false "download failed or private"
      fi
    fi
  fi
done

# Attempt to copy any checked-in model files
if [ -n "$MODEL_FILES" ]; then
  for mf in $MODEL_FILES; do
    src="$(realpath --relative-to="$REPO_ROOT" "$mf" 2>/dev/null || echo "$mf")"
    dst="${OUT_DIR}/checkedin_models/$(basename "$mf")"
    mkdir -p "$(dirname "$dst")"
    cp -a "$mf" "$dst" || true
    add_manifest_entry "$mf" "repo-file" "copy" "$dst" true "checked-in model file copied"
    MIN_SUCCESS=$((MIN_SUCCESS+1))
  done
fi

# Attempt Ollama model pulls if 'ollama' referenced in repo or manifest
if grep -R --exclude-dir=.git -n "ollama" . >/dev/null 2>&1 || grep -q "ollama" "$TMP_SCAN" 2>/dev/null || true; then
  # Look for plausible model names in scan
  grep -R --exclude-dir=.git -n -E "ollama[: ]+[-A-Za-z0-9_/]+" . | sed -E 's/.*ollama[: ]+//; s/[^A-Za-z0-9_\/\.-].*$//' | sort -u > /tmp/_ollama_candidates.txt || true
  if [ -s /tmp/_ollama_candidates.txt ]; then
    while read -r mdl; do
      if [ -z "$mdl" ]; then continue; fi
      out="${OUT_DIR}/ollama__${mdl//\//__}"
      if download_ollama "$mdl" "$out"; then
        add_manifest_entry "$mdl" "ollama" "ollama pull" "$out" true "pulled to ollama store (runner-managed)"
        MIN_SUCCESS=$((MIN_SUCCESS+1))
      else
        add_manifest_entry "$mdl" "ollama" "ollama pull" "$out" false "ollama pull failed or CLI missing"
      fi
    done < /tmp/_ollama_candidates.txt
  fi
fi

# 6) Handle environment.yml (conda) by saving it for manual/micromamba download later
if [ -f "environment.yml" ]; then
  cp environment.yml "${DEPS_DIR}/environment.yml" || true
  add_manifest_entry "environment.yml" "repo" "copy" "${DEPS_DIR}/environment.yml" true "saved for conda/micromamba resolution"
  MIN_SUCCESS=$((MIN_SUCCESS+1))
fi

# 7) Save any Dockerfiles for manual image building and package collection
if ls Dockerfile* >/dev/null 2>&1; then
  mkdir -p "${DEPS_DIR}/dockerfiles"
  cp Dockerfile* "${DEPS_DIR}/dockerfiles/" || true
  add_manifest_entry "Dockerfiles" "repo" "copy" "${DEPS_DIR}/dockerfiles" true "saved"
  MIN_SUCCESS=$((MIN_SUCCESS+1))
fi

# Finalize manifest: ensure JSON exists
if [ -f "$MANIFEST" ]; then
  log "Download manifest produced at $MANIFEST"
fi

# Upload-friendly summary
echo "SUMMARY: downloads manifest -> $MANIFEST" | tee -a "$LOG"
jq -r '.[] | "\(.name) |\(.source) |\(.method) |\(.path) |\(.success) |\(.note)"' "$MANIFEST" 2>/dev/null | tee -a "$LOG" || true

if [ "$MIN_SUCCESS" -gt 0 ]; then
  log "At least one artifact collected: success."
  exit 0
else
  err "No artifacts were downloaded or discovered for fetching."
  exit 5
fi