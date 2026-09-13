# Architecture Contract

This file describes engineering constraints without tying the repository to a specific technology.

## Principles

- Preserve existing project conventions unless a specification explicitly requires a change.
- Prefer the smallest change that satisfies the business requirement.
- Keep business logic independent from presentation and infrastructure when practical.
- Avoid adding dependencies unless there is a clear need.
- External input must be validated at system boundaries.
- Significant architectural decisions must be recorded in `.autodev/state/decisions.md`.
- Database schema changes must be explicit and reproducible.
- Destructive changes require human approval.

## Change strategy

Before implementation:

1. Read the relevant business specification.
2. Inspect existing implementation patterns.
3. Identify impacted components.
4. Determine whether the task touches any protected operation.
5. Implement the smallest compliant change.
6. Run the validation contracts.
7. Update specifications and decision records when necessary.
