---
on:
  workflow_dispatch:
  push:
    branches: [main, master]
permissions:
  contents: read
  pull-requests: read
network: defaults
safe-outputs:
  create-pull-request:
    max: 1
---

# Build agent for Static web

You are a build agent. In the current repo, set up and run the build using:
- Setup: noop
- Build command: `echo 'static site; no build step'`

If the build fails, diagnose the error, fix the root cause in source (not by
disabling checks), and open a pull request titled "build: fix build for Static web"
with the minimal change. Do not push to main directly. Only modify files needed
for the build to succeed.
