import AppKit
import CoreGraphics
import Foundation

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Failed to create CGContext")
}

// 1. macOS Squircle bounds (Apple squircle approximation)
let inset: CGFloat = 80
let rect = CGRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
let cornerRadius: CGFloat = 190
let squirclePath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Drop shadow for the squircle
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -20), blur: 40, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
context.addPath(squirclePath)
context.setFillColor(CGColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0))
context.fillPath()
context.restoreGState()

// Clip to squircle for inner drawing
context.saveGState()
context.addPath(squirclePath)
context.clip()

// 2. Base Dark Gradient (Midnight Navy -> Deep Violet)
let bgGradientColors = [
    CGColor(red: 0.06, green: 0.08, blue: 0.18, alpha: 1.0), // Top: Deep Cosmic Blue
    CGColor(red: 0.14, green: 0.06, blue: 0.28, alpha: 1.0), // Mid: Mystic Violet
    CGColor(red: 0.03, green: 0.02, blue: 0.08, alpha: 1.0)  // Bottom: Obsidian
] as CFArray
let bgLocations: [CGFloat] = [0.0, 0.6, 1.0]
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgGradientColors, locations: bgLocations) {
    context.drawLinearGradient(
        bgGradient,
        start: CGPoint(x: CGFloat(size)/2, y: CGFloat(size) - inset),
        end: CGPoint(x: CGFloat(size)/2, y: inset),
        options: []
    )
}

// 3. Glowing Aurora Radial Blooms
if let auroraGrad1 = CGGradient(
    colorsSpace: colorSpace,
    colors: [CGColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 0.4), CGColor(red: 0, green: 0, blue: 0, alpha: 0)] as CFArray,
    locations: [0.0, 1.0]
) {
    context.drawRadialGradient(
        auroraGrad1,
        startCenter: CGPoint(x: 320, y: 720),
        startRadius: 0,
        endCenter: CGPoint(x: 320, y: 720),
        endRadius: 400,
        options: []
    )
}

if let auroraGrad2 = CGGradient(
    colorsSpace: colorSpace,
    colors: [CGColor(red: 0.95, green: 0.2, blue: 0.65, alpha: 0.45), CGColor(red: 0, green: 0, blue: 0, alpha: 0)] as CFArray,
    locations: [0.0, 1.0]
) {
    context.drawRadialGradient(
        auroraGrad2,
        startCenter: CGPoint(x: 720, y: 480),
        startRadius: 0,
        endCenter: CGPoint(x: 720, y: 480),
        endRadius: 420,
        options: []
    )
}

// 4. Stylized Wallpaper / Display Frame (Frosted Glass Window)
let displayWidth: CGFloat = 580
let displayHeight: CGFloat = 360
let displayX = (CGFloat(size) - displayWidth) / 2
let displayY = (CGFloat(size) - displayHeight) / 2 + 10
let displayRect = CGRect(x: displayX, y: displayY, width: displayWidth, height: displayHeight)
let displayPath = CGPath(roundedRect: displayRect, cornerWidth: 36, cornerHeight: 36, transform: nil)

// Display Outer Shadow
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.6))
context.addPath(displayPath)
context.setFillColor(CGColor(red: 0.08, green: 0.1, blue: 0.18, alpha: 0.85))
context.fillPath()
context.restoreGState()

// Inner Screen
context.saveGState()
context.addPath(displayPath)
context.clip()

// Screen wallpaper image: layered wave & glowing sun/moon
let screenColors = [
    CGColor(red: 0.08, green: 0.14, blue: 0.32, alpha: 1.0),
    CGColor(red: 0.22, green: 0.08, blue: 0.35, alpha: 1.0)
] as CFArray
if let screenGrad = CGGradient(colorsSpace: colorSpace, colors: screenColors, locations: [0.0, 1.0]) {
    context.drawLinearGradient(screenGrad, start: CGPoint(x: displayX, y: displayY + displayHeight), end: CGPoint(x: displayX, y: displayY), options: [])
}

// Sun/Orb inside screen
if let orbGrad = CGGradient(
    colorsSpace: colorSpace,
    colors: [CGColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.9), CGColor(red: 0.9, green: 0.1, blue: 0.4, alpha: 0.6), CGColor(red: 0, green: 0, blue: 0, alpha: 0)] as CFArray,
    locations: [0.0, 0.6, 1.0]
) {
    context.drawRadialGradient(orbGrad, startCenter: CGPoint(x: displayX + displayWidth * 0.5, y: displayY + displayHeight * 0.6), startRadius: 0, endCenter: CGPoint(x: displayX + displayWidth * 0.5, y: displayY + displayHeight * 0.6), endRadius: 130, options: [])
}

// Neon Landscape Mountain Waves inside display
let wavePath1 = CGMutablePath()
wavePath1.move(to: CGPoint(x: displayX, y: displayY))
wavePath1.addLine(to: CGPoint(x: displayX, y: displayY + 110))
wavePath1.addCurve(to: CGPoint(x: displayX + displayWidth * 0.5, y: displayY + 160), control1: CGPoint(x: displayX + displayWidth * 0.25, y: displayY + 70), control2: CGPoint(x: displayX + displayWidth * 0.38, y: displayY + 170))
wavePath1.addCurve(to: CGPoint(x: displayX + displayWidth, y: displayY + 80), control1: CGPoint(x: displayX + displayWidth * 0.65, y: displayY + 150), control2: CGPoint(x: displayX + displayWidth * 0.85, y: displayY + 60))
wavePath1.addLine(to: CGPoint(x: displayX + displayWidth, y: displayY))
wavePath1.closeSubpath()

context.saveGState()
context.addPath(wavePath1)
context.setFillColor(CGColor(red: 0.05, green: 0.25, blue: 0.45, alpha: 0.8))
context.fillPath()
context.restoreGState()

let wavePath2 = CGMutablePath()
wavePath2.move(to: CGPoint(x: displayX, y: displayY))
wavePath2.addLine(to: CGPoint(x: displayX, y: displayY + 60))
wavePath2.addCurve(to: CGPoint(x: displayX + displayWidth * 0.6, y: displayY + 100), control1: CGPoint(x: displayX + displayWidth * 0.3, y: displayY + 120), control2: CGPoint(x: displayX + displayWidth * 0.45, y: displayY + 70))
wavePath2.addCurve(to: CGPoint(x: displayX + displayWidth, y: displayY + 40), control1: CGPoint(x: displayX + displayWidth * 0.75, y: displayY + 120), control2: CGPoint(x: displayX + displayWidth * 0.9, y: displayY + 80))
wavePath2.addLine(to: CGPoint(x: displayX + displayWidth, y: displayY))
wavePath2.closeSubpath()

context.saveGState()
context.addPath(wavePath2)
context.setFillColor(CGColor(red: 0.02, green: 0.12, blue: 0.25, alpha: 0.95))
context.fillPath()
context.restoreGState()

// Subtle grid overlay on screen for retro wave aesthetic
context.setStrokeColor(CGColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.2))
context.setLineWidth(1.5)
for y in stride(from: displayY, through: displayY + 80, by: 16) {
    context.move(to: CGPoint(x: displayX, y: y))
    context.addLine(to: CGPoint(x: displayX + displayWidth, y: y))
    context.strokePath()
}

// Display Glass Border
context.restoreGState() // Exit display clip

context.saveGState()
context.addPath(displayPath)
context.setStrokeColor(CGColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.4))
context.setLineWidth(4.0)
context.strokePath()
context.restoreGState()

// 5. Glowing Play / Sparkle Badges around the display
func drawSparkle(center: CGPoint, radius: CGFloat, color: CGColor) {
    context.saveGState()
    context.setShadow(offset: .zero, blur: 14, color: color)
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y - radius))
    path.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y), control: center)
    path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + radius), control: center)
    path.addQuadCurve(to: CGPoint(x: center.x - radius, y: center.y), control: center)
    path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: center)
    context.addPath(path)
    context.setFillColor(color)
    context.fillPath()
    context.restoreGState()
}

drawSparkle(center: CGPoint(x: displayX + displayWidth - 20, y: displayY + displayHeight + 25), radius: 32, color: CGColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 0.95))
drawSparkle(center: CGPoint(x: displayX + 25, y: displayY - 20), radius: 24, color: CGColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 0.9))
drawSparkle(center: CGPoint(x: displayX - 45, y: displayY + displayHeight * 0.6), radius: 18, color: CGColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.85))

// 6. Highlight Border for the macOS Squircle (Inner Glow)
context.saveGState()
context.addPath(squirclePath)
context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.22))
context.setLineWidth(3.0)
context.strokePath()
context.restoreGState()

context.restoreGState() // Exit squircle clip

guard let cgImage = context.makeImage() else {
    fatalError("Failed to render CGImage")
}

// Save master 1024x1024 image
let rootDir = FileManager.default.currentDirectoryPath
let iconsetDir = URL(fileURLWithPath: rootDir).appendingPathComponent("Resources/AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let iconSizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (filename, targetSize) in iconSizes {
    let rep = NSBitmapImageRep(cgImage: cgImage)
    let resizedRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: targetSize,
        pixelsHigh: targetSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    resizedRep.size = NSSize(width: targetSize, height: targetSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: resizedRep)
    NSGraphicsContext.current?.imageInterpolation = .high
    rep.draw(in: NSRect(x: 0, y: 0, width: targetSize, height: targetSize))
    NSGraphicsContext.restoreGraphicsState()

    if let pngData = resizedRep.representation(using: .png, properties: [:]) {
        let dest = iconsetDir.appendingPathComponent(filename)
        try? pngData.write(to: dest)
    }
}

print("✅ Generated all icon sizes in \(iconsetDir.path)")
