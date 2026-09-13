# Architectural Decision Ledger

Record only meaningful decisions that future agents or developers should know.

---

## ADR-000 - Autonomous development contract

Status: accepted

Decision:
This repository uses `.autodev` as the technology-independent contract between business specifications, engineering constraints and development agents.

Consequences:
- Agents should read `.autodev/manifest.yaml` before making changes.
- Project-specific commands are hidden behind `.autodev/commands/*`.
- Business specifications should avoid implementation details unless technically necessary.
