# Select-and-Search LLM

System-wide text selection explainer for macOS. Select text anywhere (Safari, Chrome, PDF readers, editors) and get an LLM explanation in a small popover.

## Status
Early development. See `ARCHITECTURE.md` and `SMOKE_TESTS.md`.
- Settings now persist provider defaults/models/base URLs in UserDefaults and API keys in Keychain.
- History now persists locally and is viewable in a list/detail History window.

## MVP Goals
- Menu bar app with global hotkeys.
- Selection capture via Accessibility with clipboard fallback.
- Popover UI with Explain and Ask modes.
- Providers: Gemini (default), Anthropic, OpenAI, Local (Ollama/LM Studio).
- History and settings.

## Default Hotkeys
- Explain Selection: `Control + Option + E`
- Ask About Selection: `Control + Option + P`

## Local Models
- Default local server: Ollama.
- Default small model: `llama3.2:3b` (fallback: `gemma2:2b` on low memory).
- LM Studio supported (non-default).

## Provider Runtime Config (Current)
Settings values take precedence. Environment variables are used as fallback for local runs and tests.

- `SELECT_AND_SEARCH_PROVIDER`: `gemini` (default), `anthropic`, `openai`, `local`
- Gemini:
  - `GEMINI_API_KEY`
  - `GEMINI_MODEL` (default: `gemini-2.5-flash`)
- Anthropic:
  - `ANTHROPIC_API_KEY`
  - `ANTHROPIC_MODEL` (default: `claude-3-5-haiku-latest`)
  - `ANTHROPIC_BASE_URL` (default: `https://api.anthropic.com`)
  - `ANTHROPIC_VERSION` (default: `2023-06-01`)
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
