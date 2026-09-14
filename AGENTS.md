# Agent Instructions & Operating Contract

This repository is governed by **AutoDev Core**, a technology-agnostic lifecycle, state machine and policy engine.
Before modifying any files, internalize the strict division of responsibilities:

---

## 1. Division of Responsibilities

### ENGINE RESPONSIBILITIES (Deterministic Governance)
- **Lifecycle & Phase Enforcement:** Enforces phase progression (`bootstrap` -> `specification` -> `development` -> `complete`).
- **State Machine Transitions:** Controls `.autodev/state/progress.json` and prevents invalid state leaps.
- **Contract Execution:** Executes delegated adapters (`validate`, `test`, `build`, `verify`, `run`, etc.) via `.autodev/runtime.yaml`.
- **Policy Enforcement:** Detects forbidden secrets (`.env`, `*.key`), protected paths, and changes exceeding threshold.
- **Evidence Collection:** Writes audit artifacts into `.autodev/evidence/<FEATURE_ID>.json`.
- **Feature Queue & Dependency Graph:** Resolves `depends_on` relationships between features.
- **Atomic Git Orchestration:** Stages only permitted files and commits verified features cleanly.

### AGENT RESPONSIBILITIES (Reasoning & Implementation)
- **Requirements Analysis:** Interpret `PRODUCT_BRIEF.md` and user intentions.
- **Domain Modeling:** Model entities in `.autodev/domain/entities.md` and business rules in `.autodev/domain/rules.md`.
- **Architecture & Stack Selection:** Select frameworks, languages, libraries and testing tools best suited to the domain.
- **Project Driver Configuration:** Populate `.autodev/runtime.yaml` with the exact commands for the chosen stack.
- **ADR Ledger Maintenance:** Document every significant architectural decision in `.autodev/state/decisions.md`.
- **Feature Decomposition:** Generate atomic specifications under `.autodev/features/` with clear acceptance criteria (Given/When/Then) and dependency declarations (`depends_on`).
- **Walking Skeleton (Greenfield):** Implement an initial end-to-end vertical slice (`F001`) proving runtime, tests and build work.
- **Feature Implementation:** Write clean production code fulfilling the active feature specification.
- **Automated Tests & Verification:** Design unit, integration and acceptance tests that verify the feature rules.
- **Defect Resolution:** Analyze test failures, debug root causes, and adjust code until all contracts pass.

---

## 2. Operating Lifecycle

### Phase 0: Bootstrap (Greenfield or Brownfield)
1. Run `.autodev/commands/bootstrap` (or `.ps1` on Windows) to initialize the state machine, git (if missing), and directories.
2. Read `PRODUCT_BRIEF.md` (or inspect the existing project).
3. Record architectural decisions (language, framework, persistence) in `.autodev/state/decisions.md`.
4. Configure `.autodev/runtime.yaml` with the real commands (`validate`, `test`, `build`, `run`, `verify`).
5. **For Greenfield projects:** Implement a **Walking Skeleton (`F001`)** proving:
   - Application entrypoint boots
   - Health check command exits cleanly
   - Minimal automated test passes
   - Build completes without errors
   - Verification succeeds
6. Transition `progress.json` to `"phase": "specification"`.

### Phase 1: Specification (Decomposition)
1. Run `.autodev/commands/plan` to index feature files and resolve dependencies.
2. Decompose `PRODUCT_BRIEF.md` into atomic specifications under `.autodev/features/F002-....md`, `F003-....md`.
3. Each feature file must declare:
   - Metadata (`id`, `title`, `depends_on`)
   - Objective & Actors
   - Preconditions & Business Rules
   - Scenarios & Acceptance Criteria
4. Re-run `.autodev/commands/plan` to sync features into `progress.json` and transition to `"phase": "development"`.

### Phase 2: Feature Execution Cycle
For each feature selected by the engine:
1. Engine sets feature status: `pending` -> `ready` -> `implementing`.
2. Agent reads feature specification.
3. Agent writes the minimal production code and corresponding automated tests.
4. Engine sets feature status to `validating` and runs contracts in sequence:
   - `.autodev/commands/validate`
   - `.autodev/commands/test`
   - `.autodev/commands/build`
   - `.autodev/commands/verify`
5. **If any contract fails:**
   - Feature moves to `failed`, increments `attempts`.
   - Engine moves feature to `implementing`.
   - Agent inspects failures and fixes the code.
6. **If all contracts pass:**
   - Engine inspects git status against security policies (checks for forbidden secrets and protected files).
   - Engine generates `.autodev/evidence/<FEATURE_ID>.json`.
   - Engine stages permitted changes and creates an atomic commit.
   - Feature transitions to `completed`.
   - Engine unlocks dependent features (`pending` -> `ready`).

---

## 3. General Rules & Constraints

- **Never hardcode technology assumptions in AutoDev Core.** All commands must delegate strictly to `.autodev/runtime.yaml`.
- **Do not commit secrets:** Any presence of `.env*`, `*.pem`, `*.key`, or credentials immediately halts the cycle with status `blocked`.
- **Protected files require approval:** Modifying `.autodev/policies/**` or `.autodev/manifest.yaml` marks the feature as `approval_required`.
- **Maintain documentation integrity:** Update domain models and decisions ledger as the architecture evolves.
- **Respect platform parity:** Both PowerShell (`.ps1`) and POSIX shell (`sh/bash`) scripts must behave identically.
