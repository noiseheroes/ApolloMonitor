#!/usr/bin/env swift

// Generates macOS HIG-compliant app icon
// Design: Professional audio monitor knob on dark gradient background

import AppKit
import Foundation

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "./Assets.xcassets/AppIcon.appiconset"

// (filename, pixel size) — pixel dimensions must match exactly
let sizes: [(name: String, pixels: Int)] = [
    ("icon_16", 16),
    ("icon_16@2x", 32),
    ("icon_32", 32),
    ("icon_32@2x", 64),
    ("icon_128", 128),
    ("icon_128@2x", 256),
    ("icon_256", 256),
    ("icon_256@2x", 512),
    ("icon_512", 512),
    ("icon_512@2x", 1024),
    ("icon_1024", 1024),
]

func generateIcon(pixelSize: Int) -> Data? {
    let s = CGFloat(pixelSize)

    // Create bitmap at exact pixel dimensions (72 DPI, no retina scaling)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize) // 1:1 point-to-pixel

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high

    let center = NSPoint(x: s / 2, y: s / 2)

    // === 1. BACKGROUND SQUIRCLE ===
    let inset = s * 0.02
    let bgRect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = s * 0.22
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    let bgGradient = NSGradient(
        colorsAndLocations:
            (NSColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0), 0.0),
            (NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0), 1.0)
    )!
    bgGradient.draw(in: bgPath, angle: -90)

    NSColor(white: 1.0, alpha: 0.06).setStroke()
    bgPath.lineWidth = max(0.5, s * 0.003)
    bgPath.stroke()

    // === 2. OUTER RING ===
    let ringRadius = s * 0.30
    let ringPath = NSBezierPath()
    ringPath.appendArc(withCenter: center, radius: ringRadius, startAngle: 0, endAngle: 360)
    ringPath.lineWidth = s * 0.025
    NSColor(white: 1.0, alpha: 0.10).setStroke()
    ringPath.stroke()

    // === 3. KNOB BODY ===
    let knobRadius = s * 0.22
    let knobRect = NSRect(
        x: center.x - knobRadius, y: center.y - knobRadius,
        width: knobRadius * 2, height: knobRadius * 2
    )
    let knobPath = NSBezierPath(ovalIn: knobRect)

    let knobGradient = NSGradient(
        colorsAndLocations:
            (NSColor(white: 0.35, alpha: 1.0), 0.0),
            (NSColor(white: 0.18, alpha: 1.0), 1.0)
    )!
    knobGradient.draw(in: knobPath, angle: -90)

    NSColor(white: 1.0, alpha: 0.12).setStroke()
    knobPath.lineWidth = max(0.5, s * 0.004)
    knobPath.stroke()

    // === 4. INDICATOR LINE (~2 o'clock) ===
    let indicatorAngle: CGFloat = 60 * .pi / 180
    let lineStart = NSPoint(
        x: center.x + sin(indicatorAngle) * s * 0.10,
        y: center.y + cos(indicatorAngle) * s * 0.10
    )
    let lineEnd = NSPoint(
        x: center.x + sin(indicatorAngle) * s * 0.20,
        y: center.y + cos(indicatorAngle) * s * 0.20
    )
    let linePath = NSBezierPath()
    linePath.move(to: lineStart)
    linePath.line(to: lineEnd)
    linePath.lineWidth = max(1, s * 0.018)
    linePath.lineCapStyle = .round
    NSColor.white.setStroke()
    linePath.stroke()

    // === 5. CENTER DOT ===
    let dotRadius = s * 0.025
    let dotRect = NSRect(
        x: center.x - dotRadius, y: center.y - dotRadius,
        width: dotRadius * 2, height: dotRadius * 2
    )
    NSColor(white: 1.0, alpha: 0.6).setFill()
    NSBezierPath(ovalIn: dotRect).fill()

    // === 6. TICK MARKS ===
    let tickCount = 11
    let startAngleDeg: CGFloat = -240
    let endAngleDeg: CGFloat = 60
    let tickInner = s * 0.33
    let tickOuter = s * 0.37

    for i in 0..<tickCount {
        let t = CGFloat(i) / CGFloat(tickCount - 1)
        let angleDeg = startAngleDeg + t * (endAngleDeg - startAngleDeg)
        let angleRad = angleDeg * .pi / 180

        let inner = NSPoint(
            x: center.x + cos(angleRad) * tickInner,
            y: center.y + sin(angleRad) * tickInner
        )
        let outer = NSPoint(
            x: center.x + cos(angleRad) * tickOuter,
            y: center.y + sin(angleRad) * tickOuter
        )

        let tickPath = NSBezierPath()
        tickPath.move(to: inner)
        tickPath.line(to: outer)

        let isMajor = (i % 5 == 0)
        tickPath.lineWidth = isMajor ? max(1, s * 0.012) : max(0.5, s * 0.006)
        tickPath.lineCapStyle = .round
        NSColor(white: 1.0, alpha: isMajor ? 0.7 : 0.35).setStroke()
        tickPath.stroke()
    }

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])
}

// Generate all sizes
print("Generating macOS app icons...")
for (name, pixels) in sizes {
    guard let pngData = generateIcon(pixelSize: pixels) else {
        print("  ✗ Failed: \(name)")
        continue
    }
    let path = "\(outputDir)/\(name).png"
    try! pngData.write(to: URL(fileURLWithPath: path))
    print("  ✓ \(name).png (\(pixels)x\(pixels)px)")
}
print("Done!")
