import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let accessibilityPermissionService: AccessibilityPermissionProviding

    override init() {
        accessibilityPermissionService = AccessibilityPermissionService()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if !accessibilityPermissionService.isTrusted {
            _ = accessibilityPermissionService.requestIfNeeded()
        }
        statusBarController = StatusBarController()
    }
}
