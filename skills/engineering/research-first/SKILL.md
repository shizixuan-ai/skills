---
name: research-first
description: Force a "buy vs build" evaluation before writing any code. Search GitHub and package ecosystems for existing solutions, produce a structured research report, and either recommend a dependency or degrade gracefully into prototype/tdd. Use when requirements are clear but you need to decide whether to build or buy.
---

# Research First

You are a cost-conscious architect. Before writing any code, your first instinct is "what already exists?" — not "how do I build this?"

This skill sits between **requirement alignment** (grill-me / grill-with-docs) and **implementation** (tdd / prototype). It is a soft dependency: it works standalone but benefits from the project's domain glossary in `CONTEXT.md` for sharper vocabulary.

## Process

### 1. Extract search terms

From the user's requirement, extract 2-3 technical keyword sets. Each set targets a different angle:

- **Problem keywords**: what the library does (e.g. "resume parsing", "job queue", "PDF text extraction")
- **Stack keywords**: the project's tech stack (e.g. "Go", "Python", "React", "Rust")
- **Domain keywords**: from the project's CONTEXT.md if available, to stay consistent with existing vocabulary

Write down the keyword sets before searching.

### 2. Search ecosystem

Search in this order. Stop early only if you find an obvious perfect match:

1. **GitHub** — search by keyword, filter by language, sort by stars. Look at the top 3-5 candidates.
2. **Package registry** — npm, PyPI, Go pkg, crates.io, etc. depending on the project's stack. Check download counts and recent releases.
3. **Web search** — for commercial/SaaS alternatives that may not appear in open-source search.

For each candidate found, record:
- Name, URL, license
- Latest release date and maintenance cadence
- Star count / download count (community signal)
- Description and claimed features

### 3. Evaluate candidates

Score each candidate against these dimensions. Use a simple 3-point scale (✅ full match / ⚠️ partial / ❌ no match or unknown):

| Dimension | What to check |
|-----------|--------------|
| **Requirement fit** | What % of the user's stated requirements does it cover? |
| **Activity** | Recent commits? Issues resolved? CI passing? |
| **Integration cost** | How hard to add to the project? Transitive deps? Bundle size? |
| **License** | MIT/Apache → safe. GPL/AGPL → flag for review. No license → reject. |
| **API quality** | Docs quality? Stable API or still changing? Type-safe (TS/Go)? |

At least 2 candidates must be compared. If only one exists, justify why it is or isn't appropriate.

### 4. Make a decision

Choose one of three outcomes:

```
Search → Evaluate
    │
    ├── Buy ─────────► Recommend best candidate + integration notes
    │
    ├── Hybrid ──────► Recommend partial buy + document what must be built
    │
    └── Build ──────► No suitable candidate found → degrade to prototype or tdd
                              │
                              ▼
                      Document "why not buy" in report
```

**Buy**: The candidate covers ≥80% of requirements, is well-maintained, and has a compatible license. Write integration notes and proceed to tdd for the glue code.

**Hybrid**: A candidate covers the core but leaves gaps. Recommend it for the parts it handles, and document what still needs to be built. Proceed to tdd for the custom portion.

**Build**: No candidate clears the bar. In this case:
1. Explicitly document why each candidate failed in the report
2. Transition into prototype (LOGIC branch) to validate the custom approach
3. After prototype validates the design, transition into tdd for production code

### 5. Write research report

Save the complete report to `docs/research/<topic>-research.md` using [REPORT_TEMPLATE.md](REPORT_TEMPLATE.md).

The report is the durable artifact. It serves as:
- A decision record for future reference
- Input for team review before committing to a dependency
- A "why not buy" trail when the answer is build

### 6. Hand over to next stage

End with a clear handoff signal:

- **Buy** → "Proceeding to tdd. Integration work: [brief summary of glue code needed]."
- **Hybrid** → "Proceeding to tdd. Custom portion: [what needs building]. Library handles: [what's covered]."
- **Build** → "No suitable library found. Degrading to prototype to validate custom approach, then tdd."
  Then immediately transition — do not wait for the user to re-prompt.

### 7. Update phase tracking

After completing the research, update the project's phase file so the next session (or next skill) knows where to pick up:

Regardless of outcome (Buy / Hybrid / Build), set phase to `researched` with next step `to-prd` to archive the research decision:
```bash
scripts/phase.sh set researched "/to-prd" "调研完成。下一步运行 /to-prd 将调研结论归档为 PRD"
```

Then print the phase status so the user sees the next step:

```bash
scripts/phase.sh status
```

## Anti-patterns

- **Over-searching**: Don't search for more than 15 minutes worth of queries. If nothing obvious appears in the first wave, move to build.
- **Over-scoping**: Don't try to find a library that covers 100% of requirements with zero customization. 80% fit with good API quality is a buy.
- **Introducing framework for trivial needs**: Don't recommend a heavy framework to replace 20 lines of code. Evaluate the weight-to-value ratio.
- **Ignoring transitive risk**: A library with 500+ transitive dependencies is a maintenance liability even if it scores perfectly on feature fit.
- **License neglect**: Always check license. Never recommend a no-license or GPL-licensed library without explicit user awareness.
