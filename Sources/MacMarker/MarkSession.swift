import CoreGraphics
import Foundation

struct MarkStyle {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    var width: Double
}

struct MarkStroke {
    var points: [CGPoint]
    let style: MarkStyle
}

/// The rendering clock is the only fade owner: there is no delayed completion
/// callback that could clear strokes from a newer hold.
struct MarkSession {
    static let fadeDuration: TimeInterval = 1.4
    private(set) var isHolding = false
    private(set) var strokes: [MarkStroke] = []
    private var currentStroke: Int?
    private var releasedAt: TimeInterval?

    var capturesInput: Bool { isHolding }

    mutating func beginHold() {
        isHolding = true
        releasedAt = nil
        currentStroke = nil
    }

    mutating func beginStroke(at point: CGPoint, style: MarkStyle) {
        guard isHolding else { return }
        strokes.append(MarkStroke(points: [point], style: style))
        currentStroke = strokes.count - 1
    }

    mutating func appendPoint(_ point: CGPoint) {
        guard isHolding, let index = currentStroke else { return }
        if let last = strokes[index].points.last,
           hypot(point.x - last.x, point.y - last.y) < 0.35 { return }
        strokes[index].points.append(point)
    }

    mutating func finishStroke() { currentStroke = nil }

    mutating func release(at now: TimeInterval) {
        guard isHolding else { return }
        isHolding = false
        currentStroke = nil
        releasedAt = now
    }

    func opacity(at now: TimeInterval) -> Double {
        if isHolding { return 1 }
        guard let releasedAt else { return 0 }
        return min(1, max(0, 1 - (now - releasedAt) / Self.fadeDuration))
    }

    mutating func tick(at now: TimeInterval) {
        if !isHolding, releasedAt != nil, opacity(at: now) == 0 { clear() }
    }

    mutating func clear() {
        isHolding = false
        currentStroke = nil
        releasedAt = nil
        strokes.removeAll(keepingCapacity: false)
    }
}

func runSelfTest() -> Bool {
    var failures: [String] = []
    var checks = 0
    func check(_ value: @autoclosure () -> Bool, _ name: String) {
        checks += 1
        if !value() { failures.append(name) }
    }
    let style = MarkStyle(red: 1, green: 0.8, blue: 0, opacity: 0.85, width: 5)
    var session = MarkSession()
    check(!session.capturesInput, "idle must pass input through")
    session.beginStroke(at: .zero, style: style)
    check(session.strokes.isEmpty, "idle must not create marks")
    session.beginHold()
    session.beginStroke(at: .zero, style: style)
    session.appendPoint(CGPoint(x: 10, y: 20))
    session.finishStroke()
    session.tick(at: 100)
    check(session.strokes.count == 1 && session.opacity(at: 100) == 1,
          "marks must remain fully visible for the whole hold")
    session.release(at: 100)
    check(!session.capturesInput, "release must immediately restore input")
    check(abs(session.opacity(at: 100.7) - 0.5) < 0.0001, "fade must last 1.4 seconds")
    session.beginHold()
    session.beginStroke(at: CGPoint(x: 50, y: 50), style: style)
    session.tick(at: 102)
    check(session.strokes.count == 2 && session.opacity(at: 102) == 1,
          "an older fade must not remove a new hold")
    session.release(at: 102)
    session.tick(at: 104)
    check(session.strokes.isEmpty && !session.capturesInput, "completed fade must clear marks")
    session.beginHold()
    session.clear()
    check(!session.capturesInput, "permission loss must fail open")
    check(Shortcut.defaultShortcut.matches(keyCode: 61, modifiers: Shortcut.optionMask),
          "default shortcut must be right Option")
    check(!Shortcut.defaultShortcut.matches(keyCode: 58, modifiers: Shortcut.optionMask),
          "left Option must not match right Option")
    let chord = Shortcut(keyCode: 8, modifiers: Shortcut.commandMask | Shortcut.shiftMask, modifierOnly: false)
    check(chord.matches(keyCode: 8, modifiers: Shortcut.commandMask | Shortcut.shiftMask), "chord must match")
    check(!chord.matches(keyCode: 8, modifiers: Shortcut.commandMask), "missing modifier must not match")

    // Observed failure: Fn down, then Sidecar proximity/down/1107 drags with
    // event Fn=0 and merged HID Fn/key=0, with no intervening Fn keyboard up.
    var functionKey = FunctionKeyState()
    check(!functionKey.isDown, "Fn must start released")
    functionKey.observe(type: .flagsChanged, keyCode: 63, flags: .maskSecondaryFn)
    check(functionKey.isDown, "Fn's own down edge must latch")
    let fnShortcut = Shortcut(keyCode: 63, modifiers: Shortcut.functionMask, modifierOnly: true)
    check(fnShortcut.matches(keyCode: 63, modifiers: functionKey.replacingFunctionFlag(in: 0)),
          "cleared HID flags must not release a latched Fn shortcut")
    session.beginHold()
    functionKey.observe(type: .tabletProximity, keyCode: 63, flags: [])
    functionKey.observe(type: .leftMouseDown, keyCode: 63, flags: [])
    session.beginStroke(at: .zero, style: style)
    for index in 1...1107 {
        functionKey.observe(type: .leftMouseDragged, keyCode: 63, flags: [])
        session.appendPoint(CGPoint(x: index, y: 10))
        if !functionKey.isDown { session.release(at: 200) }
        session.tick(at: 300)
    }
    check(functionKey.isDown && session.capturesInput && session.strokes.count == 1
          && session.strokes[0].points.count == 1108 && session.opacity(at: 300) == 1,
          "Sidecar proximity/down/drags must retain Fn capture and marks")
    functionKey.observe(type: .flagsChanged, keyCode: 56, flags: [])
    functionKey.observe(type: .keyUp, keyCode: 63, flags: [])
    check(functionKey.isDown, "unrelated keyboard events must not release Fn")
    let otherBits = CGEventFlags.maskShift.rawValue | CGEventFlags.maskCommand.rawValue
        | CGEventFlags.maskAlphaShift.rawValue
    check(functionKey.replacingFunctionFlag(in: otherBits) == otherBits | Shortcut.functionMask,
          "Fn substitution must preserve every other modifier bit")
    functionKey.observe(type: .flagsChanged, keyCode: 63, flags: [])
    if !functionKey.isDown { session.release(at: 300) }
    check(!functionKey.isDown && !session.capturesInput && session.opacity(at: 300) == 1,
          "Fn's actual up edge must immediately restore input and start fading")
    functionKey.observe(type: .flagsChanged, keyCode: 63, flags: .maskSecondaryFn)
    session.beginHold()
    functionKey.reset()
    session.clear()
    functionKey.observe(type: .leftMouseDragged, keyCode: 63, flags: .maskSecondaryFn)
    check(!functionKey.isDown && !session.capturesInput,
          "pause/fail-open reset must not resurrect a prior Fn hold from pointer flags")
    check(functionKey.replacingFunctionFlag(in: otherBits | Shortcut.functionMask) == otherBits,
          "a reset Fn latch must remove only the Fn bit")
    if failures.isEmpty {
        print("PASS: hold, release, 1.4s fade, rehold, fail-open, shortcuts and Sidecar Fn regression (\(checks) checks)")
    } else {
        failures.forEach { print("FAIL: \($0)") }
    }
    return failures.isEmpty
}
