#!/usr/bin/env bash
# proot_inspector.sh
# Lightweight watcher to monitor a target UI process (or proot) for:
#  - root (readlink /proc/$PID/root)
#  - mountinfo changes (bind mounts involving /host-rootfs, /sdcard, /storage, /data)
#  - exe (real binary)
#  - SELinux attr (attr/current) when available
#  - namespace links (/proc/$PID/ns/*)
#  - visible /dev/input devices and X input events (if requested and available)
#
# Purpose: pin the exact moment a process switches storage root, namespaces, or loses access to input.
# Author: GitHub Copilot (assistant to spiralgang)
# License: MIT (use as you like)
set -euo pipefail

PROG="$(basename "$0")"
VERSION="2025-09-01"

usage() {
  cat <<EOF
$PROG $VERSION
Usage:
  $PROG [-p PID | -n NAME] [-i INTERVAL] [-o OUTFILE] [--watch-input] [--tail]

Options:
  -p PID         : PID to watch (mutually exclusive with -n)
  -n NAME        : process name to watch (first matched PID)
  -i INTERVAL    : polling interval seconds (default: 1)
  -o OUTFILE     : log file path (default: /tmp/proot_inspector.log)
  --watch-input  : attempt to list /dev/input and run 'xinput test' if DISPLAY available
  --watch-inotify: try inotifywait on target's root and mount change (if inotifywait exists)
  --tail         : print appended log lines to stdout in real time (like tail -F)
  -h, --help     : show this help
EOF
  exit 1
}

# Defaults
INTERVAL=1
OUTFILE="/tmp/proot_inspector.log"
WATCH_INPUT=false
WATCH_INOTIFY=false
TAIL=false

# Parse args
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p) PID="$2"; shift 2;;
    -n) NAME="$2"; shift 2;;
    -i) INTERVAL="$2"; shift 2;;
    -o) OUTFILE="$2"; shift 2;;
    --watch-input) WATCH_INPUT=true; shift;;
    --watch-inotify) WATCH_INOTIFY=true; shift;;
    --tail) TAIL=true; shift;;
    -h|--help) usage;;
    *) POSITIONAL+=("$1"); shift;;
  esac
done
set -- "${POSITIONAL[@]}"

if [[ -z "${PID:-}" && -z "${NAME:-}" ]]; then
  echo "ERROR: specify -p PID or -n NAME" >&2
  usage
fi

if [[ -n "${NAME:-}" && -z "${PID:-}" ]]; then
  # find first matching PID
  # prefer full-match of comm, fallback to pgrep
  PID="$(pgrep -n -f "$NAME" 2>/dev/null || true)"
  if [[ -z "$PID" ]]; then
    PID="$(ps -eo pid,comm | awk -v nm="$NAME" '$2==nm {print $1; exit}')"
  fi
  if [[ -z "$PID" ]]; then
    echo "ERROR: could not find process named '$NAME'." >&2
    exit 2
  fi
fi

if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
  echo "ERROR: PID appears invalid: '$PID'" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUTFILE")"
: > "$OUTFILE"

log() {
  printf '%s %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" | tee -a "$OUTFILE"
}

# helpers
safe_readlink() {
  readlink -f "$1" 2>/dev/null || echo "N/A"
}
safe_cat() {
  if [[ -r "$1" ]]; then
    cat "$1" 2>/dev/null || echo "N/A"
  else
    echo "N/A"
  fi
}

# initial capture
prev_root=""
prev_mountsig=""
prev_exe=""
prev_attr=""
prev_ns=""
prev_dev_list=""
prev_xinput_list=""

gather_mount_signature() {
  # capture only mount lines that mention host-rootfs, sdcard, storage, data or bind points to /
  if [[ -r "/proc/$PID/mountinfo" ]]; then
    grep -E '/host-rootfs|/sdcard|/storage|/data| bind| / ' "/proc/$PID/mountinfo" 2>/dev/null | md5sum | awk '{print $1}'
  else
    echo "absent"
  fi
}

gather_mount_excerpt() {
  if [[ -r "/proc/$PID/mountinfo" ]]; then
    grep -E '/host-rootfs|/sdcard|/storage|/data| bind| / ' "/proc/$PID/mountinfo" 2>/dev/null || true
  fi
}

gather_ns() {
  if [[ -d "/proc/$PID/ns" ]]; then
    ls -l /proc/$PID/ns 2>/dev/null | awk '{print $1,$3,$4,$9,$10}' | sed 's/ /_/g' | tr '\n' '|' || echo "N/A"
  else
    echo "N/A"
  fi
}

gather_dev_inputs() {
  if [[ -d /dev/input ]]; then
    ls -la /dev/input 2>/dev/null | sed -n '1,200p' || echo "N/A"
  else
    echo "no-dev-input"
  fi
}

gather_xinput_list() {
  # try to query X if DISPLAY is set in user's environment (we avoid overwriting DISPLAY)
  # run as the current shell; if not accessible, return N/A
  if command -v xdpyinfo >/dev/null 2>&1 && env | grep -q '^DISPLAY='; then
    # capture list for display in env
    xinput --list 2>/dev/null || echo "xinput-unavailable"
  else
    echo "no-display-or-xinput"
  fi
}

show_proot_cmdline() {
  # find proot processes and display their cmdlines (useful to inspect -b binds)
  ps -eo pid,cmd | grep -E '(^|/)proot\b' | grep -v grep || true
}

# optional inotify waiter runner
maybe_inotifywatch() {
  if ! $WATCH_INOTIFY; then return; fi
  if ! command -v inotifywait >/dev/null 2>&1; then
    log "inotifywait not found; --watch-inotify disabled"
    return
  fi
  # run in background: watch /proc/$PID/root (if readable) and /proc/$PID/mountinfo
  (
    while true; do
      # inotifywait will fail on proc pseudo-files on some kernels; guard
      if [[ -d "/proc/$PID" ]]; then
        inotifywait -e attrib,modify,close_write -t 0 "/proc/$PID/mountinfo" >/dev/null 2>&1 \
          && log "inotify: /proc/$PID/mountinfo changed (inotifywait)"
      fi
      sleep 1
      # bail if PID gone
      if ! kill -0 "$PID" 2>/dev/null; then
        exit 0
      fi
    done
  ) &
  INOTIFY_PID=$!
  log "inotify watcher started (pid: $INOTIFY_PID)"
}

# optional watch-xinput-test (runs xinput test in background if available and DISPLAY present).
maybe_watch_input_events() {
  if ! $WATCH_INPUT; then return; fi
  if ! command -v xinput >/dev/null 2>&1; then
    log "xinput not present; --watch-input disabled"
    return
  fi
  # attempt to detect a touch device and run xinput test in background (non-blocking)
  XID="$(xinput --list 2>/dev/null | grep -i touch || true)"
  if [[ -z "$XID" ]]; then
    log "no 'touch' device reported by xinput --list (or DISPLAY not accessible)"
    return
  fi
  # pick the first id
  ID="$(xinput --list 2>/dev/null | awk -F'id=' '/touch/ {print $2; exit}' | awk '{print $1}')"
  if [[ -z "$ID" ]]; then
    log "failed to parse xinput device id"
    return
  fi
  # run xinput test in background and tee to a separate file
  XOUTFILE="${OUTFILE}.xinput.$ID.log"
  ( xinput test "$ID" 2>&1 | sed "s/^/XINPUT[$ID] $(date +%s): /" >> "$XOUTFILE" ) &
  XINPUT_PID=$!
  log "xinput test started (device id=$ID, pid=$XINPUT_PID, out=$XOUTFILE)"
}

# initial dump
log "=== proot_inspector START pid=$PID interval=$INTERVAL outfile=$OUTFILE ==="
log "Inspecting: /proc/$PID (user=$(ps -o user= -p $PID 2>/dev/null) cmd=$(ps -o cmd= -p $PID 2>/dev/null))"
show_proot_cmdline | sed 's/^/PROOT: /' | tee -a "$OUTFILE"

prev_root="$(safe_readlink /proc/$PID/root)"
prev_exe="$(safe_readlink /proc/$PID/exe)"
prev_attr="$(safe_cat /proc/$PID/attr/current 2>/dev/null || echo "N/A")"
prev_ns="$(gather_ns)"
prev_mountsig="$(gather_mount_signature)"
prev_dev_list="$(gather_dev_inputs)"
prev_xinput_list="$(gather_xinput_list || echo "N/A")"

log "Initial root: $prev_root"
log "Initial exe: $prev_exe"
log "Initial selinux/attr: ${prev_attr:-N/A}"
log "Initial ns: $prev_ns"
log "Initial mount signature: $prev_mountsig"
log "Initial /dev/input listing (excerpt):"
echo "$prev_dev_list" | sed -n '1,40p' >> "$OUTFILE"
log "Initial xinput list (if available):"
echo "$prev_xinput_list" | sed -n '1,40p' >> "$OUTFILE"

maybe_inotifywatch
maybe_watch_input_events

# main loop: poll and report only on changes (also every N iterations output a heartbeat)
ITER=0
while true; do
  if ! kill -0 "$PID" 2>/dev/null; then
    log "PID $PID no longer exists. Exiting."
    break
  fi

  CUR_ROOT="$(safe_readlink /proc/$PID/root)"
  CUR_EXE="$(safe_readlink /proc/$PID/exe)"
  CUR_ATTR="$(safe_cat /proc/$PID/attr/current 2>/dev/null || echo "N/A")"
  CUR_NS="$(gather_ns)"
  CUR_MOUNTSIG="$(gather_mount_signature)"
  CUR_DEVLIST="$(gather_dev_inputs)"
  CUR_XINPUT="$(gather_xinput_list || echo "N/A")"

  changed=false

  if [[ "$CUR_ROOT" != "$prev_root" ]]; then
    log "root CHANGED: -> $CUR_ROOT"
    prev_root="$CUR_ROOT"
    changed=true
  fi

  if [[ "$CUR_EXE" != "$prev_exe" ]]; then
    log "exe CHANGED: -> $CUR_EXE"
    prev_exe="$CUR_EXE"
    changed=true
  fi

  if [[ "$CUR_ATTR" != "$prev_attr" ]]; then
    log "SELinux attr CHANGED: -> $CUR_ATTR"
    prev_attr="$CUR_ATTR"
    changed=true
  fi

  if [[ "$CUR_NS" != "$prev_ns" ]]; then
    log "namespaces CHANGED: -> $CUR_NS"
    log "namespaces (detailed):"
    ls -l /proc/$PID/ns 2>/dev/null | tee -a "$OUTFILE"
    prev_ns="$CUR_NS"
    changed=true
  fi

  if [[ "$CUR_MOUNTSIG" != "$prev_mountsig" ]]; then
    log "mount table signature CHANGED"
    log "mount excerpt:"
    gather_mount_excerpt | tee -a "$OUTFILE"
    prev_mountsig="$CUR_MOUNTSIG"
    changed=true
  fi

  # /dev/input changes - log short diffs
  if [[ "$CUR_DEVLIST" != "$prev_dev_list" ]]; then
    log "/dev/input listing CHANGED (excerpt):"
    printf '%s\n' "$CUR_DEVLIST" | sed -n '1,40p' >> "$OUTFILE"
    prev_dev_list="$CUR_DEVLIST"
    changed=true
  fi

  if [[ "$CUR_XINPUT" != "$prev_xinput_list" ]]; then
    log "xinput list changed (if available):"
    printf '%s\n' "$CUR_XINPUT" | sed -n '1,40p' >> "$OUTFILE"
    prev_xinput_list="$CUR_XINPUT"
    changed=true
  fi

  # heartbeat every 30 iterations or if changed
  ITER=$((ITER+1))
  if $changed || (( ITER % 30 == 0 )); then
    log "heartbeat: pid=$PID iter=$ITER"
    # also dump proot cmdlines each heartbeat (useful to see -b binds)
    show_proot_cmdline | sed 's/^/PROOT: /' | tee -a "$OUTFILE"
  fi

  # optionally print tail to stdout
  if $TAIL; then
    tail -n 200 "$OUTFILE"
  fi

  sleep "$INTERVAL"
done

# cleanup background watchers
if [[ -n "${XINPUT_PID:-}" ]]; then
  kill "$XINPUT_PID" 2>/dev/null || true
  log "killed xinput watcher pid $XINPUT_PID"
fi
if [[ -n "${INOTIFY_PID:-}" ]]; then
  kill "$INOTIFY_PID" 2>/dev/null || true
  log "killed inotify watcher pid $INOTIFY_PID"
fi

log "=== proot_inspector STOP ==="