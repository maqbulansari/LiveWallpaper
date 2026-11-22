import AppKit
import UniformTypeIdentifiers

final class MenuBarController {
    private var statusItem: NSStatusItem!
    private let manager = WallpaperManager.shared

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Live Wallpaper") {
                button.image = image
            } else {
                button.title = "✨"
            }
        }

        manager.onStateChange = { [weak self] in
            self?.updateMenu()
        }

        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        // Status Header
        let statusTitle: String
        if let currentURL = manager.currentURL {
            let filename = currentURL.lastPathComponent
            let state = manager.isPlaying ? "Playing" : "Paused"
            statusTitle = "\(state): \(filename)"
        } else {
            statusTitle = "No Wallpaper Selected"
        }
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // Choose Wallpaper
        let chooseItem = NSMenuItem(
            title: "Choose Video Wallpaper...",
            action: #selector(chooseWallpaper),
            keyEquivalent: "o"
        )
        chooseItem.target = self
        menu.addItem(chooseItem)

        // Play / Pause
        let playPauseTitle = manager.isPlaying ? "Pause Wallpaper" : "Resume Wallpaper"
        let playPauseItem = NSMenuItem(
            title: playPauseTitle,
            action: #selector(togglePlayPause),
            keyEquivalent: "p"
        )
        playPauseItem.target = self
        playPauseItem.isEnabled = manager.currentURL != nil
        menu.addItem(playPauseItem)

        // Mute / Unmute
        let muteTitle = manager.isMuted ? "Unmute Audio" : "Mute Audio"
        let muteItem = NSMenuItem(
            title: muteTitle,
            action: #selector(toggleMute),
            keyEquivalent: "m"
        )
        muteItem.target = self
        muteItem.isEnabled = manager.currentURL != nil
        menu.addItem(muteItem)

        // Video Scaling Submenu
        let scalingMenu = NSMenu()
        let aspectFill = NSMenuItem(title: "Aspect Fill (Crop to Fit)", action: #selector(setAspectFill), keyEquivalent: "")
        aspectFill.target = self
        aspectFill.state = manager.currentGravity == .resizeAspectFill ? .on : .off
        scalingMenu.addItem(aspectFill)

        let aspectFit = NSMenuItem(title: "Aspect Fit (Letterbox)", action: #selector(setAspectFit), keyEquivalent: "")
        aspectFit.target = self
        aspectFit.state = manager.currentGravity == .resizeAspect ? .on : .off
        scalingMenu.addItem(aspectFit)

        let resize = NSMenuItem(title: "Stretch to Fill", action: #selector(setStretch), keyEquivalent: "")
        resize.target = self
        resize.state = manager.currentGravity == .resize ? .on : .off
        scalingMenu.addItem(resize)

        let scalingItem = NSMenuItem(title: "Video Scaling", action: nil, keyEquivalent: "")
        scalingItem.submenu = scalingMenu
        menu.addItem(scalingItem)

        // Sync Lock Screen Wallpaper (Poster Frame)
        let lockSyncItem = NSMenuItem(
            title: "Sync Lock Screen Wallpaper",
            action: #selector(toggleSyncLockScreen),
            keyEquivalent: "l"
        )
        lockSyncItem.target = self
        lockSyncItem.state = manager.syncLockScreen ? .on : .off
        menu.addItem(lockSyncItem)

        menu.addItem(NSMenuItem.separator())

        // Open Wallpapers Folder
        let folderItem = NSMenuItem(title: "Open Wallpapers Folder...", action: #selector(openFolder), keyEquivalent: "")
        folderItem.target = self
        menu.addItem(folderItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Live Wallpaper", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    @objc private func chooseWallpaper() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType.movie,
            UTType.video,
            UTType.quickTimeMovie,
            UTType.mpeg4Movie
        ]
        panel.title = "Select Live Wallpaper Video"
        panel.prompt = "Set Wallpaper"

        NSApp.activate(ignoringOtherApps: true)

        if panel.runModal() == .OK, let url = panel.url {
            manager.setWallpaper(url: url)
        }
    }

    @objc private func togglePlayPause() {
        manager.togglePlayPause()
    }

    @objc private func toggleMute() {
        manager.toggleMute()
    }

    @objc private func toggleSyncLockScreen() {
        manager.toggleSyncLockScreen()
    }

    @objc private func setAspectFill() {
        manager.setGravity(.resizeAspectFill)
    }

    @objc private func setAspectFit() {
        manager.setGravity(.resizeAspect)
    }

    @objc private func setStretch() {
        manager.setGravity(.resize)
    }

    @objc private func openFolder() {
        let path = FileManager.default.currentDirectoryPath
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
