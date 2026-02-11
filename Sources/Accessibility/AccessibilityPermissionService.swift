import ApplicationServices

protocol AccessibilityPermissionProviding {
    var isTrusted: Bool { get }
    @discardableResult
    func requestIfNeeded() -> Bool
}

struct AccessibilityPermissionService: AccessibilityPermissionProviding {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    func requestIfNeeded() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
