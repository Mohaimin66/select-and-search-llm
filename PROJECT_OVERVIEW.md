# Select-and-Search LLM (macOS) - Project Overview

## Goal
Build a lightweight, privacy-forward macOS app that lets you select text anywhere (Safari, Chrome, PDF readers, document editors) and instantly get an LLM-powered explanation or summary in a small popover. The app should run in the background (menu bar), support global hotkeys, and provide a minimal UI with a chat/history view.

## Core Use Cases (v1 focus)
1. Select text in Safari or Chrome, hit a hotkey, see an explanation popover.
2. Select text in common PDF readers, hit a hotkey, see an explanation popover (selection-only).
3. Global hotkey opens a prompt bar prefilled with selected text, user can refine and send.
4. Right-click / Services menu entry triggers the same action.
5. History view shows past prompts and responses.

## Non-Goals (v1)
- OCR for images or scanned PDFs.
- Full-document ingestion in arbitrary apps.
- Deep per-app integrations (e.g., browser extensions) in v1.

## UX / Interaction Model
**Primary triggers**
- Hotkey A: "Explain Selection" (instant call)
- Hotkey B: "Ask About Selection" (opens prompt bar for edits)
Default hotkeys:
- Explain Selection: Control + Option + E
- Ask About Selection: Control + Option + P

**Popover**
- Minimal window anchored near selection (best effort).
- Shows response + actions: "Copy", "Follow-up", "Open History".

**History UI**
- Simple list of entries: timestamp, app name, selected text, prompt, response.
- Local storage only.

## Privacy + Model Options
- Local models: support Ollama or LM Studio (HTTP API).
- Cloud models: OpenAI and Gemini in MVP via user-provided API key.
- Future: Anthropic, Hugging Face.
- No data is sent anywhere unless the user explicitly configures a provider.
- Allow per-provider selection and a default model.
- Default local server: Ollama (LM Studio supported, not default).
- Default local model: `llama3.2:3b` (fallback to `gemma2:2b` on low-memory systems).
- Default Gemini model: `gemini-2.5-flash`.

## Technical Approach (macOS)
### App Type
- Menu bar app with an on-demand popover + optional main window (history).

### Selection Capture
1. **Accessibility APIs** (primary)
   - Use AXUIElement to read `AXSelectedText` and `AXSelectedTextRange`.
   - Try to fetch nearby context using `AXVisibleText` or `AXValue`.
   - Use `kAXBoundsForRangeParameterizedAttribute` to anchor popover near selection.
2. **Clipboard fallback**
   - Simulate copy of selection when accessibility data is unavailable.
   - Restore clipboard content after read.

### Context Strategy
- Default: selection only.
- If available: include a small "nearby context" window (1-2 paragraphs).
- Apply a context budget; trim or compress nearby context when over budget.
- For PDFs: selection only in v1.
- Optional future: per-app context depth.

### Global Hotkeys
- Register global hotkeys (Carbon or NSEvent).
- Configurable in settings.

### Right-Click Integration
- Implement macOS **Services** entry ("Explain Selection").
- This appears in the context menu in many apps and can be enabled in:
  System Settings > Keyboard > Shortcuts > Services.

### LLM Abstraction
Define a provider interface:
- `prepareRequest(input, context, prompt, model)`
- `send()` -> streaming or non-streaming response
Implement providers:
- OpenAI
- Gemini
- Local (Ollama, LM Studio)
Future: Anthropic, Hugging Face.

### Data Storage
- Lightweight local storage (SQLite or Core Data).
- Store only minimal metadata and response content.

## MVP Feature Set
- Menu bar presence.
- Global hotkeys.
- Selection capture (AX + clipboard fallback).
- Popover UI with response.
- Prompt bar for custom question.
- Local history view.
- Provider configuration (Gemini + OpenAI + Local).

## Phased Implementation Plan
**Phase 0: Prototype**
- Basic app shell + menu bar icon
- Accessibility permission flow
- Read selection + show simple popover

**Phase 1: MVP**
- Hotkeys (Explain + Ask)
- LLM provider abstraction
- Gemini + OpenAI + Local providers
- History UI
- Settings for API keys + default model

**Phase 2: Usability**
- Improve context extraction (visible text)
- Better popover positioning (bounds for range)
- Services menu entry

**Phase 3: Expansion**
- Add providers (Anthropic, Hugging Face)
- Per-app settings (context depth, prompt templates)
- Streaming responses

## Key Risks / Constraints
- Accessibility APIs are inconsistent across apps.
- PDF readers may not expose nearby context.
- Clipboard fallback can be flaky (must be careful to restore clipboard content).
- Global hotkeys can conflict with other apps.

## Open Questions
- Should we add a browser extension later for deeper context?
- Do we want on-device model bundles or rely on user-installed local servers?
- Which local small model should be recommended by default?

## Suggested Next Step
Confirm the app stack for the first prototype (Swift + SwiftUI recommended for macOS).
