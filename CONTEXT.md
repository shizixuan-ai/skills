# Matt Pocock Skills

A collection of agent skills (slash commands and behaviors) loaded by Claude Code. Skills are organized into buckets and consumed by per-repo configuration emitted by `/setup-matt-pocock-skills`.

## Language

**Issue tracker**:
The tool that hosts a repo's issues — GitHub Issues, Linear, a local `.scratch/` markdown convention, or similar. Skills like `to-issues`, `to-prd`, `triage`, and `qa` read from and write to it.
_Avoid_: backlog manager, backlog backend, issue host

**Issue**:
A single tracked unit of work inside an **Issue tracker** — a bug, task, PRD, or slice produced by `to-issues`.
_Avoid_: ticket (use only when quoting external systems that call them tickets)

**Triage role**:
A canonical state-machine label applied to an **Issue** during triage (e.g. `needs-triage`, `ready-for-afk`). Each role maps to a real label string in the **Issue tracker** via `docs/agents/triage-labels.md`.

**Bucket**:
A storage category for skills under `skills/`. Six buckets exist: `engineering/` (daily code work), `productivity/` (non-code workflow tools), `misc/` (kept but rarely used), `personal/` (user-specific, not promoted), `in-progress/` (drafts), and `deprecated/` (no longer used). Bucket membership controls whether a skill appears in the top-level `README.md` and `.claude-plugin/plugin.json`.
_Avoid_: folder, directory (use only when describing filesystem mechanics)

**Phase**:
The current stage in the three-ring spiral model, stored in `.claude/phase` and managed by `scripts/phase.sh`. Valid transitions: `aligned → researched → planned → validated → implementing`. Each phase has a `next` command hint for what to run next. Skills like `research-first`, `to-prd`, and `prototype` write to the phase file after completing their step.

**Spiral model**:
A three-ring architectural workflow. The **outer ring** runs automated architecture scans (`architecture-scan.sh`). The **middle ring** validates module interfaces via design-validation prototypes. The **inner ring** implements features via TDD. Phase transitions track progress through the rings.

**Grilling session**:
An interaction pattern used by `/grill-me` and `/grill-with-docs` where the AI interviews the user through a decision tree until all branches are resolved and requirements are fully aligned.

**Buy vs Build**:
A decision framework used by `/research-first`. "Buy" means an existing solution covers ≥80% of requirements with a compatible license. "Build" means no suitable candidate exists — degrade to prototype then TDD.

**Deep module**:
A module that encapsulates significant behaviour behind a small, stable interface. Deep modules are testable in isolation and rarely change. The opposite is a shallow module (interface nearly as complex as the implementation). Used by `/improve-codebase-architecture`, `/tdd`, and `/to-prd`.

**Vertical slice**:
A self-contained feature implementation that cuts through all layers (interface, business logic, persistence) in one pass. Used by `/tdd` (tracer-bullet approach) and `/to-issues` (issue decomposition). Contrasts with horizontal slicing (writing all tests first, then all code).

## Relationships

- An **Issue tracker** holds many **Issues**
- An **Issue** carries one **Triage role** at a time
- A **Bucket** contains many skills
- A **Phase** transitions forward through the **Spiral model**
- A **Grilling session** resolves ambiguity before Buy vs Build or implementation decisions
- A **Deep module** is discovered or created through deepening opportunities

## Flagged ambiguities

- "backlog" was previously used to mean both the *tool* hosting issues and the *body of work* inside it — resolved: the tool is the **Issue tracker**; "backlog" is no longer used as a domain term.
- "backlog backend" / "backlog manager" — resolved: collapsed into **Issue tracker**.
