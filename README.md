# Select-and-Search LLM

System-wide text selection explainer for macOS. Select text anywhere (Safari, Chrome, PDF readers, editors) and get an LLM explanation in a small popover.

## Status
Early development. See `ARCHITECTURE.md` and `SMOKE_TESTS.md`.

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

## Provider Runtime Config (Current)
- `SELECT_AND_SEARCH_PROVIDER`: `gemini` (default), `openai`, `local`
- Gemini:
  - `GEMINI_API_KEY`
  - `GEMINI_MODEL` (default: `gemini-2.5-flash`)
- OpenAI:
  - `OPENAI_API_KEY`
  - `OPENAI_MODEL` (default: `gpt-4.1-mini`)
- Local:
  - `LOCAL_LLM_BASE_URL` (default: `http://localhost:11434`)
  - `LOCAL_LLM_MODEL` (default: `llama3.2:3b`)
  - `LOCAL_LLM_API_KEY` (optional)

## Docs
- `ARCHITECTURE.md`
- `SMOKE_TESTS.md`

## License
Apache-2.0. See `LICENSE`.
