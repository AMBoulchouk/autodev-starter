# Command adapters

These files are the boundary between the technology-independent AutoDev contract and the real project.

Replace each placeholder with the command appropriate for your repository.

Expected behavior:

- `inspect`: report useful project/environment information.
- `validate`: run static validation, linting, formatting checks, type checks or equivalent.
- `test`: run automated tests.
- `build`: produce or verify a build.
- `run`: start the project locally.
- `deploy-preview`: create a non-production preview if supported.

Keep the filenames stable even when the implementation changes.
