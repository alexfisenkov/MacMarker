import CoreGraphics

/// Sidecar pointer events can clear the merged HID Fn snapshot while the key
/// is still physically held. Only Fn's own keyboard edges own this state.
struct FunctionKeyState {
    static let keyCode: UInt16 = 63
    private(set) var isDown = false

    mutating func observe(type: CGEventType, keyCode: UInt16, flags: CGEventFlags) {
        guard type == .flagsChanged, keyCode == Self.keyCode else { return }
        isDown = flags.contains(.maskSecondaryFn)
    }

    func replacingFunctionFlag(in flags: UInt64) -> UInt64 {
        let mask = CGEventFlags.maskSecondaryFn.rawValue
        return (flags & ~mask) | (isDown ? mask : 0)
    }

    mutating func reset() { isDown = false }
}
