import Foundation

enum StatusBarAction: String {
    case explainSelection
    case askSelection
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
        .action(title: "Explain Selection (Debug)", keyEquivalent: "e", action: .explainSelection),
        .action(title: "Ask About Selection (Debug)", keyEquivalent: "p", action: .askSelection),
        .separator(),
        .action(title: "Open History", keyEquivalent: "h", action: .openHistory),
        .action(title: "Settings", keyEquivalent: ",", action: .openSettings),
        .separator(),
        .action(title: "Quit", keyEquivalent: "q", action: .quit)
    ]
}
