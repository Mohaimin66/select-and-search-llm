# Implementation Checkpoints

## Checkpoint 1: Repo Bootstrap and Docs
- Status: completed (2026-02-04)
- Scope:
  - README and project docs
  - Architecture overview
  - Contribution and security policies
  - License

## Checkpoint 2: App Shell
- Status: blocked (Xcode required for XCTest + manual smoke run)
- Scope:
  - SwiftUI app skeleton
  - Menu bar icon + menu
  - Basic window for history/settings
  - Basic smoke test plan

## Checkpoint 3: Accessibility + Selection Capture
- Status: pending
- Scope:
  - Accessibility permission flow
  - Read selected text (AX)
  - Clipboard fallback
  - Unit tests for selection parsing utilities

## Checkpoint 4: Popover UI
- Status: pending
- Scope:
  - Popover anchored near selection
  - Prompt bar
  - Response view

## Checkpoint 5: Provider Abstraction
- Status: pending
- Scope:
  - Provider protocol
  - Request/response normalization
  - Error handling
  - Unit tests for request building and error mapping

## Checkpoint 6: Provider Implementations
- Status: pending
- Scope:
  - Gemini 2.5 Flash
  - OpenAI (configurable)
  - Local (Ollama default, LM Studio optional)
  - Integration tests for mock providers

## Checkpoint 7: History Store
- Status: pending
- Scope:
  - Local storage
  - List + detail view

## Checkpoint 8: Settings
- Status: pending
- Scope:
  - API keys (Keychain)
  - Hotkeys
  - Provider defaults
  - Local setup wizard
  - Manual verification checklist update

## Checkpoint 9: Services Menu
- Status: pending
- Scope:
  - macOS Services integration
