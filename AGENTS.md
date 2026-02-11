# Codex Project Instructions

These rules apply to all work in this repository.

## Repo + Git Hygiene
- Ensure a GitHub repo exists before writing code.
- Do not work on `main`. Always create a new branch for changes.
- Commit in small, meaningful checkpoints.
- Never push directly to `main`. Create a PR and wait for approval before merging.
- Prefer parallel PRs for independent changes.
- If changes conflict, continue on the same branch until resolved.
- Each commit must include a clear summary and scope.
- Each PR must include a brief "Thought Process" section with rationale, tradeoffs, and key decisions.

## Testing and Verification
- Always add or update unit tests for new logic.
- Add integration tests for cross-module flows when applicable.
- Run the relevant test suites locally and report results.
- Manually verify UI changes (smoke checklist).
- If tests cannot run, document the blocker and request what is needed.

## Documentation
- Keep `ARCHITECTURE.md` updated.
- Add/update `SMOKE_TESTS.md` for manual verification steps.

## Permissions
- Ask before running commands that require elevated permissions or external tools.
