# Smoke Tests

## Checkpoint 2: App Shell
1. Build and run the app.
2. Confirm the menu bar icon appears (text magnifier icon).
3. Click the menu bar icon and verify menu items:
   - Open History
   - Settings
   - Quit
4. Select "Open History" and confirm a window appears.
5. Select "Settings" and confirm a window appears.
6. Select "Quit" and confirm the app exits.

## Checkpoint 3: Selection Capture
1. Build and run the app.
2. If prompted, grant Accessibility permission for the app.
3. In another app (for example, Safari), select some text.
4. Open the menu bar menu and click "Explain Selection (Debug)".
5. Confirm a floating popover appears with:
   - selected text section
   - response section
   - source label
6. Click "Ask About Selection (Debug)".
7. Confirm the popover includes a prompt field and "Submit Prompt" action.
8. Enter a prompt and submit, then confirm response text updates.
9. In an app where Accessibility selection is unavailable, repeat and confirm clipboard fallback or "No Selection Captured" alert.

## Checkpoint 5: Provider Layer
1. Set provider environment variables before launch.
2. Gemini path:
   - set `SELECT_AND_SEARCH_PROVIDER=gemini`
   - set `GEMINI_API_KEY=<your_key>`
3. OpenAI path:
   - set `SELECT_AND_SEARCH_PROVIDER=openai`
   - set `OPENAI_API_KEY=<your_key>`
4. Anthropic path:
   - set `SELECT_AND_SEARCH_PROVIDER=anthropic`
   - set `ANTHROPIC_API_KEY=<your_key>`
5. Local path (Ollama/LM Studio):
   - set `SELECT_AND_SEARCH_PROVIDER=local`
   - optionally set `LOCAL_LLM_BASE_URL` and `LOCAL_LLM_MODEL`
6. Run app, select text in Safari/Chrome/PDF reader, then trigger:
   - `Explain Selection (Debug)`
   - `Ask About Selection (Debug)`
7. Confirm popover behavior:
   - loading indicator appears while request is in-flight
   - response renders after completion
   - submit is disabled when prompt is empty
8. Failure-path check:
   - remove remote API key and retry
   - confirm popover shows a clear provider error message

## Checkpoint 6: Settings + Keychain
1. Launch app and open Settings from the menu bar.
2. In "Default Provider", switch provider (for example, Gemini to Anthropic).
3. Update model/base URL fields and close Settings.
4. Re-open Settings and confirm values persisted.
5. Enter an API key into one of the secure fields and close Settings.
6. Re-open Settings and confirm the key is still present.
7. Trigger `Explain Selection (Debug)` or `Ask About Selection (Debug)` and verify requests use the selected provider configuration.
8. Clear an API key in Settings and retry request; confirm environment fallback is used when set, otherwise a clear missing-key error is shown.

## Checkpoint 7: History Store
1. Launch app and trigger `Explain Selection (Debug)` on any selected text.
2. Trigger `Ask About Selection (Debug)`, submit a prompt, and wait for response.
3. Open History from the menu bar.
4. Confirm at least two entries appear in the left list.
5. Select each entry and verify detail panel shows:
   - timestamp
   - app/source metadata
   - selection text
   - response text
   - prompt (for Ask entries)
6. Click `Clear History` and verify list becomes empty.
7. Relaunch the app and confirm cleared state is preserved.
