# GitHub Copilot Instructions for FileSystemds

This file is NOT just a summary of the current codebase. It is a strategic guide for Copilot and all contributors:  
**Understand the past, but focus on building the next generation.**

---

## 1. Context: Where We Come From

- **Legacy Base:**  
  FileSystemds is built on top of heavily modified early-2000s personal computing software and service management stacks, originally for desktops/laptops, now retrofitted for mobile/edge/cloud.
- **Reality Check:**  
  Most “upstream” components are 7–15 years old, often stagnant, with practices and APIs that predate modern mobile and cloud ops.
- **Why This Matters:**  
  The legacy is the starting point, **not the destination**.  
  Our job is to **modernize, modularize, and agentify**—not enshrine technical debt.

---

## 2. Vision: Where FileSystemds Is Going

**FileSystemds is transforming into:**

- A modular, agent-driven, service and system orchestrator for mobile, edge, and cloud platforms.
- No more monolithic, desktop-centric, unmaintainable code.  
- Everything must be:
  - **Composable** (replaceable modules, not hardwired logic)
  - **Automatable** (agentic workflows, not manual scripts)
  - **Cloud- and Mobile-ready** (stateless, cross-arch, cross-platform)
  - **Observable** (structured logs/metrics for every subsystem)
  - **Pointer-first** for all large assets/artifacts (no checked-in binaries, ever)

---

## 3. Production Process: How to Get There

### Coding & Architecture

- **Deprecate “magic” monolithic binaries and handwritten legacy init scripts.**
- **Every new subsystem must be modular and discoverable**—pluggable, agent-compatible, and with a clear contract.
- **Favor modern languages and tools** (C for core, Python/Shell for automation, Meson for build, YAML/JSON for configs).
- **Strict pointer-first artifact policy:**  
  - All large assets (models, binaries, datasets) are LFS pointers only—gated, auditable, and never stored in repo.
  - Use the canonical fetcher in `/productenv/src/UserlAss/hf_prepare.sh` or equivalent.
- **No new technical debt:**  
  - If you must interface with legacy, isolate it and wrap with modern, testable adapters.

### Pull Request & Review Standards

- **Every PR must move the project closer to the vision.**  
  - If it just patches legacy, it must also modernize or add agentic/testable interfaces.
- **All new code must be tested, documented, and observable.**
- **No direct shelling out to legacy commands unless fully sandboxed and logged.**
- **CI/CD must default to pointer-first, artifact-safe, and self-healing.**
- **Branch naming:**  
  - Use descriptive, forward-looking names (e.g. `agentic/mobile-daemon`, `modularize-userland`, `pointer-first-ci`).

---

## 4. What Copilot Should Do (and Enforce)

- **Prioritize modern, mobile/edge/cloud-first design** in all suggestions and reviews.
- **Challenge legacy patterns**—if you see a “just patch the old” PR, flag it unless it also advances modularity/agentic goals.
- **Enforce pointer-first, artifact-safe workflows** in code, CI, and docs.
- **Encourage explicit documentation of new interfaces and migration paths.**
- **When in doubt, ask for the rationale:**  
  - “Does this change move us closer to an agentic, modular, mobile/cloud-ready system?”

---

## 5. Example Prompts for Copilot Chat

- `@workspace What legacy modules are most in need of modular/agentic refactor for mobile/cloud?`
- `@workspace How can we migrate service X from a monolithic shell script to an autonomous, agent-driven workflow?`
- `@workspace Propose a pointer-first CI workflow that ensures all artifacts are gated and no model/data gets checked in.`

---

**Remember:**  
This is not “just another fork of systemd for ARM.”  
FileSystemds is a launchpad for the future of automated, modular, agent-driven system orchestration.  
Copilot’s job is to help us get there—every PR, every review, every suggestion.
