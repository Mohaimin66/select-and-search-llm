import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let accessibilityPermissionService: AccessibilityPermissionProviding
    let settingsStore: AppSettingsStore

    override init() {
        accessibilityPermissionService = AccessibilityPermissionService()
        settingsStore = AppSettingsStore()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if !accessibilityPermissionService.isTrusted {
            _ = accessibilityPermissionService.requestIfNeeded()
        }
        statusBarController = StatusBarController(settingsStore: settingsStore)
    }
}
