# Testing Policy

The repository must expose a technology-independent testing contract through:

`.autodev/commands/test`

The underlying implementation may use any test framework.

Minimum expectations:

- Business rules should have automated tests.
- Bug fixes should include regression coverage when practical.
- Validation failures must block completion.
- Tests must not depend on production services unless explicitly approved.
