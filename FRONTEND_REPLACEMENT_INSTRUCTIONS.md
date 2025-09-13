```markdown
# Front-end replacement: use rootfs-manifest.yml as single source of truth

Goal:
Replace the current static front-end distribution list with a manifest-driven UI that reads /manifests/rootfs.json (server provides YAML->JSON).

Minimal UI contract (array of objects):
[
  {
    "id": "archlinux-arm",
    "name": "Arch Linux ARM (aarch64)",
    "preferred_arch": "aarch64",
    "urls": {
      "aarch64": "http://.../ArchLinuxARM-aarch64-latest.tar.gz"
    },
    "accept": [".tar.gz"],
    "note": "short guidance"
  },
  ...
]

Implementation notes:
- On app start (or when user opens Filesystems/Apps page), call GET /manifests/rootfs.json.
- Parse into a list and render each item with:
  - display name (name)
  - architecture badge (preferred_arch)
  - short note (note) as tooltip/subtext
  - download button that uses urls[detected_arch] first, or opens a small picker if multiple archs exist.
- Fallback: if urls[detected_arch] missing, present the list of available arch URLs for user selection.
- If URL uses templating ({{version}}/{{timestamp}}), provide a small "Browse mirror" action which opens the provided discover_hint URL in external browser so user can copy exact filename.
- Download strategy: prefer external browser or native download manager when the in-app downloader reports "resolve" or "illegal state" errors. After browser download completes to /sdcard/Download, call FileSystem Import flow.

Edge cases:
- .tar.xz: if UI detects .tar.xz and UserLAnd import requires .tar.gz, show a small helper modal explaining repack requirement and link to a "repack" script or instructions.
- Bouncer URLs: when a manifest entry points at a directory/bouncer, prefer open-in-browser because bouncer performs mirror selection and sometimes returns redirects UI downloader mishandles.

Security:
- Only display manifest entries from your trusted server.
- Validate hostnames against allowlist if you are distributing this for many devices.

Deployment:
- Add rootfs-manifest.yml + userland-server-config.yml to spiralgang/UserlAsServer staging branch.
- Configure CI (you have runner hours) to validate YAML and publish rootfs.json via a small server container that exposes /manifests/rootfs.json.
```