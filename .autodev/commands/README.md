# Command adapters

These files are the boundary between the technology-independent AutoDev contract and the real project. AutoDev Core remains 100% agnostic of technologies and delegates operational commands strictly to the Project Driver (`.autodev/runtime.yaml`).

Available contracts:

- `bootstrap`: initialize environment, git repository, directory structure and state tracking.
- `plan`: deterministic coordinator that indexes feature specifications, resolves dependencies and updates the work queue.
- `auto-cycle`: run the automated development cycle (validate -> test -> build -> verify -> git safety -> evidence -> commit -> advance).
- `inspect`: report project, governance and driver diagnostics without blocking.
- `validate`: run structural governance checks and delegate code validation to `runtime.yaml commands.validate`.
- `test`: delegate automated test execution to `runtime.yaml commands.test`.
- `build`: delegate compilation/bundle execution to `runtime.yaml commands.build`.
- `verify`: verify feature acceptance criteria delegating to `runtime.yaml commands.verify`.
- `run`: start the project locally delegating to `runtime.yaml commands.run`.
- `deploy-preview`: create a non-production preview delegating to `runtime.yaml commands.preview`.

Both POSIX shell scripts (`command`) and PowerShell scripts (`command.ps1`) are provided for 100% cross-platform parity.
