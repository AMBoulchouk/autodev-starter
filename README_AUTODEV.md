# AutoDev Starter

This folder makes a repository easier for autonomous coding agents to operate without prescribing a specific technology stack.

## 1. Copy into your project

Copy these items to the root of an existing repository:

- `.autodev/`
- `AGENTS.md`

## 2. Configure the manifest

Edit:

`.autodev/manifest.yaml`

Set the project name, capabilities and autonomy policy.

## 3. Connect the project-specific commands

Edit the files under:

`.autodev/commands/`

Each command is an adapter. The agent should call the adapter, not the underlying framework command directly.

For example, if your project uses a command like:

    npm test

or:

    dotnet test

or:

    pytest

put that command inside `.autodev/commands/test`.

The same pattern applies to:

- inspect
- validate
- test
- build
- run
- deploy-preview

## 4. Write business specifications

Create features under:

`.autodev/features/`

Focus on:

- objective
- actors
- preconditions
- business rules
- outcomes
- acceptance criteria

Avoid implementation details unless they are themselves a requirement.

## 5. Give the coding agent a task

Example:

    Implement `.autodev/features/example-feature.md`.

A compliant agent should inspect the repository, implement the change, run the project contracts and update decision records when needed.

## Suggested first local test

1. Copy this starter into a small existing repository.
2. Replace the placeholder command adapters with the real commands used by the project.
3. Set the capabilities in `.autodev/manifest.yaml`.
4. Ask the coding agent to implement a tiny feature from `.autodev/features/`.
5. Verify that the agent uses the `.autodev/commands/*` contracts instead of hard-coding assumptions about the technology.
