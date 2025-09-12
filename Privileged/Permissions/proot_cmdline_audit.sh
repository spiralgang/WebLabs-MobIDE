#!/usr/bin/env bash
# Extract live proot commandlines and -b bind graphs for authoritative state.
# Android/PRoot friendly: reads /proc for running sessions.
set -euo pipefail

echo "[i] Scanning proot processes..."
# shellcheck disable=SC2009
PIDS=$(ps -eo pid,cmd | awk '/[p]root .* -r /{print $1}')
if [[ -z "${PIDS}" ]]; then
  echo "[!] No proot processes found."
  exit 0
fi

for PID in ${PIDS}; do
  echo "---- PRoot PID ${PID} ----"
  if [[ -r "/proc/${PID}/cmdline" ]]; then
    tr '\0' '\n' < "/proc/${PID}/cmdline" | nl -ba
    echo "---- Binds (-b) ----"
    tr '\0' '\n' < "/proc/${PID}/cmdline" | awk 'p{print "  " $0; p=0} $0=="-b"{p=1}'
  else
    echo "Cannot read /proc/${PID}/cmdline"
  fi
done