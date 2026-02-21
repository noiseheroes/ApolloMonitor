#!/usr/bin/env swift

// Generates DMG installer background images
// Clean, professional dark design

import AppKit
import Foundation

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "./Installer"

let version = "v1.0.0"

func generateBackground(width: Int, height: Int) -> Data? {
    let w = CGFloat(width)
    let h = CGFloat(height)

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.shouldAntialias = true
    ctx.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: w, height: h)

    // Background gradient: dark, professional
    let bgGradient = NSGradient(
        colorsAndLocations:
            (NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0), 0.0),
            (NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0), 1.0)
    )!
    bgGradient.draw(in: rect, angle: -90)

    // Subtle top highlight line
    let topLine = NSBezierPath()
    topLine.move(to: NSPoint(x: 0, y: h - 1))
    topLine.line(to: NSPoint(x: w, y: h - 1))
    topLine.lineWidth = 1
    NSColor(white: 1.0, alpha: 0.04).setStroke()
    topLine.stroke()

    // Title: "Apollo Monitor"
    let titleFont = NSFont.systemFont(ofSize: w * 0.056, weight: .light)
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.9),
    ]
    let title = "Apollo Monitor" as NSString
    let titleSize = title.size(withAttributes: titleAttrs)
    title.draw(at: NSPoint(x: (w - titleSize.width) / 2, y: h * 0.80), withAttributes: titleAttrs)

    // Subtitle
    let subFont = NSFont.systemFont(ofSize: w * 0.026, weight: .regular)
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: subFont,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.35),
    ]
    let subtitle = "Control your Apollo monitor from anywhere" as NSString
    let subSize = subtitle.size(withAttributes: subAttrs)
    subtitle.draw(at: NSPoint(x: (w - subSize.width) / 2, y: h * 0.74), withAttributes: subAttrs)

    // Arrow dots (drag indicator) — centered vertically in the icon area
    let arrowY = h * 0.46
    let dotCount = 9
    let dotSpacing = w * 0.025
    let dotRadius = w * 0.005
    let totalDotsWidth = CGFloat(dotCount - 1) * dotSpacing
    let startX = (w - totalDotsWidth) / 2 - w * 0.04

    for i in 0..<dotCount {
        let x = startX + CGFloat(i) * dotSpacing
        let alpha = 0.15 + Double(i) / Double(dotCount) * 0.25
        NSColor(white: 1.0, alpha: alpha).setFill()
        let dotRect = NSRect(x: x - dotRadius, y: arrowY - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
        NSBezierPath(ovalIn: dotRect).fill()
    }

    // Arrow head
    let arrowX = startX + CGFloat(dotCount) * dotSpacing
    let arrowSize = w * 0.016
    let arrowPath = NSBezierPath()
    arrowPath.move(to: NSPoint(x: arrowX, y: arrowY - arrowSize))
    arrowPath.line(to: NSPoint(x: arrowX + arrowSize, y: arrowY))
    arrowPath.line(to: NSPoint(x: arrowX, y: arrowY + arrowSize))
    arrowPath.close()
    NSColor(white: 1.0, alpha: 0.35).setFill()
    arrowPath.fill()

    // "Drag to Applications folder"
    let instrFont = NSFont.systemFont(ofSize: w * 0.024, weight: .regular)
    let instrAttrs: [NSAttributedString.Key: Any] = [
        .font: instrFont,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.25),
    ]
    let instr = "Drag to Applications folder" as NSString
    let instrSize = instr.size(withAttributes: instrAttrs)
    instr.draw(at: NSPoint(x: (w - instrSize.width) / 2, y: h * 0.14), withAttributes: instrAttrs)

    // Version number (bottom right)
    let verFont = NSFont.monospacedSystemFont(ofSize: w * 0.020, weight: .regular)
    let verAttrs: [NSAttributedString.Key: Any] = [
        .font: verFont,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.18),
    ]
    let ver = version as NSString
    let verSize = ver.size(withAttributes: verAttrs)
    ver.draw(at: NSPoint(x: w - verSize.width - w * 0.04, y: h * 0.04), withAttributes: verAttrs)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

print("Generating DMG background images...")

if let data = generateBackground(width: 540, height: 380) {
    try! data.write(to: URL(fileURLWithPath: "\(outputDir)/background.png"))
    print("  ✓ background.png (540x380)")
}

if let data = generateBackground(width: 1080, height: 760) {
    try! data.write(to: URL(fileURLWithPath: "\(outputDir)/background@2x.png"))
    print("  ✓ background@2x.png (1080x760)")
}

print("Done!")
