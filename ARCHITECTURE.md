# Architecture Overview

## Summary
Select-and-Search LLM is a macOS menu bar app that captures selected text system-wide and returns LLM explanations in a small popover. It uses Accessibility APIs for selection capture, falls back to clipboard where necessary, and supports multiple LLM providers with local-first privacy options.

## Components
1. **App Shell**
   - Menu bar app with optional main window (history + settings).
   - SwiftUI for UI; AppKit for system services, event taps, and popovers.
2. **Selection Capture**
   - Primary: Accessibility APIs to read selected text and selection bounds.
   - Fallback: Clipboard copy + restore.
3. **Context Budgeter**
   - Applies a token/character budget to limit input size.
   - Default: selection only.
   - Optional: include nearby context when available.
4. **LLM Provider Layer**
   - Provider protocol with request/response normalization.
   - Implementations: Gemini, OpenAI, Local (Ollama/LM Studio).
5. **UI Layer**
   - Popover anchored near selection.
   - Prompt bar for editable queries.
   - Response display with copy/follow-up.
6. **History Store**
   - Local-only storage (Core Data or SQLite).
   - Stores selection, prompt, response, provider, timestamps.
7. **Settings**
   - API keys in Keychain.
   - Provider defaults and model selection.
   - Hotkey customization.
   - Local setup wizard and capacity checks.

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
- API keys stored in Keychain.
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
