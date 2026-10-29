import AppKit
import ApplicationServices

private let markerTapCallback: CGEventTapCallBack = { _, type, event, context in
    guard let context else { return Unmanaged.passUnretained(event) }
    let controller = Unmanaged<InputController>.fromOpaque(context).takeUnretainedValue()
    return controller.handle(type: type, event: event) ? nil : Unmanaged.passUnretained(event)
}

final class InputController {
    let preferences: Preferences
    private let overlay: OverlayController
    private var session = MarkSession()
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var timer: Timer?
    private var localMonitor: Any?
    private var lastPermissionCheck: TimeInterval = 0
    private var capturedButtons: Set<Int64> = []
    private var suppressedKeys: Set<UInt16> = []
    private var suppressedModifiers: Set<UInt16> = []
    private var pendingModifier: UInt16?
    private var recordedModifierFlags: UInt64 = 0
    private var requiresRelease = true
    private(set) var isRecording = false
    private(set) var isAvailable = false
    private(set) var statusText = "Нужен доступ «Универсальный доступ»"
    var onStatusChanged: (() -> Void)?
    var onRecordingChanged: ((Bool) -> Void)?

    init(preferences: Preferences, overlay: OverlayController) {
        self.preferences = preferences
        self.overlay = overlay
    }

    func start() {
        retryPermission()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.tick() }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            guard let self, self.isRecording, self.tap == nil, let cgEvent = event.cgEvent else { return event }
            return self.handle(type: cgEvent.type, event: cgEvent) ? nil : event
        }
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.didActivateApplicationNotification] {
            workspace.addObserver(self, selector: #selector(environmentChanged), name: name, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
                                                name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func retryPermission(prompt: Bool = false) {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
        guard AXIsProcessTrusted() else {
            removeTap()
            setStatus(available: false, text: "Разрешите MacMarker в «Универсальный доступ»")
            return
        }
        guard tap == nil else { return }
        let types: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .leftMouseDown, .leftMouseUp,
                                   .leftMouseDragged, .rightMouseDown, .rightMouseUp, .rightMouseDragged,
                                   .otherMouseDown, .otherMouseUp, .otherMouseDragged, .scrollWheel]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let created = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                              options: .defaultTap, eventsOfInterest: mask,
                                              callback: markerTapCallback,
                                              userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            setStatus(available: false, text: "Перехват недоступен — проверьте разрешение и повторите")
            return
        }
        tap = created
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, created, 0)
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
        CGEvent.tapEnable(tap: created, enable: true)
        requiresRelease = true
        setStatus(available: true, text: "Готов · удерживайте \(preferences.shortcut.displayName)")
    }

    func preferencesChanged() {
        failOpen()
        if isAvailable { setStatus(available: true, text: "Готов · удерживайте \(preferences.shortcut.displayName)") }
    }

    func beginRecording() {
        failOpen()
        pendingModifier = nil
        recordedModifierFlags = 0
        isRecording = true
        onRecordingChanged?(true)
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        pendingModifier = nil
        requiresRelease = true
        onRecordingChanged?(false)
    }

    func failOpen() {
        session.clear()
        requiresRelease = true
        overlay.render(session, at: ProcessInfo.processInfo.systemUptime)
    }

    @objc private func environmentChanged() { stopRecording(); failOpen() }

    @objc private func screensChanged() {
        failOpen()
        overlay.rebuild()
    }

    private func removeTap() {
        failOpen()
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
        // Once the tap is removed, no further input can be swallowed.
        capturedButtons.removeAll()
        suppressedKeys.removeAll()
        suppressedModifiers.removeAll()
    }

    private func setStatus(available: Bool, text: String) {
        guard isAvailable != available || statusText != text else { return }
        isAvailable = available
        statusText = text
        onStatusChanged?()
    }

    private func physicallyHeld(_ shortcut: Shortcut) -> Bool {
        guard CGEventSource.keyState(.hidSystemState, key: shortcut.keyCode) else { return false }
        let flags = physicalModifierFlags(CGEventSource.flagsState(.hidSystemState).rawValue)
        return shortcut.matches(keyCode: shortcut.keyCode, modifiers: flags)
    }

    private func physicalModifierFlags(_ flags: UInt64) -> UInt64 {
        // Navigation keys carry the function flag even without physical Fn.
        let ordinary = flags & Shortcut.modifierMask & ~Shortcut.functionMask
        return ordinary | (CGEventSource.keyState(.hidSystemState, key: 63) ? Shortcut.functionMask : 0)
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastPermissionCheck >= 1 {
            lastPermissionCheck = now
            retryPermission()
        }
        if let tap, !CGEvent.tapIsEnabled(tap: tap) {
            failOpen()
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        let held = physicallyHeld(preferences.shortcut)
        if !held { requiresRelease = false }
        if session.isHolding && !held { session.release(at: now) }
        session.tick(at: now)
        overlay.render(session, at: now)
    }

    private func commitShortcut(_ shortcut: Shortcut) {
        stopRecording()
        preferences.shortcut = shortcut
        requiresRelease = true
    }

    private func record(type: CGEventType, event: CGEvent, code: UInt16) -> Bool {
        if type == .keyDown {
            suppressedKeys.insert(code)
            if code == 53 { stopRecording(); return true }
            if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                commitShortcut(Shortcut(keyCode: code, modifiers: physicalModifierFlags(event.flags.rawValue),
                                        modifierOnly: false))
            }
        } else if type == .flagsChanged, Shortcut.modifierKeys.contains(code) {
            if code == 57 {
                commitShortcut(Shortcut(keyCode: code, modifiers: 0, modifierOnly: true))
                return true
            }
            if CGEventSource.keyState(.hidSystemState, key: code) {
                pendingModifier = code
                recordedModifierFlags |= physicalModifierFlags(event.flags.rawValue)
                suppressedModifiers.insert(code)
            } else if pendingModifier == code {
                suppressedModifiers.remove(code)
                commitShortcut(Shortcut(keyCode: code, modifiers: recordedModifierFlags,
                                        modifierOnly: true))
            }
        } else if type == .keyUp { suppressedKeys.remove(code) }
        return true
    }

    /// true consumes the event. All mutation and rendering run on the main loop.
    func handle(type: CGEventType, event: CGEvent) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            failOpen()
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        }
        let keyboard = type == .keyDown || type == .keyUp || type == .flagsChanged
        let code = UInt16(clamping: event.getIntegerValueField(.keyboardEventKeycode))
        if keyboard && isRecording { return record(type: type, event: event, code: code) }
        let now = ProcessInfo.processInfo.systemUptime
        if type == .keyUp, suppressedKeys.remove(code) != nil {
            if code == preferences.shortcut.keyCode { session.release(at: now) }
            return true
        }
        if type == .flagsChanged, suppressedModifiers.contains(code),
           !CGEventSource.keyState(.hidSystemState, key: code) {
            suppressedModifiers.remove(code)
            if code == preferences.shortcut.keyCode { session.release(at: now) }
            return true
        }
        guard isAvailable else { return false }
        let shortcut = preferences.shortcut
        let held = physicallyHeld(shortcut)
        if !held {
            requiresRelease = false
            if session.isHolding { session.release(at: now) }
        }
        let isTrigger = shortcut.matches(keyCode: code, modifiers: physicalModifierFlags(event.flags.rawValue))
        if keyboard && !requiresRelease && held && isTrigger && (type == .keyDown || type == .flagsChanged) {
            if !session.isHolding { session.beginHold() }
            if type == .keyDown { suppressedKeys.insert(code) }
            else { suppressedModifiers.insert(code) }
            return true
        }
        if session.isHolding && keyboard {
            if type == .keyDown {
                suppressedKeys.insert(code)
                if code == 53 { failOpen() }
            }
            // Do not forward typed keys or modifier changes to the foreground app.
            if type == .flagsChanged { suppressedModifiers.insert(code) }
            return true
        }
        let down = type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown
        let drag = type == .leftMouseDragged || type == .rightMouseDragged || type == .otherMouseDragged
        let up = type == .leftMouseUp || type == .rightMouseUp || type == .otherMouseUp
        let button = event.getIntegerValueField(.mouseEventButtonNumber)
        if up && capturedButtons.remove(button) != nil {
            session.finishStroke()
            return true
        }
        if drag && capturedButtons.contains(button) && !session.isHolding { return true }
        guard session.capturesInput else { return false }
        if down {
            capturedButtons.insert(button)
            session.beginStroke(at: event.location, style: preferences.style)
        } else if drag {
            session.appendPoint(event.location)
        } else if up { session.finishStroke() }
        if down || drag || up {
            overlay.render(session, at: now)
            return true
        }
        return type == .scrollWheel
    }
}
