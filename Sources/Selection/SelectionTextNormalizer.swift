import Foundation

protocol SelectionTextNormalizing {
    func normalize(_ text: String?) -> String?
}

struct SelectionTextNormalizer: SelectionTextNormalizing {
    func normalize(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
