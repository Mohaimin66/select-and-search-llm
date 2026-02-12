import Carbon
import Foundation

final class GlobalHotkeyService {
    private enum HotkeyID {
        static let explain: UInt32 = 1
        static let ask: UInt32 = 2
    }

    private static let signature = fourCharCode("SASL")

    private var registeredHotkeys: [UInt32: EventHotKeyRef] = [:]
    private var callbacks: [UInt32: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef?

    init(
        onExplain: @escaping () -> Void,
        onAsk: @escaping () -> Void
    ) {
        callbacks[HotkeyID.explain] = onExplain
        callbacks[HotkeyID.ask] = onAsk
        installEventHandler()
    }

    deinit {
        unregisterAll()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func updateShortcuts(
        explain: KeyboardShortcut,
        ask: KeyboardShortcut
    ) {
        unregisterAll()
        register(shortcut: explain, id: HotkeyID.explain)
        register(shortcut: ask, id: HotkeyID.ask)
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )
    }

    private func register(shortcut: KeyboardShortcut, id: UInt32) {
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.key.carbonKeyCode,
            shortcut.modifiers.carbonFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            return
        }
        registeredHotkeys[id] = hotKeyRef
    }

    private func unregisterAll() {
        for hotkeyRef in registeredHotkeys.values {
            UnregisterEventHotKey(hotkeyRef)
        }
        registeredHotkeys.removeAll()
    }

    fileprivate func handleHotkeyEvent(_ event: EventRef?) -> OSStatus {
        guard let event else {
            return OSStatus(eventNotHandledErr)
        }

        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr else {
            return status
        }

        guard let callback = callbacks[hotkeyID.id] else {
            return OSStatus(eventNotHandledErr)
        }

        callback()
        return noErr
    }
}

private let hotkeyHandler: EventHandlerUPP = { _, event, userData in
    guard let userData else {
        return OSStatus(eventNotHandledErr)
    }

    let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userData).takeUnretainedValue()
    return service.handleHotkeyEvent(event)
}

private extension GlobalHotkeyService {
    static func fourCharCode(_ string: String) -> FourCharCode {
        string.utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}

private extension ShortcutKey {
    var carbonKeyCode: UInt32 {
        switch self {
        case .a: return UInt32(kVK_ANSI_A)
        case .b: return UInt32(kVK_ANSI_B)
        case .c: return UInt32(kVK_ANSI_C)
        case .d: return UInt32(kVK_ANSI_D)
        case .e: return UInt32(kVK_ANSI_E)
        case .f: return UInt32(kVK_ANSI_F)
        case .g: return UInt32(kVK_ANSI_G)
        case .h: return UInt32(kVK_ANSI_H)
        case .i: return UInt32(kVK_ANSI_I)
        case .j: return UInt32(kVK_ANSI_J)
        case .k: return UInt32(kVK_ANSI_K)
        case .l: return UInt32(kVK_ANSI_L)
        case .m: return UInt32(kVK_ANSI_M)
        case .n: return UInt32(kVK_ANSI_N)
        case .o: return UInt32(kVK_ANSI_O)
        case .p: return UInt32(kVK_ANSI_P)
        case .q: return UInt32(kVK_ANSI_Q)
        case .r: return UInt32(kVK_ANSI_R)
        case .s: return UInt32(kVK_ANSI_S)
        case .t: return UInt32(kVK_ANSI_T)
        case .u: return UInt32(kVK_ANSI_U)
        case .v: return UInt32(kVK_ANSI_V)
        case .w: return UInt32(kVK_ANSI_W)
        case .x: return UInt32(kVK_ANSI_X)
        case .y: return UInt32(kVK_ANSI_Y)
        case .z: return UInt32(kVK_ANSI_Z)
        }
    }
}

private extension ShortcutModifiers {
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) {
            flags |= UInt32(cmdKey)
        }
        if contains(.option) {
            flags |= UInt32(optionKey)
        }
        if contains(.control) {
            flags |= UInt32(controlKey)
        }
        if contains(.shift) {
            flags |= UInt32(shiftKey)
        }
        return flags
    }
}
