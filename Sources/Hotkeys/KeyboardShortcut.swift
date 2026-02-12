import Foundation

enum ShortcutKey: String, CaseIterable, Codable, Equatable, Sendable {
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z

    var displayName: String {
        rawValue.uppercased()
    }
}

struct ShortcutModifiers: OptionSet, Codable, Equatable, Sendable {
    let rawValue: UInt8

    static let control = ShortcutModifiers(rawValue: 1 << 0)
    static let option = ShortcutModifiers(rawValue: 1 << 1)
    static let command = ShortcutModifiers(rawValue: 1 << 2)
    static let shift = ShortcutModifiers(rawValue: 1 << 3)

    static let defaultExplain: ShortcutModifiers = [.control, .option]
}

struct KeyboardShortcut: Codable, Equatable, Sendable {
    var key: ShortcutKey
    var modifiers: ShortcutModifiers

    static let defaultExplain = KeyboardShortcut(key: .e, modifiers: .defaultExplain)
    static let defaultAsk = KeyboardShortcut(key: .p, modifiers: .defaultExplain)

    var displayLabel: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("Ctrl") }
        if modifiers.contains(.option) { parts.append("Opt") }
        if modifiers.contains(.command) { parts.append("Cmd") }
        if modifiers.contains(.shift) { parts.append("Shift") }
        parts.append(key.displayName)
        return parts.joined(separator: " + ")
    }
}
