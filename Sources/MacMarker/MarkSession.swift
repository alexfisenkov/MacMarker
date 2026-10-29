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
    func check(_ value: @autoclosure () -> Bool, _ name: String) {
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
    if failures.isEmpty {
        print("PASS: hold, release, 1.4s fade, rehold, fail-open and physical shortcut matching (12 checks)")
    } else {
        failures.forEach { print("FAIL: \($0)") }
    }
    return failures.isEmpty
}
