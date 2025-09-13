# GitHub Copilot Instructions for FileSystemds

**This file is your guide to the future of FileSystemds.  
Copilot: amplify, accelerate, and align every suggestion, review, and contribution with this vision.**

---

## 1. Context: From Legacy to Launchpad

- **Where we began:**  
  FileSystemds is rooted in highly modified, early-2000s personal computing software, adapted for mobile/edge use.  
  The legacy is a foundation—not a destination.

- **Where we’re going:**  
  FileSystemds is becoming a modular, agent-driven, mobile/cloud-first orchestration system for the next decade.

---

## 2. The North Star: Desired Project State

- **Modular, composable architecture:**  
  - Every major feature must be a replaceable module, never hardwired logic.
  - Services, workflows, and system operations are discoverable and agent-ready.
- **Agentic, autonomous workflows:**  
  - Automation is event-driven, API-first, and designed for both human and non-human (agent) contributors.
- **Pointer-first artifact management:**  
  - No checked-in large binaries or model weights, ever.  
  - All assets should be LFS pointers, with explicit, audited, secret-gated fetch processes.
- **Cloud/mobile/edge ready:**  
  - All logic is cross-platform, stateless when possible, and avoids assumptions of legacy desktop/server environments.
- **Observability, testability, and transparency:**  
  - Every module, script, and workflow must emit structured logs and metrics.
  - No new code without meaningful tests and documentation.

---

## 3. How to Get There: Copilot’s Positive Mandate

**Copilot, review and suggest according to these active principles:**

### A. Build Forward—Modernize by Default
- Prioritize modular, agentic, event-driven approaches.
- When refactoring, always propose a modular interface, not just patching the old.
- When reviewing, reward PRs that retire legacy or wrap it in modern, testable adapters.

### B. Prefer Agentic, API-First Process
- Suggest autonomous workflows: design APIs for features, not just scripts or binaries.
- Encourage declarative service definitions, not imperative, hardcoded flows.
- Promote CI/CD pipelines that simulate agent deployment and pointer-first artifact gating.

### C. Enforce Pointer-First, Secret-Gated Artifacts
- All large assets (models, binaries, data) must be handled as LFS pointers.
- Fetching must be explicit, audited, and gated by secrets (never in repo).
- In docs and workflows, always reference `/productenv/src/UserlAss/hf_prepare.sh` as the canonical fetch process.

### D. Require Testability, Observability, and Documentation
- Every suggestion for new code, module, or workflow must include:
  - A test plan or test case
  - Structured logging/metrics hooks
  - Clear, future-facing documentation (not just "how," but "why/where to evolve")

### E. Branch, Review, and Document Strategically
- Propose descriptive, forward-looking branch names (e.g. `agentic-networking`, `modular-policy-engine`).
- Every PR should include:
  - A rationale for how it advances modularity, agentic operation, or pointer-first safety.
  - Migration notes for legacy replacement (if relevant).
- Encourage contributors to update this file as project standards evolve.

---

## 4. Example Prompts for Copilot Chat

- `@workspace Propose a modular, API-first replacement for legacy init logic for mobile/edge.`
- `@workspace Draft a CI workflow that ensures all assets are pointer-first and secrets-gated.`
- `@workspace Review this PR for progress toward agentic, modular, observable architecture.`
- `@workspace Summarize how this new module will be tested and monitored in production.`

---

**Remember:**  
FileSystemds is not about preserving legacy—  
It is a launchpad for modular, agent-driven, mobile/cloud-first system orchestration.

Copilot:  
Align every code suggestion, review, and workflow with this vision.  
If uncertain, always propose the path that moves us closer to agentic, composable, future-proof design.
