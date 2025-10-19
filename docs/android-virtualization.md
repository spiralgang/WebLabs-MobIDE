# Android Virtualization Strategy for WebLabs-MobIDE

## Why Docker Was Replaced

Running the legacy Docker-based toolchain required kernel features (namespaces,
cgroups) that are not exposed on stock Android devices. Attempts to bundle a
rootless Docker binary failed because it still relies on privileged daemons.
Instead we evaluated userland container options that can operate entirely in
unprivileged mode.

### Survey of Options

| Solution | Summary | Outcome |
| --- | --- | --- |
| **proot-distro (Termux)** | Ships with Termux, provides lightweight userland virtualization with bind mounts and UID emulation. Supports custom aliases. | ✅ Selected. Stable, scriptable, ARM64 ready. |
| **UserLAnd** | Graphical app that wraps proot sessions. Requires manual UI interaction, limited automation. | ❌ Rejected. Hard to automate and integrate with WebLabs UI. |
| **Anlinux / Andronix** | Script collections that bootstrap various distros over proot. Require manual onboarding and paid upgrades for automation hooks. | ❌ Rejected. Vendor lock-in and brittle scripts. |
| **chroot via Magisk** | Full Linux chroot if device is rooted. | ⚠️ Optional. Not viable for stock devices so not a baseline dependency. |

proot-distro with Termux offered the best mix of availability (from F-Droid or
GitHub), automation hooks (CLI friendly), and compatibility with modern Ubuntu
root filesystems.

## Chosen Architecture

1. **Host Environment:** Termux app installed on Android, with the `proot` and
   `proot-distro` packages. `wget`, `curl`, and `tsu` are not required.
2. **Distro Alias:** The app provisions a dedicated alias `weblabs-mobide` that
   wraps the stock `ubuntu` rootfs shipped by proot-distro. A fallback to any
   existing Ubuntu alias keeps power users unblocked.
3. **Provisioning Script:** On first launch the app logs into the alias and
   installs Code-Server, OpenJDK 17, Node.js, Python 3, and build-essential. It
   also drops `/usr/local/bin/weblabs-start.sh`, a helper that can start, stop,
   and report status for Code-Server.
4. **Workspace Bind:** `proot-distro login --shared-tmp --termux-home` allows
   the Android app sandbox (`context.filesDir/workspace`) to appear inside the
   distro as `/root/workspace`.
5. **Process Lifecycle:** Code-Server is spawned in the background by
   `weblabs-start.sh`, which records its PID and writes logs to
   `/var/log/weblabs-code-server.log`. This gives us deterministic start/stop
   semantics without needing systemd.

## Installation Checklist

Run the following commands inside Termux before launching WebLabs-MobIDE:

```bash
pkg update
pkg install proot-distro
proot-distro install --override-alias weblabs-mobide ubuntu
```

Optional: export a higher inotify limit and open firewall rules if you use
Android 14+ and external browsers:

```bash
echo "fs.inotify.max_user_watches=1048576" >> ~/.termux/termux.properties
termux-reload-settings
```

## Runtime Telemetry

`DockerManager` (now a virtualization orchestrator) exposes a `SharedFlow` of
`VirtualizationEvent` values. `MainActivity` subscribes to this flow:

- **Info** events are logged for diagnostics.
- **Warning** events surface as short Toasts (e.g., falling back to the local
  IDE).
- **Error** events render longer Toasts so the user understands when proot-distro
  is missing or misconfigured.

The telemetry mechanism ensures that missing Termux packages or failed
provisioning steps do not silently fail: the UI immediately reflects the issue
and falls back to the offline web IDE when necessary.

## Operational Commands

The legacy `docker://` WebView scheme is still supported, but it now proxies to
proot-distro operations:

- `docker://status` → `weblabs-start.sh status`
- `docker://start` → full provisioning + `weblabs-start.sh start`
- `docker://stop` → `weblabs-start.sh stop`

Each command executes via `proot-distro login`, so they inherit the same
workspace bindings and environment variables configured during provisioning.

## Future Enhancements

- Cache toolchain packages to avoid re-running `apt-get` when the distro is
  already configured.
- Replace Toast-based telemetry with a richer UI status panel.
- Investigate bundling bootstrap archives to remove the external `install`
  command dependency entirely.

