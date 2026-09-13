# Agent Instructions

Before modifying this repository:

1. Read `.autodev/manifest.yaml`.
2. Read `.autodev/architecture.md`.
3. Read the relevant files under `.autodev/domain/` and `.autodev/features/`.
4. Read `.autodev/state/decisions.md`.
5. Inspect existing project conventions before introducing new patterns.
6. Produce an internal impact assessment covering business rules, persistence, interfaces, tests and compatibility.
7. Implement the smallest change that satisfies the specification.
8. Run:
   - `.autodev/commands/inspect`
   - `.autodev/commands/validate`
   - `.autodev/commands/test`
   - `.autodev/commands/build`
9. Fix validation failures before considering the task complete.
10. Update specs when behavior changes.
11. Record significant architectural decisions in `.autodev/state/decisions.md`.
12. Never perform protected operations listed in `.autodev/manifest.yaml` without explicit human approval.

## General rules

- Do not rewrite unrelated code.
- Do not add dependencies without a concrete reason.
- Do not duplicate business rules across layers when avoidable.
- Do not infer production credentials or production access.
- Prefer existing project conventions over introducing new abstractions.
