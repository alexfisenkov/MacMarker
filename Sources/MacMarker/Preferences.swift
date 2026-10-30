import AppKit

struct Shortcut: Codable, Equatable {
    static let commandMask: UInt64 = CGEventFlags.maskCommand.rawValue
    static let shiftMask: UInt64 = CGEventFlags.maskShift.rawValue
    static let optionMask: UInt64 = CGEventFlags.maskAlternate.rawValue
    static let controlMask: UInt64 = CGEventFlags.maskControl.rawValue
    static let functionMask: UInt64 = CGEventFlags.maskSecondaryFn.rawValue
    static let modifierMask = commandMask | shiftMask | optionMask | controlMask | functionMask
    static let defaultShortcut = Shortcut(keyCode: 61, modifiers: optionMask, modifierOnly: true)
    static let modifierKeys: Set<UInt16> = [54, 55, 56, 57, 60, 58, 61, 59, 62, 63]

    var keyCode: UInt16
    var modifiers: UInt64
    var modifierOnly: Bool

    func matches(keyCode: UInt16, modifiers: UInt64) -> Bool {
        guard self.keyCode == keyCode else { return false }
        let actual = modifiers & Self.modifierMask
        return modifierOnly ? actual & self.modifiers == self.modifiers : self.modifiers == actual
    }

    static func modifierFlag(for code: UInt16) -> UInt64 {
        switch code {
        case 54, 55: return commandMask
        case 56, 60: return shiftMask
        case 58, 61: return optionMask
        case 59, 62: return controlMask
        case 63: return functionMask
        default: return 0
        }
    }

    var displayName: String {
        let flags = modifiers & Self.modifierMask & (modifierOnly ? ~Self.modifierFlag(for: keyCode) : UInt64.max)
        return (flags & Self.controlMask != 0 ? "⌃" : "")
            + (flags & Self.optionMask != 0 ? "⌥" : "")
            + (flags & Self.shiftMask != 0 ? "⇧" : "")
            + (flags & Self.commandMask != 0 ? "⌘" : "")
            + (flags & Self.functionMask != 0 ? "Fn+" : "")
            + Self.keyName(keyCode)
    }

    static func keyName(_ code: UInt16) -> String {
        let names: [UInt16: String] = [
            0:"A", 1:"S", 2:"D", 3:"F", 4:"H", 5:"G", 6:"Z", 7:"X", 8:"C", 9:"V", 11:"B",
            12:"Q", 13:"W", 14:"E", 15:"R", 16:"Y", 17:"T", 18:"1", 19:"2", 20:"3", 21:"4",
            22:"6", 23:"5", 24:"=", 25:"9", 26:"7", 27:"−", 28:"8", 29:"0", 30:"]", 31:"O",
            32:"U", 33:"[", 34:"I", 35:"P", 36:"Return", 37:"L", 38:"J", 39:"'", 40:"K", 41:";",
            42:"\\", 43:",", 44:"/", 45:"N", 46:"M", 47:".", 48:"Tab", 49:"Space", 50:"`",
            51:"⌫", 53:"Escape", 54:"Правый Command ⌘", 55:"Левый Command ⌘",
            56:"Левый Shift ⇧", 57:"Caps Lock", 58:"Левый Option ⌥", 59:"Левый Control ⌃",
            60:"Правый Shift ⇧", 61:"Правый Option ⌥", 62:"Правый Control ⌃", 63:"Fn / 🌐",
            65:"Keypad .", 67:"Keypad *", 69:"Keypad +", 71:"Keypad Clear", 75:"Keypad /", 76:"Keypad Enter",
            78:"Keypad −", 81:"Keypad =", 82:"Keypad 0", 83:"Keypad 1", 84:"Keypad 2", 85:"Keypad 3",
            86:"Keypad 4", 87:"Keypad 5", 88:"Keypad 6", 89:"Keypad 7", 91:"Keypad 8", 92:"Keypad 9",
            96:"F5", 97:"F6", 98:"F7", 99:"F3", 100:"F8", 101:"F9", 103:"F11", 105:"F13",
            106:"F16", 107:"F14", 109:"F10", 111:"F12", 113:"F15", 114:"Help", 115:"Home",
            116:"Page Up", 117:"⌦", 118:"F4", 119:"End", 120:"F2", 121:"Page Down", 122:"F1",
            123:"←", 124:"→", 125:"↓", 126:"↑"
        ]
        return names[code] ?? "Клавиша \(code)"
    }
}

final class Preferences {
    private let defaults = UserDefaults.standard
    var onChange: (() -> Void)?
    var isEnabled: Bool { didSet { save() } }
    var color: NSColor { didSet { save() } }
    var opacity: Double { didSet { save() } }
    var width: Double { didSet { save() } }
    var shortcut: Shortcut { didSet { save() } }

    init() {
        isEnabled = defaults.object(forKey: "markerEnabled") as? Bool ?? true
        let stored = defaults.dictionary(forKey: "markerColor")
        color = NSColor(srgbRed: stored?["r"] as? Double ?? 1,
                        green: stored?["g"] as? Double ?? 0.74,
                        blue: stored?["b"] as? Double ?? 0.05, alpha: 1)
        opacity = defaults.object(forKey: "markerOpacity") == nil ? 0.85 : min(1, max(0, defaults.double(forKey: "markerOpacity")))
        width = defaults.object(forKey: "markerWidth") == nil ? 5 : min(100, max(1, defaults.double(forKey: "markerWidth")))
        if let data = defaults.data(forKey: "markerShortcut"), let value = try? JSONDecoder().decode(Shortcut.self, from: data) {
            shortcut = value
        } else { shortcut = .defaultShortcut }
    }

    var style: MarkStyle {
        let rgb = color.usingColorSpace(.sRGB) ?? .systemYellow
        return MarkStyle(red: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent,
                         opacity: opacity, width: width)
    }

    private func save() {
        defaults.set(isEnabled, forKey: "markerEnabled")
        let rgb = color.usingColorSpace(.sRGB) ?? .systemYellow
        defaults.set(["r": rgb.redComponent, "g": rgb.greenComponent, "b": rgb.blueComponent], forKey: "markerColor")
        defaults.set(opacity, forKey: "markerOpacity")
        defaults.set(width, forKey: "markerWidth")
        if let data = try? JSONEncoder().encode(shortcut) { defaults.set(data, forKey: "markerShortcut") }
        onChange?()
    }
}
