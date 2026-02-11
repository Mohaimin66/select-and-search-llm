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
4. Open the menu bar menu and click "Capture Selection (Debug)".
5. Confirm an alert appears with "Selection Captured (Accessibility)".
6. In an app where Accessibility selection is unavailable, select text and click the same menu item.
7. Confirm an alert appears with "Selection Captured (Clipboard fallback)" or "No Selection Captured".
