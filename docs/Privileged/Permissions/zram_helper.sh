#!/usr/bin/env bash
# scripts/zram_helper.sh
#
# One-shot helper: detect ZRAM capability and either:
#  - If running as root on a kernel with zram support: install & enable zram-tools (configurable),
#    create /etc/default/zramswap tuned for mobile (Galaxy S9+ defaults), start service and show a monitoring dashboard.
#  - If NOT root or zram module unavailable: scaffold a userland "NIMM-MIND" Zarr+Blosc helper (Python) and optionally create a venv.
#
# Safety:
#  - Does not upload secrets.
#  - Will NOT remove existing swap devices automatically.
#  - Package installs use apt-get (Debian/Ubuntu). Script will bail if apt not present.
#
# Usage:
#   sudo ./scripts/zram_helper.sh                # interactive, root path
#   ./scripts/zram_helper.sh --percent 40 --algo lz4 --create-python
#   ./scripts/zram_helper.sh --help
set -euo pipefail

PROG=$(basename "$0")
DEFAULT_PERCENT=40
DEFAULT_ALGO="lz4"
DEFAULT_DEVICES=1

PERCENTAGE="$DEFAULT_PERCENT"
ALGO="$DEFAULT_ALGO"
DEVICES="$DEFAULT_DEVICES"
FORCE=0
CREATE_PY=0

show_help(){
  cat <<EOF
$PROG — zram helper (root or userland fallback)

Options:
  --percent N       Percent of total RAM to allocate to zram (default: $DEFAULT_PERCENT)
  --algo NAME       Compression algorithm: lz4 (default) or zstd
  --devices N       Number of /dev/zram devices to create (default: $DEFAULT_DEVICES)
  --create-python   Always scaffold the userland Zarr/Blosc helper (no root needed)
  --force           Force actions (non-interactive where possible)
  -h, --help        Show this help
Examples:
  sudo $PROG                          # run as root, interactive prompts
  sudo $PROG --percent 35 --algo zstd --devices 1
  $PROG --create-python               # userland path: scaffold python helper
EOF
  exit 0
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --percent) PERCENTAGE="$2"; shift 2;;
    --algo) ALGO="$2"; shift 2;;
    --devices) DEVICES="$2"; shift 2;;
    --create-python) CREATE_PY=1; shift;;
    --force) FORCE=1; shift;;
    -h|--help) show_help;;
    *) echo "Unknown arg: $1"; show_help;;
  esac
done

# helpers
is_root() { [ "$(id -u)" -eq 0 ]; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }
info(){ printf "\e[1;34m[INFO]\e[0m %s\n" "$*"; }
warn(){ printf "\e[1;33m[WARN]\e[0m %s\n" "$*"; }
err(){ printf "\e[1;31m[ERROR]\e[0m %s\n" "$*"; }

# validate percentage & algo
if ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]] || [ "$PERCENTAGE" -lt 5 ] || [ "$PERCENTAGE" -gt 90 ]; then
  err "PERCENTAGE must be an integer between 5 and 90."
  exit 2
fi
if [[ "$ALGO" != "lz4" && "$ALGO" != "zstd" ]]; then
  err "ALGO must be 'lz4' or 'zstd'"
  exit 2
fi

# detect zram device/kernel
ZRAM_PRESENT=0
if ls /dev/zram* >/dev/null 2>&1; then
  ZRAM_PRESENT=1
fi

# If root -> try to modprobe if not present
if is_root; then
  if [ "$ZRAM_PRESENT" -eq 0 ]; then
    if has_cmd modprobe; then
      info "Attempting to load zram module (modprobe zram)..."
      set +e
      modprobe zram 2>/dev/null
      MRET=$?
      set -e
      if [ $MRET -eq 0 ] && ls /dev/zram* >/dev/null 2>&1; then
        ZRAM_PRESENT=1
      else
        warn "modprobe zram failed or /dev/zram* not created. Kernel may lack zram module."
      fi
    else
      warn "modprobe not available in PATH."
    fi
  fi
fi

# Root path: configure zram-tools and zramswap
if is_root && [ $ZRAM_PRESENT -eq 1 ]; then
  info "Root detected + zram support found. Preparing zram-tools / zramswap configuration."

  # ensure apt available
  if ! has_cmd apt-get; then
    warn "apt-get not found. This script supports Debian/Ubuntu via apt-get for package installs. Exiting root flow."
  else
    # interactive confirmation unless forced
    if [ "$FORCE" -ne 1 ]; then
      echo "About to install/configure zram-tools and enable zramswap with:"
      echo "  PERCENTAGE=${PERCENTAGE}%  ALGO=${ALGO}  DEVICES=${DEVICES}"
      read -rp "Proceed? [y/N] " ans
      case "$ans" in [Yy]*) ;; *) info "Aborted by user."; exit 0;; esac
    fi

    info "Installing zram-tools (if missing)..."
    apt-get update -qq
    apt-get install -y -qq zram-tools || { warn "zram-tools install failed; continuing (maybe already installed)"; }

    # write /etc/default/zramswap (idempotent backup)
    CONF="/etc/default/zramswap"
    BACKUP="${CONF}.bak.$(date +%s)"
    if [ -f "$CONF" ]; then
      info "Backing up existing $CONF -> $BACKUP"
      cp -a "$CONF" "$BACKUP"
    fi

    cat > "$CONF" <<EOF
# /etc/default/zramswap — managed by scripts/zram_helper.sh
PERCENTAGE=${PERCENTAGE}
ALGO=${ALGO}
DEVICES=${DEVICES}
EXTRA_OPTS=""
EOF

    info "Wrote $CONF. Enabling and starting zramswap service (systemd)."
    if has_cmd systemctl; then
      systemctl daemon-reload || true
      systemctl enable --now zramswap || warn "Failed to enable/start zramswap service via systemctl; try 'systemctl status zramswap' manually."
      sleep 1
      info "zramswap service status:"
      systemctl status zramswap --no-pager || true
    else
      warn "systemctl not available. Please enable/start zramswap manually."
    fi

    # show zramctl & free info
    if has_cmd zramctl; then
      info "zramctl output:"
      zramctl || true
    else
      warn "zramctl not present; try 'apt install util-linux' or use 'cat /sys/block/zram0/disksize' to inspect devices."
    fi

    info "Memory summary (free -h):"
    free -h || true

    cat <<EOF

Summary:
- zram configured with PERCENTAGE=${PERCENTAGE}%, ALGO=${ALGO}, DEVICES=${DEVICES}
- If you want different tuning, edit $CONF and run: systemctl restart zramswap
- Monitor with: sudo zramctl && watch -n1 free -h

Notes:
- lz4 is recommended on mobile (low CPU latency). zstd increases compression ratio but costs more CPU.
- If your workload is CPU-bound, reduce PERCENTAGE or use lz4.

EOF
  fi

  # Also scaffold python helper if requested
  if [ "$CREATE_PY" -eq 1 ]; then
    PY_HELPER_DIR="${HOME}/icedman/examples"
    mkdir -p "$PY_HELPER_DIR"
    PY_FILE="${PY_HELPER_DIR}/nimm_mind_zarr_helper.py"
    if [ ! -f "$PY_FILE" ]; then
      cat > "$PY_FILE" <<'PY'
#!/usr/bin/env python3
# examples/nimm_mind_zarr_helper.py
# Minimal "NIMM-MIND" helper: demonstrates Zarr+Blosc compressed chunk store for large arrays.
# Run: python3 nimm_mind_zarr_helper.py

import os, tempfile, shutil
import numpy as np
import zarr
from numcodecs import Blosc

compressor = Blosc(cname='lz4', clevel=1, shuffle=Blosc.BITSHUFFLE)
tmpdir = os.path.expanduser(os.getenv("ICEDMAN_ZARR_DIR", "~/icedman/nimm_zarr"))
os.makedirs(tmpdir, exist_ok=True)
store_path = os.path.join(tmpdir, "dataset.zarr")

shape = (1024*10, 1024)  # tune as you need
chunks = (64, 1024)

print("Creating zarr store at", store_path)
z = zarr.open(store_path, mode='w', shape=shape, chunks=chunks, dtype='float32', compressor=compressor)
# populate a tiny subset to avoid huge disk writes on first-run
for i in range(0, min(256, shape[0]), chunks[0]):
    block = np.random.rand(chunks[0], chunks[1]).astype('float32')
    z[i:i+chunks[0], :] = block

print("Wrote a few chunks. Example read of first chunk:")
a = z[0:1,:]
print("chunk shape:", a.shape, "sum:", float(a.sum()))
print("Store size (bytes):", sum(os.path.getsize(os.path.join(dp,f)) for dp,_,fn in os.walk(store_path) for f in fn))
print("Done.")
PY
      chmod +x "$PY_FILE"
      info "Scaffolded Python helper: $PY_FILE"
    else
      info "Python helper already exists: $PY_FILE"
    fi
  fi

  exit 0
fi

# Non-root / fallback path
info "Non-root path or zram not available. Scaffolding userland compressed-store helper (Zarr + Blosc)."

if [ "$CREATE_PY" -eq 1 ] || ! has_cmd python3; then
  info "Creating Python helper scaffolding under ~/icedman/examples (no root required)."
fi

PY_HELPER_DIR="${HOME}/icedman/examples"
mkdir -p "$PY_HELPER_DIR"
PY_FILE="${PY_HELPER_DIR}/nimm_mind_zarr_helper.py"

cat > "$PY_FILE" <<'PY'
#!/usr/bin/env python3
# examples/nimm_mind_zarr_helper.py
# NIMM-MIND style userland helper (Zarr + Blosc)
# Requirements: python3 + pip install zarr numcodecs blosc numpy
# This script creates a compressed chunked array store and demonstrates writes/reads.

import os, sys
try:
    import numpy as np
    import zarr
    from numcodecs import Blosc
except Exception as e:
    print("Missing Python deps:", e)
    print("Install with: pip install zarr numcodecs blosc numpy")
    sys.exit(2)

compressor = Blosc(cname='lz4', clevel=1, shuffle=Blosc.BITSHUFFLE)
tmpdir = os.path.expanduser(os.getenv("ICEDMAN_ZARR_DIR", "~/icedman/nimm_zarr"))
os.makedirs(tmpdir, exist_ok=True)
store_path = os.path.join(tmpdir, "dataset.zarr")

shape = (1024*10, 1024)
chunks = (64, 1024)

print("Creating zarr store at", store_path)
z = zarr.open(store_path, mode='w', shape=shape, chunks=chunks, dtype='float32', compressor=compressor)
for i in range(0, min(256, shape[0]), chunks[0]):
    block = np.random.rand(chunks[0], chunks[1]).astype('float32')
    z[i:i+chunks[0], :] = block

print("Read single chunk (decompressed into RAM):")
a = z[0:1, :]
print("shape:", a.shape, "sum:", float(a.sum()))
print("Example store path:", store_path)
PY

chmod +x "$PY_FILE"
info "Python helper created at: $PY_FILE"

# Offer to create a venv and install deps if python3 and pip are available
if has_cmd python3 && has_cmd pip3; then
  VENV_DIR="${HOME}/icedman/venv"
  if [ ! -d "$VENV_DIR" ]; then
    if [ "$FORCE" -ne 1 ]; then
      read -rp "Create virtualenv at $VENV_DIR and install deps (zarr,numcodecs,blosc,numpy)? [y/N] " a
      case "$a" in [Yy]*) DO_VENV=1 ;; *) DO_VENV=0 ;; esac
    else
      DO_VENV=1
    fi
    if [ "$DO_VENV" -eq 1 ]; then
      info "Creating venv and installing Python deps (may take time)..."
      python3 -m venv "$VENV_DIR"
      # shellcheck disable=SC1090
      source "$VENV_DIR/bin/activate"
      pip install --upgrade pip
      pip install zarr numcodecs blosc numpy
      deactivate
      info "Venv ready. To run helper:"
      echo "  source $VENV_DIR/bin/activate && python $PY_FILE"
    else
      info "Skipped venv creation. Install deps manually if desired."
    fi
  else
    info "Venv already present at $VENV_DIR. To use: source $VENV_DIR/bin/activate && python $PY_FILE"
  fi
else
  warn "python3 or pip3 not found in PATH. Install them or run the helper on a machine with Python."
fi

cat <<EOF

Summary:
- zram not configured (or not running as root). Use the python helper as a userland alternative that provides chunked, compressed arrays (NIMM-MIND style).
- Helper path: $PY_FILE
- Recommended quick test:
   1) (Optional) create venv: source ~/icedman/venv/bin/activate
   2) python $PY_FILE

If you later get root/kernel access and want the kernel-zram path, re-run this script with sudo.

EOF

exit 0