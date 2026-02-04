# Select-and-Search LLM - Detailed Plan

## Decisions (Confirmed)
- Stack: Swift + SwiftUI.
- Providers in MVP: OpenAI + Gemini + Local (Ollama/LM Studio style HTTP servers).
- Future providers: Anthropic, Hugging Face (keep interface ready).
- v1: no OCR.
- Inputs: selection + small nearby context when available.
- Triggers: global hotkeys + right-click (Services menu).
- Default hotkeys:
  - Explain Selection: Control + Option + E
  - Ask About Selection: Control + Option + P
- Default local server: Ollama (LM Studio supported, not default).
- Default local model: `llama3.2:3b` (fallback to `gemma2:2b` on low-memory systems).
- Default Gemini model: `gemini-2.5-flash`.

## Architecture (Modules)
1. **App Shell**
   - Menu bar app with optional main window (history + settings).
2. **Selection Capture**
   - Primary: Accessibility APIs (AXSelectedText, AXSelectedTextRange).
   - Secondary: clipboard fallback (temporary copy + restore).
3. **Context Builder**
   - Default: selection only.
   - If available: small nearby context window (1-2 paragraphs).
   - Context budgeter to cap input size and latency.
   - Optional compression: summarize nearby context when over budget.
4. **LLM Provider Layer**
   - Protocol: `Provider` with `prepareRequest(...)` and `send(...)`.
   - Implementations: OpenAI, Gemini, Local.
   - Stubs for Anthropic/Hugging Face.
5. **UI Layer**
   - Popover anchored near selection (best effort).
   - Prompt bar mode (editable input).
   - Response view with copy + follow-up.
6. **History Store**
   - Local only; Core Data or SQLite.
   - Stores: app name, timestamp, selection, prompt, response, model.
7. **Settings**
   - API keys stored in Keychain.
   - Provider selection + default model.
   - Hotkey configuration.
   - Local setup status (Ollama/LM Studio detection + setup guidance).

## Data Flow (Hotkey → Answer)
1. User selects text.
2. Hotkey fires.
3. Selection capture:
   - Try Accessibility text.
   - If missing, fallback to clipboard read.
4. Context builder adds nearby text if available.
   - If over budget, compress context or trim with a priority order.
5. Provider builds prompt (system + user + context).
6. LLM response streamed or one-shot.
7. Popover displays response.
8. Entry saved in history.

## UX (MVP)
- **Hotkey A**: Explain Selection (auto-submit)
- **Hotkey B**: Ask About Selection (open prompt bar)
- Popover:
  - Response
  - Copy button
  - Follow-up input
  - Open History
- Menu bar menu:
  - Open History
  - Settings
  - Quit

## Right-Click Integration (Services)
- Add a macOS Services entry "Explain Selection".
- Appears in app context menus where text is selected.
- Uses same pipeline as Hotkey A.

## Permissions
- Accessibility permission required for selection capture + global hotkeys (event tap).
- Clipboard access for fallback capture.

## Implementation Phases
### Phase 0: Feasibility Prototype
- Menu bar app shell.
- Accessibility permission prompt.
- Read selection and display basic popover.
- Log capture results to console.

### Phase 1: MVP
- Global hotkeys (Explain + Ask).
- LLM provider abstraction.
- OpenAI + Gemini + Local providers.
- Prompt bar + response UI.
- History store.
- Settings view.

### Phase 2: Context & Services
- Nearby context extraction (when supported).
- Popover anchoring with text bounds.
- Services menu integration.

### Phase 3: Providers + Polish
- Add Anthropic, Hugging Face providers.
- Streaming responses.
- Per-app context settings.

## Acceptance Criteria (MVP)
- Works in Safari and Chrome for selection.
- Works (selection-only, best effort) in:
  - Preview
  - Adobe Acrobat
  - Skim
  - PDF Expert
- Hotkey A returns a response in a popover within ~2 seconds on a fast model.
- Hotkey B opens prompt bar with selection prefilled.
- History view shows last 50+ interactions.

## Local Model Onboarding (Minimal Setup)
- On first run, detect:
  - Physical memory (for capacity check).
  - Whether Ollama is running at `localhost:11434`.
  - Whether LM Studio server is running at its configured port (if user set it).
- If insufficient memory, disable local models by default and show guidance.
- If Ollama is not installed/running:
  - Show "Install Ollama" and "Start Ollama" guidance.
  - Once running, offer a "Download recommended small model" action or instructions.
- Always allow user override.

## Open Questions
- Which local small model should be recommended by default?
- Do we need per-app overrides in v1?
