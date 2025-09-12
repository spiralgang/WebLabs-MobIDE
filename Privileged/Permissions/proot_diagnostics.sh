#!/usr/bin/env bash
# proot_diagnostics.sh - safe diagnostics for PRoot / host root layout
set -euo pipefail
echo "===== process root info ====="
echo "proc$$ root -> $(readlink -f /proc/$$/root 2>/dev/null || echo '(rdlink failed)')"
echo "proc1 root -> $(readlink -f /proc/1/root 2>/dev/null || echo '(rdlink failed)')"
echo
echo "===== mount points (filtered) ====="
mount | egrep -i 'sdcard|emulated|storage|media|fuse|host-rootfs|data|proot' || mount | sed -n '1,120p'
echo
echo "===== host-rootfs and /data presence ====="
ls -ld /host-rootfs /host-rootfs/data /data 2>/dev/null || true
echo
echo "===== /data summary (permissions/SELinux if available) ====="
ls -ldZ /data 2>/dev/null || ls -ld /data 2>/dev/null || true
ls -ldZ /data/data 2>/dev/null || ls -ld /data/data 2>/dev/null || true
ls -ldZ /data/user/0 2>/dev/null || ls -ld /data/user/0 2>/dev/null || true
echo
echo "===== tech.ula candidate paths (shallow listing) ====="
for p in "/data/data/tech.ula" "/data/user/0/tech.ula" "/host-rootfs/data/data/tech.ula" "/host-rootfs/data/user/0/tech.ula"; do
  echo "---- $p ----"
  ls -al --color=never "$p" 2>/dev/null | sed -n '1,120p' || echo "(missing or permission denied)"
done
echo
echo "===== small-file read test (first readable small file under /data/data/tech.ula) ====="
sample=$(find /data/data/tech.ula /data/user/0/tech.ula 2>/dev/null -type f -size -64k -print 2>/dev/null | head -n1 || true)
echo "SAMPLE_FILE=${sample:-<none>}"
[ -n "$sample" ] && (echo "---- head ----"; head -c 256 "$sample" | sed -n '1,20p') || true
echo
echo "===== userland shell info ====="
ps -o pid,uid,gid,cmd -p $$ 2>/dev/null || true
cat /proc/$$/cmdline 2>/dev/null | tr '\0' ' ' || true
echo
echo "===== done ====="