# Agent Instructions

Before modifying this repository:

1. Read `.autodev/manifest.yaml`.
2. Read `.autodev/architecture.md`.
3. Read `.autodev/state/progress.json` (and `.autodev/state/decisions.md` if present).
4. Identify the current workflow phase:
   - **Phase 0: Bootstrap (Greenfield / Setup)**:
     - If the repository has no code/stack or `progress.json` has `"phase": "bootstrap"`:
     - Read `PRODUCT_BRIEF.md` (if available) to identify desired tech stack or requirements.
     - Run `.autodev/commands/bootstrap` (or `.ps1` on Windows) to initialize the base project structure.
     - Configure the real package manager, linter, and test runner in the project.
     - Transition `progress.json` to `"phase": "specification"`.
   - **Phase 1: Specification (Decomposition)**:
     - If `progress.json` has `"phase": "specification"`:
     - Analyze `PRODUCT_BRIEF.md` to model domain entities (`.autodev/domain/entities.md`) and rules (`.autodev/domain/rules.md`).
     - Generate sequential, atomic feature files under `.autodev/features/` (e.g., `01-scaffold.md`, `02-auth.md`, etc.).
     - Populate `features_pending` in `.autodev/state/progress.json` and set `"phase": "development"`.
   - **Phase 2: Feature Implementation (Execution Cycle)**:
     - Pick the next feature from `features_pending` in `progress.json`.
     - Set `current_feature` in `progress.json`.
     - Read the target feature specification.
     - Implement the smallest change that satisfies the specification.
     - Write corresponding automated tests.
5. Run project contracts:
   - `.autodev/commands/inspect`
   - `.autodev/commands/validate`
   - `.autodev/commands/test`
   - `.autodev/commands/build`
6. Fix any validation or test failures before considering the feature complete.
7. Upon passing all contracts:
   - Move the feature from `features_pending` to `features_completed` in `progress.json`.
   - Record significant architectural decisions in `.autodev/state/decisions.md`.
   - Commit changes cleanly.
8. Never perform protected operations listed in `.autodev/manifest.yaml` without explicit human approval.

## General rules

- Do not rewrite unrelated code.
- Do not add dependencies without a concrete reason.
- Do not duplicate business rules across layers when avoidable.
- Do not infer production credentials or production access.
- Prefer existing project conventions over introducing new abstractions.
- Respect Windows and Unix portability (both PowerShell `.ps1` and POSIX shell scripts exist under `.autodev/commands/`).
