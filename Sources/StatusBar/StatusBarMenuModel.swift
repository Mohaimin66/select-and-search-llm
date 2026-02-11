import Foundation

enum StatusBarAction: String {
    case captureSelection
    case openHistory
    case openSettings
    case quit
}

struct StatusBarMenuItem: Equatable {
    let title: String
    let keyEquivalent: String
    let action: StatusBarAction?
    let isSeparator: Bool

    static func action(title: String, keyEquivalent: String, action: StatusBarAction) -> StatusBarMenuItem {
        StatusBarMenuItem(
            title: title,
            keyEquivalent: keyEquivalent,
            action: action,
            isSeparator: false
        )
    }

    static func separator() -> StatusBarMenuItem {
        StatusBarMenuItem(
            title: "",
            keyEquivalent: "",
            action: nil,
            isSeparator: true
        )
    }
}

enum StatusBarMenuModel {
    static let defaultItems: [StatusBarMenuItem] = [
        .action(title: "Capture Selection (Debug)", keyEquivalent: "e", action: .captureSelection),
        .separator(),
        .action(title: "Open History", keyEquivalent: "h", action: .openHistory),
        .action(title: "Settings", keyEquivalent: ",", action: .openSettings),
        .separator(),
        .action(title: "Quit", keyEquivalent: "q", action: .quit)
    ]
}
