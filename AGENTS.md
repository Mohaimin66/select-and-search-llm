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
- Treat CodeRabbit review as a required PR quality gate by default.
- Wait for CodeRabbit review to complete before requesting merge.
- If CodeRabbit posts actionable comments, apply fixes, push updates, and re-trigger review (comment if needed).
- Critically evaluate CodeRabbit comments against full project context; do not apply suggestions blindly.
- If a suggestion is incorrect or lower quality, respond with technical reasoning in the PR discussion and keep the stronger implementation.
- Continue the review discussion with CodeRabbit until the PR reaches an approved, stable state ready for user review.
- Do not ask for merge approval until CodeRabbit has no actionable comments or the user explicitly waives this gate.

## Testing and Verification
- Always add or update unit tests for new logic.
- Add integration tests for cross-module flows when applicable.
- Run the relevant test suites locally and report results.
- Manually verify UI changes (smoke checklist).
- If tests cannot run, document the blocker and request what is needed.
- Prioritize software quality, correctness, accessibility, and security in every change and review response.

## Documentation
- Keep `ARCHITECTURE.md` updated.
- Add/update `SMOKE_TESTS.md` for manual verification steps.

## Permissions
- Ask before running commands that require elevated permissions or external tools.
