# Optional project specifications

Use this folder if the repository already prefers `/specs` as the canonical place for business requirements.

If you do, point agents to it from `AGENTS.md` and keep `.autodev/features/` either as an index or remove duplication.

The important rule is not the folder name; it is maintaining a clear separation between:

- WHAT: business behavior
- CONSTRAINTS: engineering and autonomy policies
- HOW TO OPERATE: executable project adapters
- WHY: architectural decision history
