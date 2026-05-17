---
name: architecture-scan
description: Run a lightweight architecture health check — file sizes, module boundaries, tech debt markers, and domain glossary staleness. Use as a pre-push hook, CI check, or on-demand scan to detect architecture drift before it accumulates.
---

# Architecture Scan

The outer ring of the spiral model. A lightweight, automated check that detects architecture drift early — before it requires a full `improve-codebase-architecture` intervention.

This skill runs `scripts/architecture-scan.sh` and interprets its output. The scan is designed to be:
- **Fast** — completes in under a second on most repos
- **No AI needed** — pure shell checks, usable in CI or git hooks
- **Composable** — feeds into `improve-codebase-architecture` for deeper analysis when issues are found

## Setup: Install as a pre-push hook (one-time)

Run these commands from the project root to install the scan as a pre-push hook:

```bash
scripts/architecture-scan.sh install-hook
```

Or manually:

```bash
cat > .git/hooks/pre-push << 'HOOK'
#!/usr/bin/env bash
scripts/architecture-scan.sh
HOOK
chmod +x .git/hooks/pre-push
```

The hook runs on every push and warns if architecture drift is detected. It does NOT block the push — it outputs warnings so you can decide whether to address them before opening a PR.

## On-demand usage

Run the scan at any time:

```bash
scripts/architecture-scan.sh              # compare against origin/main
scripts/architecture-scan.sh origin/dev   # compare against a different base
scripts/architecture-scan.sh origin/main ./backend  # scan a subdirectory
```

## What the scan checks

| Check | What it detects | Threshold |
|-------|----------------|-----------|
| **File size** | Overgrown files that should be split | >500 lines |
| **Tech debt markers** | TODOs/FIXMEs/HACKs without ticket references, counted per branch diff | Any new untracked markers |
| **Module boundaries** | New source files placed outside known module directories | Per diff |
| **Domain glossary staleness** | New camelCase terms introduced without updating CONTEXT.md | Per diff |
| **Change breadth** | Branch touching too many modules — possible missing abstraction | >4 modules = warning, >8 = flag |

## Interpretation

| Exit code | Result | Action |
|-----------|--------|--------|
| 0 | PASS | No action needed |
| 1 | WARNING | Review flagged items before merge. If patterns repeat across branches, schedule an `improve-codebase-architecture` session |
| 2 | FAIL | Run `/improve-codebase-architecture` before merging to address the issues |

## When to run

- **Before every merge** (via pre-push hook) — catch drift as it happens
- **On every Nth commit** (via Claude Code `resubmit` hook or `/loop`) — stay aware of accumulating patterns
- **After a large feature branch** — verify the architecture is still coherent

## Relationship to other skills

```
zoom-out (explain current state)
    │
    ▼
architecture-scan (automated health check, fast, no AI)
    │
    ├── PASS → continue
    │
    └── FAIL → improve-codebase-architecture (deep analysis with AI)
```

The three skills form a progression: `zoom-out` gives you a map, `architecture-scan` checks for drift automatically, and `improve-codebase-architecture` fixes the issues when drift is found.
