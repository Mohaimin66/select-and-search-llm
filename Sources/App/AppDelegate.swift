import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let accessibilityPermissionService: AccessibilityPermissionProviding
    let settingsStore: AppSettingsStore
    let historyStore: AppHistoryStore

    override init() {
        accessibilityPermissionService = AccessibilityPermissionService()
        settingsStore = AppSettingsStore()
        historyStore = AppHistoryStore()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if !accessibilityPermissionService.isTrusted {
            _ = accessibilityPermissionService.requestIfNeeded()
        }
        statusBarController = StatusBarController(settingsStore: settingsStore, historyStore: historyStore)
    }
}
