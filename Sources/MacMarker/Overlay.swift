import AppKit

private final class MarkerPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class MarkerView: NSView {
    var strokes: [MarkStroke] = []
    var fade: Double = 0
    var screenOrigin = CGPoint.zero
    var quartzBaseline: CGFloat = 0

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard fade > 0 else { return }
        for stroke in strokes {
            guard let first = stroke.points.first else { continue }
            let style = stroke.style
            NSColor(srgbRed: style.red, green: style.green, blue: style.blue,
                    alpha: style.opacity * fade).set()
            func local(_ point: CGPoint) -> CGPoint {
                CGPoint(x: point.x - screenOrigin.x, y: quartzBaseline - point.y - screenOrigin.y)
            }
            let path = NSBezierPath()
            path.lineWidth = style.width
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            if stroke.points.count == 1 {
                let point = local(first)
                NSBezierPath(ovalIn: NSRect(x: point.x - style.width / 2, y: point.y - style.width / 2,
                                           width: style.width, height: style.width)).fill()
            } else {
                path.move(to: local(first))
                for point in stroke.points.dropFirst() { path.line(to: local(point)) }
                path.stroke()
            }
        }
    }
}

final class OverlayController {
    private var panels: [MarkerPanel] = []
    private var shown = false

    init() { rebuild() }

    func rebuild() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        shown = false
        // Quartz uses the upper left of the primary display; AppKit uses its
        // lower left. Other displays may have either negative X or negative Y.
        let baseline = NSScreen.screens.first?.frame.maxY ?? 0
        for screen in NSScreen.screens {
            let panel = MarkerPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                                    backing: .buffered, defer: false)
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            let view = MarkerView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.screenOrigin = screen.frame.origin
            view.quartzBaseline = baseline
            panel.contentView = view
            panel.setFrame(screen.frame, display: false)
            panels.append(panel)
        }
    }

    func render(_ session: MarkSession, at now: TimeInterval) {
        let fade = session.opacity(at: now)
        let shouldShow = !session.strokes.isEmpty && fade > 0
        for panel in panels {
            if let view = panel.contentView as? MarkerView {
                view.strokes = session.strokes
                view.fade = fade
                view.needsDisplay = true
            }
            if shouldShow && !shown { panel.orderFrontRegardless() }
            if !shouldShow && shown { panel.orderOut(nil) }
        }
        shown = shouldShow
    }
}
