# Architecture Overview

## Summary
Select-and-Search LLM is a macOS menu bar app that captures selected text system-wide and returns LLM explanations in a small popover. It uses Accessibility APIs for selection capture, falls back to clipboard where necessary, and supports multiple LLM providers with local-first privacy options.

Current implementation status:
- App shell is implemented.
- Selection capture service is implemented (Accessibility first, clipboard fallback).
- Popover and prompt bar flows are implemented behind debug menu actions (`Explain Selection (Debug)` and `Ask About Selection (Debug)`).
- LLM provider layer is implemented and wired into popover responses.
- Settings store is implemented with UserDefaults persistence and Keychain-backed API keys.
- History store is implemented with local JSON persistence and list/detail UI.

## Components
1. **App Shell**
   - Menu bar app with optional main window (history + settings).
   - SwiftUI for UI; AppKit for system services, event taps, and popovers.
2. **Selection Capture**
   - Primary: Accessibility APIs to read selected text and selection bounds.
   - Fallback: Clipboard copy + restore.
   - Current surface: debug alert to validate capture source and text.
3. **Context Budgeter**
   - Applies a token/character budget to limit input size.
   - Default: selection only.
   - Optional: include nearby context when available.
4. **LLM Provider Layer**
   - Provider protocol with request/response normalization.
   - Implementations: Gemini, Anthropic, OpenAI, Local (Ollama/LM Studio).
   - Runtime provider selection from environment:
     - `SELECT_AND_SEARCH_PROVIDER` (`gemini` default, `anthropic`, `openai`, `local`)
     - `GEMINI_API_KEY`, `GEMINI_MODEL` (`gemini-2.5-flash` default)
     - `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL` (`claude-3-5-haiku-latest` default), `ANTHROPIC_BASE_URL` (`https://api.anthropic.com` default), `ANTHROPIC_VERSION` (`2023-06-01` default)
     - `OPENAI_API_KEY`, `OPENAI_MODEL` (`gpt-4.1-mini` default)
     - `LOCAL_LLM_BASE_URL` (`http://localhost:11434` default), `LOCAL_LLM_MODEL` (`llama3.2:3b` default), `LOCAL_LLM_API_KEY` (optional)
5. **UI Layer**
   - Popover anchored near selection.
   - Prompt bar for editable queries.
   - Response display with copy/follow-up.
   - Current implementation: floating popover near cursor with selection, prompt input (ask mode), response panel, loading indicator, and provider error messaging.
6. **History Store**
   - Local-only storage (Core Data or SQLite).
   - Stores selection, prompt, response, provider, timestamps.
   - Current implementation: local JSON persistence in Application Support with in-app list/detail browsing and clear-history action.
7. **Settings**
   - API keys in Keychain.
   - Provider defaults and model selection.
   - Hotkey customization.
   - Local setup wizard and capacity checks.
   - Current implementation: provider/model/base URL settings are persisted via `AppSettingsStore`; API keys are stored via `KeychainService`.

## Core Flows
**Explain Selection**
1. Hotkey or Services menu triggers.
2. Capture selected text + optional context.
3. Build prompt and send to provider.
4. Show popover with response.
5. Store history entry.

**Ask About Selection**
1. Hotkey triggers prompt bar.
2. User edits prompt.
3. Send to provider and show response.
4. Store history entry.

## Permissions & Security
- Accessibility permission required for selection capture.
- Clipboard access used only as fallback and restored immediately.
- API keys can be loaded from Settings (Keychain) with environment fallback.
- No telemetry; all logs local.

## Local Model Support
- Detect local server availability (Ollama default).
- Offer model download once server is running.
- Use memory heuristics to warn about oversized models.
- Allow user override with warnings.

## Extensibility
- Provider protocol allows easy addition of new APIs.
- Context budgeter can be extended for smarter compression.
- Services menu and hotkeys are modular.
