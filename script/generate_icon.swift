import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate_icon.swift <iconset-directory>\n", stderr)
    exit(2)
}

let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fileManager = FileManager.default
try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
}

func renderIcon(pixels: Int) throws -> Data {
    let dimension = CGFloat(pixels)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "MacMarkerIcon", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    let bounds = CGRect(x: 0, y: 0, width: dimension, height: dimension)
    color(0.07, 0.10, 0.15).setFill()
    NSBezierPath(roundedRect: bounds.insetBy(dx: dimension * 0.035, dy: dimension * 0.035), xRadius: dimension * 0.23, yRadius: dimension * 0.23).fill()

    let glow = NSBezierPath()
    glow.move(to: CGPoint(x: dimension * 0.22, y: dimension * 0.30))
    glow.curve(to: CGPoint(x: dimension * 0.77, y: dimension * 0.68), controlPoint1: CGPoint(x: dimension * 0.36, y: dimension * 0.49), controlPoint2: CGPoint(x: dimension * 0.57, y: dimension * 0.18))
    color(0.18, 0.25, 0.33).setStroke()
    glow.lineWidth = dimension * 0.15
    glow.lineCapStyle = .round
    glow.stroke()

    let mark = NSBezierPath()
    mark.move(to: CGPoint(x: dimension * 0.23, y: dimension * 0.35))
    mark.curve(to: CGPoint(x: dimension * 0.75, y: dimension * 0.72), controlPoint1: CGPoint(x: dimension * 0.39, y: dimension * 0.51), controlPoint2: CGPoint(x: dimension * 0.61, y: dimension * 0.48))
    color(1.0, 0.68, 0.20).setStroke()
    mark.lineWidth = dimension * 0.075
    mark.lineCapStyle = .round
    mark.stroke()

    let pencil = NSBezierPath()
    pencil.move(to: CGPoint(x: dimension * 0.48, y: dimension * 0.72))
    pencil.line(to: CGPoint(x: dimension * 0.73, y: dimension * 0.47))
    color(0.96, 0.97, 0.98).setStroke()
    pencil.lineWidth = dimension * 0.095
    pencil.lineCapStyle = .round
    pencil.stroke()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MacMarkerIcon", code: 2)
    }
    return data
}

let iconSizes: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for (name, pixels) in iconSizes {
    try renderIcon(pixels: pixels).write(to: destination.appendingPathComponent(name), options: .atomic)
}
