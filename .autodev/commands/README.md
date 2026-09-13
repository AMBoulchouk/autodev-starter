# Command adapters

These files are the boundary between the technology-independent AutoDev contract and the real project. They come with built-in polymorphic detection (Node.js, Python, Go, Rust), but can be customized for specific project tooling.

Available contracts:

- `bootstrap`: initialize environment, git repository and state tracking for blank projects.
- `plan`: synchronize product requirements from `PRODUCT_BRIEF.md` into features and domain models.
- `auto-cycle`: run the automated development cycle (validate -> test -> build -> commit -> advance).
- `inspect`: report useful project, environment and stack information without blocking.
- `validate`: run structural checks and static validation, linting or type checks if configured.
- `test`: run automated tests with graceful handling during early bootstrap phases.
- `build`: produce or verify a build artifact.
- `run`: start the project locally using detected entrypoints.
- `deploy-preview`: create a non-production preview if supported.

Both POSIX shell scripts (`command`) and PowerShell scripts (`command.ps1`) are provided for cross-platform portability.
