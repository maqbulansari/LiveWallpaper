import AppKit
import AVFoundation

final class WallpaperWindow: NSWindow {
    private var playerLayer: AVPlayerLayer?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.setFrame(screen.frame, display: true)

        // Desktop window level - sits directly beneath desktop icons and above wallpaper
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true // Allows clicking desktop icons and Finder desktop

        let contentView = NSView(frame: screen.frame)
        contentView.wantsLayer = true
        contentView.layer = CALayer()
        self.contentView = contentView
    }

    func attachPlayer(_ player: AVQueuePlayer, gravity: AVLayerVideoGravity = .resizeAspectFill) {
        playerLayer?.removeFromSuperlayer()

        let layer = AVPlayerLayer(player: player)
        layer.frame = contentView?.bounds ?? .zero
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer.videoGravity = gravity
        contentView?.layer?.addSublayer(layer)
        self.playerLayer = layer

        self.orderBack(nil)
    }

    func updateGravity(_ gravity: AVLayerVideoGravity) {
        playerLayer?.videoGravity = gravity
    }
}
