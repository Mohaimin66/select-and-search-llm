# Select-and-Search LLM

System-wide text selection explainer for macOS. Select text anywhere (Safari, Chrome, PDF readers, editors) and get an LLM explanation in a small popover.

## Status
Early development. See `PLAN.md` and `CHECKPOINTS.md`.

## MVP Goals
- Menu bar app with global hotkeys.
- Selection capture via Accessibility with clipboard fallback.
- Popover UI with Explain and Ask modes.
- Providers: Gemini (default), OpenAI, Local (Ollama/LM Studio).
- History and settings.

## Default Hotkeys
- Explain Selection: `Control + Option + E`
- Ask About Selection: `Control + Option + P`

## Local Models
- Default local server: Ollama.
- Default small model: `llama3.2:3b` (fallback: `gemma2:2b` on low memory).
- LM Studio supported (non-default).

## Docs
- `PROJECT_OVERVIEW.md`
- `PLAN.md`
- `ARCHITECTURE.md`
- `CHECKPOINTS.md`
- `SMOKE_TESTS.md`

## License
Apache-2.0. See `LICENSE`.
