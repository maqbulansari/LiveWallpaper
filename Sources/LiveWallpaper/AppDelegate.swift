import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarController = MenuBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController.setup()
        WallpaperManager.shared.setupScreens()
        WallpaperManager.shared.loadSavedWallpaper()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }
}
