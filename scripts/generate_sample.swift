import Foundation
import AVFoundation
import CoreGraphics
import CoreVideo

let width = 1920
let height = 1080
let fps: Int32 = 60
let durationSeconds = 5
let totalFrames = durationSeconds * Int(fps)
let outputPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("sample_wallpaper.mp4")

if FileManager.default.fileExists(atPath: outputPath.path) {
    try? FileManager.default.removeItem(at: outputPath)
}

print("🎨 Generating looping sample wallpaper to \(outputPath.path)...")

guard let writer = try? AVAssetWriter(outputURL: outputPath, fileType: .mp4) else {
    fatalError("Failed to create AVAssetWriter")
}

let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 6_000_000,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
    ]
]

let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
writerInput.expectsMediaDataInRealTime = false

let sourcePixelBufferAttributes: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height,
    kCVPixelBufferCGImageCompatibilityKey as String: true,
    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
]

let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: writerInput,
    sourcePixelBufferAttributes: sourcePixelBufferAttributes
)

writer.add(writerInput)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

func createPixelBuffer() -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32ARGB,
        sourcePixelBufferAttributes as CFDictionary,
        &pixelBuffer
    )
    return status == kCVReturnSuccess ? pixelBuffer : nil
}

let colorSpace = CGColorSpaceCreateDeviceRGB()

for frame in 0..<totalFrames {
    while !writerInput.isReadyForMoreMediaData {
        usleep(1000)
    }

    guard let pixelBuffer = createPixelBuffer() else {
        print("Failed to allocate pixelBuffer")
        break
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

    if let context = CGContext(
        data: pixelData,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    ) {
        let t = Double(frame) / Double(totalFrames) * 2.0 * .pi

        // Background dark gradient
        let startColor = CGColor(red: CGFloat(0.05 + 0.05 * sin(t)), green: CGFloat(0.08 + 0.04 * cos(t)), blue: CGFloat(0.18 + 0.08 * sin(t + 1.0)), alpha: 1.0)
        let midColor = CGColor(red: CGFloat(0.12 + 0.10 * sin(t + 2.0)), green: CGFloat(0.04 + 0.04 * cos(t + 1.0)), blue: CGFloat(0.25 + 0.10 * cos(t)), alpha: 1.0)
        let endColor = CGColor(red: CGFloat(0.02), green: CGFloat(0.03), blue: CGFloat(0.08), alpha: 1.0)

        let colors = [startColor, midColor, endColor] as CFArray
        let locations: [CGFloat] = [0.0, 0.5, 1.0]
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            let startPoint = CGPoint(x: CGFloat(Double(width) * (0.5 + 0.3 * cos(t))), y: CGFloat(Double(height) * (0.5 + 0.3 * sin(t))))
            let endPoint = CGPoint(x: CGFloat(Double(width) * (0.5 - 0.3 * cos(t))), y: CGFloat(Double(height) * (0.5 - 0.3 * sin(t))))
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }

        // Draw animated glowing aurora orbs
        for i in 0..<5 {
            let offset = Double(i) * (.pi * 2.0 / 5.0)
            let cx = Double(width) * (0.5 + 0.35 * cos(t + offset))
            let cy = Double(height) * (0.5 + 0.25 * sin(2.0 * (t + offset)))
            let radius = CGFloat(200.0 + 80.0 * sin(t + Double(i)))

            let orbColors = [
                CGColor(red: CGFloat(0.3 + 0.3 * sin(t + Double(i))), green: CGFloat(0.4 + 0.4 * cos(t)), blue: CGFloat(0.8 + 0.2 * sin(t)), alpha: 0.35),
                CGColor(red: 0, green: 0, blue: 0, alpha: 0.0)
            ] as CFArray
            if let orbGrad = CGGradient(colorsSpace: colorSpace, colors: orbColors, locations: [0.0, 1.0]) {
                context.drawRadialGradient(orbGrad, startCenter: CGPoint(x: cx, y: cy), startRadius: 0, endCenter: CGPoint(x: cx, y: cy), endRadius: radius, options: [])
            }
        }
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

    let presentationTime = CMTime(value: Int64(frame), timescale: fps)
    adaptor.append(pixelBuffer, withPresentationTime: presentationTime)

    if frame % 60 == 0 {
        print("  Rendering: \(Int(Double(frame) / Double(totalFrames) * 100))%")
    }
}

writerInput.markAsFinished()
let group = DispatchGroup()
group.enter()
writer.finishWriting {
    group.leave()
}
group.wait()

print("✨ Successfully generated \(outputPath.lastPathComponent) (5s loop, 60fps, 1080p)!")
