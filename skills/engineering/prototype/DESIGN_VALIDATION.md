# Design Validation Prototype

A lightweight, throwaway calling-code exercise that validates module interfaces before they are implemented. Use this when the question is about **API design, module boundaries, or data flow** — the kind of thing that looks right in a design doc but reveals awkwardness only when you try to use it.

## When this is the right shape

- A design doc, PRD, or interface spec has been drafted (e.g. by `to-prd` / `grill-with-docs` / `research-first`) and you need to validate it before committing to implementation.
- "I'm not sure if this API surface is ergonomic — let me write the calling code first and see how it feels."
- "Does this module boundary split the concerns cleanly, or is there a better seam?"
- "Before writing the full implementation, let me check that the data flow makes sense end-to-end."

If the question is about runtime behaviour or edge cases in a state machine — wrong branch. Use [LOGIC.md](LOGIC.md). If the question is about visual appearance — wrong branch. Use [UI.md](UI.md).

## Relationship to the three-ring model

This branch is the **validation step** in the middle ring of the spiral model. It sits between design and implementation:

```
Align → Research → Design → Validate → Build (TDD)
                               ↑
                     This branch ←──────── Return if awkward
```

The output of this branch is a **pass/fail signal**: either the design is validated (→ proceed to tdd), or it has issues (→ return to design with specific feedback).

## Process

### 1. State what is being validated

Write down the specific interfaces or modules under test. One paragraph, at the top of the prototype file:

> "Validating the `ResumeParser` interface from the PRD. Focus on: constructor params, the `Parse()` return shape, and error handling. Is the `Options` struct comprehensive without being noisy?"

Include the specific design decisions being validated — not the entire design, just the parts that would be expensive to change later.

### 2. Isolate the interface boundary

Define the interface(s) being validated in the project's language:

```
Go:   type definition or interface
TS:   type or interface declaration
Python:  Protocol or ABC
Rust:    trait
```

Write only the interface — no implementation. The prototype validates the *interface's* ergonomics, not whether the implementation works. Concretely:

- Skip method bodies (return zero values, `panic("TODO")`, `raise NotImplementedError`)
- Do implement any *caller-side* scaffolding needed to invoke the interface naturally
- Mock or stub any dependencies the interface requires

This keeps the prototype focused on the design question rather than implementation details.

### 3. Write calling code

Write the smallest amount of real-looking calling code that exercises the interface's core use cases. Pick **1-3 call sites** that represent:

- The **happy path** (the primary use case)
- One **edge case or error path**
- (Optional) One **composition scenario** — two interfaces working together

Example:

```go
func main() {
    // Happy path
    parser := resume.NewParser(resume.WithLanguage("zh-CN"))
    result, err := parser.Parse(inputFile)
    if err != nil { panic(err) }

    // Edge case
    _, err = parser.Parse(emptyFile)
    // What does Parse return for empty input? Zero value? Error?

    // Composition
    matcher := matching.NewMatcher(parser)
    score, err := matcher.Match(jobDesc, resumeFile)
}
```

The calling code is deliberately naive — no abstractions, no error handling beyond what makes the flow readable. This is not production code; it's exploring whether the API feels natural.

### 4. Assess the experience

After writing the calling code, evaluate against these signals:

| Good signal | Bad signal |
|-------------|------------|
| Calling code reads like prose | Calling code needs comments to explain what's happening |
| Method names match the domain language from CONTEXT.md | You reach for a method name and it doesn't exist |
| Parameters have sensible defaults | Every call requires 3+ configuration arguments |
| Error handling is natural and expected | Errors appear where you wouldn't expect them |
| Composition is straightforward | You need adapter/wrapper types to connect two interfaces |

### 5. Output the verdict

End with one of:

- **PASS** — "Interface validated. Proceeding to tdd." Include a brief note of what was confirmed.
- **PASS WITH NOTES** — "Interface is sound but these minor issues were found: [list]. Fix before tdd or defer — surface them in the design doc."
- **FAIL** — "This interface has design problems: [specific issues]. Return to design phase with this feedback."

For FAIL, include concrete alternatives — not just "this doesn't feel right" but "the `Parse` method should accept `io.Reader` instead of `string` because the caller always has a file handle, not a path."

## When done

- **PASS**: Delete the prototype calling code. The interface decisions it validated are the durable output.
- **PASS WITH NOTES**: Update the design doc / interface spec with the minor fixes, then delete the prototype.
- **FAIL**: Write the feedback into the design doc or create a quick update to the PRD. Delete the prototype — the calling code was throwaway, but the interface lessons are not.

In all cases, the prototype itself is throwable. Do not keep it around "just in case" — keep the lessons, not the code.

## Anti-patterns

- **Implementing the interface**: If you find yourself writing method bodies, you've left design validation and entered implementation. Stop, delete the bodies, and stay focused on the interface.
- **Validating too much at once**: One prototype validates one module boundary. If you're testing three interfaces and their interactions, split into separate prototypes.
- **Perfecting the calling code**: The calling code is scratch — typos, awkward variable names, temporary stubs are all fine. Polish hides the rough edges that the validation is meant to find.
- **Waiting until the interface is "done"**: Validate early, validate rough. Awkwardness found now costs minutes to fix; awkwardness found after implementation costs hours.
