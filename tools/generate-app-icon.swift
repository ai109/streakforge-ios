#!/usr/bin/env swift

//
//  generate-app-icon.swift
//  Generates the three 1024x1024 PNGs for AppIcon.appiconset.
//
//  Usage:  swift tools/generate-app-icon.swift <output-dir>
//
//  Run once to materialize StreakForge/Assets.xcassets/AppIcon.appiconset/
//  AppIcon-{Light,Dark,Tinted}.png. The script lives under tools/ rather
//  than in the app target so it never ships in the binary.
//

import AppKit
import Foundation

// MARK: Renderer

func renderIcon(
    background: (NSColor, NSColor),
    symbolColor: NSColor,
    pointSize: CGFloat,
    canvasSize: CGFloat = 1024,
    outputURL: URL
) {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize),
        pixelsHigh: Int(canvasSize),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        FileHandle.standardError.write("Failed to create bitmap rep\n".data(using: .utf8)!)
        return
    }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    // Background — vertical gradient, top to bottom.
    let gradient = NSGradient(colors: [background.0, background.1])!
    gradient.draw(in: NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize), angle: 270)

    // Flame SF Symbol, tinted via sourceIn so it always paints solid color
    // regardless of how the system would render the template by default.
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .black)
    if let raw = NSImage(systemSymbolName: "flame.fill", accessibilityDescription: nil),
       let configured = raw.withSymbolConfiguration(config) {

        let symbolSize = configured.size
        let tinted = NSImage(size: symbolSize)
        tinted.lockFocus()
        symbolColor.set()
        let symbolBounds = NSRect(origin: .zero, size: symbolSize)
        configured.draw(in: symbolBounds)
        // .sourceIn keeps only the pixels where the symbol drew anything,
        // painted in the currently-set color. This is the reliable way
        // to recolor a template image on macOS.
        symbolBounds.fill(using: .sourceIn)
        tinted.unlockFocus()

        let drawRect = NSRect(
            x: (canvasSize - symbolSize.width) / 2,
            y: (canvasSize - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        tinted.draw(in: drawRect)
    }

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("Failed to encode PNG\n".data(using: .utf8)!)
        return
    }

    do {
        try pngData.write(to: outputURL)
        print("Wrote \(outputURL.path)")
    } catch {
        FileHandle.standardError.write("Write failed: \(error)\n".data(using: .utf8)!)
    }
}

// MARK: Main

let outputDir = CommandLine.arguments.dropFirst().first
    .map { URL(fileURLWithPath: $0) }
    ?? URL(fileURLWithPath: ".")

// Match AppColors.primary / .primaryPressed (light variant).
let brandPrimary = NSColor(srgbRed: 1.00, green: 0.42, blue: 0.21, alpha: 1.0)  // 0xFF6B35
let brandPressed = NSColor(srgbRed: 0.91, green: 0.34, blue: 0.15, alpha: 1.0)  // 0xE85826

renderIcon(
    background: (brandPrimary, brandPressed),
    symbolColor: .white,
    pointSize: 600,
    outputURL: outputDir.appendingPathComponent("AppIcon-Light.png")
)

// Dark mode icon: deep warm-charcoal background, flame in the dark-mode
// brand orange (matches AppColors.primary's dark variant).
let darkBgTop    = NSColor(srgbRed: 0.18, green: 0.10, blue: 0.06, alpha: 1.0)
let darkBgBottom = NSColor(srgbRed: 0.06, green: 0.03, blue: 0.02, alpha: 1.0)
let darkSymbol   = NSColor(srgbRed: 1.00, green: 0.52, blue: 0.32, alpha: 1.0)  // 0xFF8552

renderIcon(
    background: (darkBgTop, darkBgBottom),
    symbolColor: darkSymbol,
    pointSize: 600,
    outputURL: outputDir.appendingPathComponent("AppIcon-Dark.png")
)

// iOS 18 tinted icon: monochrome on dark background; the system tints
// the white pixels with the user's wallpaper-extracted color.
renderIcon(
    background: (NSColor(white: 0.08, alpha: 1.0), NSColor(white: 0.02, alpha: 1.0)),
    symbolColor: .white,
    pointSize: 600,
    outputURL: outputDir.appendingPathComponent("AppIcon-Tinted.png")
)
