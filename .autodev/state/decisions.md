# Architectural Decision Ledger (ADR)

This ledger tracks significant architectural decisions made throughout the lifecycle of the project.
All entries must follow the standardized structure below.

---

## ADR-000 - Autonomous development contract

Status: accepted

Problem:
Autonomous coding agents lack a standardized governance boundary, leading to unstructured code modifications, broken builds, and undocumented architectural drift.

Decision:
Adopt `.autodev` as the technology-independent governance and contract framework.

Reason:
Separating business specifications, engineering constraints, and lifecycle execution creates an auditable boundary for agents.

Rejected alternatives:
Ad-hoc prompt instructions without persistent project-level contracts.

Consequences:
- Agents must adhere to `AGENTS.md` and `.autodev/manifest.yaml`.
- All operational interactions must be channeled through delegated contracts.

---

## ADR-001 - Decoupled Project Driver (`runtime.yaml`)

Status: accepted

Problem:
Hardcoding technology assumptions (such as Node.js, Python, Rust, Go) inside the AutoDev Core creates coupling, prevents support for arbitrary stacks, and forces core modifications for every new toolchain.

Decision:
Introduce `.autodev/runtime.yaml` as an explicit Project Driver interface. AutoDev Core remains 100% technology-agnostic and executes contracts solely through the driver.

Reason:
Preserves total separation between Engine (governance, state, workflow) and Project Driver (real commands and toolchain).

Rejected alternatives:
- Heuristic file sniffing inside core scripts (`package.json`, `Cargo.toml`, etc.).
- Plugin architecture requiring bespoke script adapters for each language.

Consequences:
- The Agent is responsible for populating `.autodev/runtime.yaml` during bootstrap.
- AutoDev Core requires no code changes to support any future language or framework.

---

## ADR-002 - Strict Feature State Machine and Acceptance Evidence

Status: accepted

Problem:
Simple completed/pending lists fail to track feature dependencies, validation failures, retry loops, security violations, or auditable verification of acceptance criteria.

Decision:
Adopt a formal state machine (`pending`, `ready`, `implementing`, `validating`, `blocked`, `approval_required`, `failed`, `completed`, `skipped`) stored in `.autodev/state/progress.json` and generate an immutable audit record for every completed feature under `.autodev/evidence/<FEATURE_ID>.json`.

Reason:
Provides deterministic cycle enforcement, auditable traceability, and recovery from failures without context loss.

Rejected alternatives:
- Free-form markdown checkboxes in task files.
- Ephemeral in-memory execution state.

Consequences:
- Features cannot skip validation or verification.
- Every completed feature leaves a verifiable cryptographic Git commit and JSON evidence payload.
