import Foundation

enum SelectionSource: String, Codable, Equatable, Sendable {
    case accessibility
    case clipboard
}

extension SelectionSource {
    var displayLabel: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .clipboard:
            return "Clipboard fallback"
        }
    }
}

struct SelectionCaptureResult: Equatable {
    let text: String
    let source: SelectionSource
}

@MainActor
final class SelectionCaptureService {
    private let accessibilityProvider: AccessibilitySelectionProviding
    private let clipboardProvider: ClipboardSelectionProviding
    private let normalizer: SelectionTextNormalizing

    init(
        accessibilityProvider: AccessibilitySelectionProviding = AccessibilitySelectionProvider(),
        clipboardProvider: ClipboardSelectionProviding = ClipboardSelectionProvider(),
        normalizer: SelectionTextNormalizing = SelectionTextNormalizer()
    ) {
        self.accessibilityProvider = accessibilityProvider
        self.clipboardProvider = clipboardProvider
        self.normalizer = normalizer
    }

    func captureSelection() -> SelectionCaptureResult? {
        if let text = normalizer.normalize(accessibilityProvider.selectedText()) {
            return SelectionCaptureResult(text: text, source: .accessibility)
        }

        if let text = normalizer.normalize(clipboardProvider.selectedTextByClipboardCopy()) {
            return SelectionCaptureResult(text: text, source: .clipboard)
        }

        return nil
    }
}
