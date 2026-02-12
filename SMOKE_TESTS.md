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
4. Local path (Ollama/LM Studio):
   - set `SELECT_AND_SEARCH_PROVIDER=local`
   - optionally set `LOCAL_LLM_BASE_URL` and `LOCAL_LLM_MODEL`
5. Run app, select text in Safari/Chrome/PDF reader, then trigger:
   - `Explain Selection (Debug)`
   - `Ask About Selection (Debug)`
6. Confirm popover behavior:
   - loading indicator appears while request is in-flight
   - response renders after completion
   - submit is disabled when prompt is empty
7. Failure-path check:
   - remove remote API key and retry
   - confirm popover shows a clear provider error message
