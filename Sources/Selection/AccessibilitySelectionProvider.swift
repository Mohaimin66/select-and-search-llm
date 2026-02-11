import ApplicationServices
import Foundation

@MainActor
protocol AccessibilitySelectionProviding {
    func selectedText() -> String?
}

@MainActor
struct AccessibilitySelectionProvider: AccessibilitySelectionProviding {
    func selectedText() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedObject: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedObject
        )

        guard focusedStatus == .success, let focusedObject, CFGetTypeID(focusedObject) == AXUIElementGetTypeID() else {
            return nil
        }

        let focusedElement = unsafeDowncast(focusedObject, to: AXUIElement.self)
        var selectedTextObject: CFTypeRef?
        let selectedTextStatus = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextObject
        )

        guard selectedTextStatus == .success else {
            return nil
        }

        return selectedTextObject as? String
    }
}
