import AppKit
import AVFoundation

final class WallpaperManager {
    static let shared = WallpaperManager()

    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var windows: [WallpaperWindow] = []

    private(set) var currentURL: URL?
    private(set) var isPlaying: Bool = false
    private(set) var isMuted: Bool = true
    private(set) var syncLockScreen: Bool = true
    private(set) var currentGravity: AVLayerVideoGravity = .resizeAspectFill

    private let defaults = UserDefaults.standard
    private let kSavedVideoKey = "SavedWallpaperURL"
    private let kSavedMutedKey = "SavedWallpaperMuted"
    private let kSavedGravityKey = "SavedWallpaperGravity"
    private let kSavedSyncLockScreenKey = "SavedWallpaperSyncLockScreen"

    var onStateChange: (() -> Void)?

    private init() {
        self.isMuted = defaults.object(forKey: kSavedMutedKey) as? Bool ?? true
        self.syncLockScreen = defaults.object(forKey: kSavedSyncLockScreenKey) as? Bool ?? true
        if let gravityRaw = defaults.string(forKey: kSavedGravityKey) {
            self.currentGravity = AVLayerVideoGravity(rawValue: gravityRaw)
        }
        setupNotifications()
    }

    func setupScreens() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()

        for screen in NSScreen.screens {
            let win = WallpaperWindow(screen: screen)
            if let queuePlayer = queuePlayer {
                win.attachPlayer(queuePlayer, gravity: currentGravity)
            }
            win.orderBack(nil)
            windows.append(win)
        }

        if syncLockScreen, let url = currentURL {
            syncLockScreenPoster(for: AVURLAsset(url: url))
        }
    }

    func loadSavedWallpaper() {
        if let savedPath = defaults.string(forKey: kSavedVideoKey) {
            let url = URL(fileURLWithPath: savedPath)
            if FileManager.default.fileExists(atPath: url.path) {
                setWallpaper(url: url)
                return
            }
        }

        // Look for sample_wallpaper.mp4 in current working directory or bundle
        let localSample = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("sample_wallpaper.mp4")
        if FileManager.default.fileExists(atPath: localSample.path) {
            setWallpaper(url: localSample)
        } else if let bundleSample = Bundle.main.url(forResource: "sample_wallpaper", withExtension: "mp4") {
            setWallpaper(url: bundleSample)
        }
    }

    func setWallpaper(url: URL) {
        self.currentURL = url
        defaults.set(url.path, forKey: kSavedVideoKey)

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer(playerItem: playerItem)
        player.isMuted = isMuted

        self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        self.queuePlayer = player

        if windows.isEmpty {
            setupScreens()
        } else {
            for win in windows {
                win.attachPlayer(player, gravity: currentGravity)
                win.orderBack(nil)
            }
        }

        player.play()
        self.isPlaying = true
        syncLockScreenPoster(for: asset)
        onStateChange?()
    }

    func togglePlayPause() {
        guard let player = queuePlayer else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        onStateChange?()
    }

    func toggleMute() {
        isMuted.toggle()
        queuePlayer?.isMuted = isMuted
        defaults.set(isMuted, forKey: kSavedMutedKey)
        onStateChange?()
    }

    func toggleSyncLockScreen() {
        syncLockScreen.toggle()
        defaults.set(syncLockScreen, forKey: kSavedSyncLockScreenKey)
        if syncLockScreen, let url = currentURL {
            syncLockScreenPoster(for: AVURLAsset(url: url))
        }
        onStateChange?()
    }

    func syncLockScreenPoster(for asset: AVAsset) {
        guard syncLockScreen else { return }

        Task {
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)
                let targetSec = (seconds.isFinite && seconds > 1.0) ? 1.0 : 0.1
                let time = CMTime(seconds: targetSec, preferredTimescale: 600)

                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true

                let cgImage: CGImage
                if #available(macOS 15.0, *) {
                    let (img, _) = try await generator.image(at: time)
                    cgImage = img
                } else {
                    cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                }

                let rep = NSBitmapImageRep(cgImage: cgImage)
                guard let data = rep.representation(using: .png, properties: [:]) else { return }

                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let dir = appSupport.appendingPathComponent("LiveWallpaper", isDirectory: true)
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let posterURL = dir.appendingPathComponent("lockscreen_poster.png")
                try data.write(to: posterURL)

                await MainActor.run {
                    for screen in NSScreen.screens {
                        do {
                            try NSWorkspace.shared.setDesktopImageURL(posterURL, for: screen, options: [:])
                        } catch {
                            print("LiveWallpaper: Could not set desktop image for screen \(screen): \(error)")
                        }
                    }
                }
            } catch {
                print("LiveWallpaper: Error syncing lock screen poster: \(error)")
            }
        }
    }

    func setGravity(_ gravity: AVLayerVideoGravity) {
        self.currentGravity = gravity
        defaults.set(gravity.rawValue, forKey: kSavedGravityKey)
        for win in windows {
            win.updateGravity(gravity)
        }
        onStateChange?()
    }

    private func setupNotifications() {
        // Display configuration change (plugging in / unplugging external monitors)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupScreens()
        }

        // Screen sleep & wake
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.queuePlayer?.pause()
        }
        ws.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            if self?.isPlaying == true {
                self?.queuePlayer?.play()
            }
        }
        ws.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.queuePlayer?.pause()
        }
        // Lock screen sleep & wake / lock & unlock
        let dist = DistributedNotificationCenter.default()
        dist.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.queuePlayer?.pause()
        }
        dist.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.isPlaying == true {
                self?.queuePlayer?.play()
            }
        }
    }
}
