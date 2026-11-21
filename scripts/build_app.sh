#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🔨 Building LiveWallpaper (Release)..."
swift build -c release

APP_NAME="LiveWallpaper"
APP_DIR="$DIR/build/$APP_NAME.app"
BIN_DIR="$DIR/.build/release"

echo "📦 Packaging $APP_NAME.app..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"

# Generate icon if missing
if [ ! -f "$DIR/Resources/AppIcon.icns" ]; then
    echo "🎨 Generating app icon..."
    swift "$DIR/scripts/generate_icon.swift"
    iconutil -c icns "$DIR/Resources/AppIcon.iconset" -o "$DIR/Resources/AppIcon.icns"
fi

if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Generate sample wallpaper if missing
if [ ! -f "$DIR/sample_wallpaper.mp4" ]; then
    echo "🎨 Generating sample wallpaper..."
    swift "$DIR/scripts/generate_sample.swift"
fi

if [ -f "$DIR/sample_wallpaper.mp4" ]; then
    cp "$DIR/sample_wallpaper.mp4" "$APP_DIR/Contents/Resources/"
fi

# Info.plist with LSUIElement=true (runs as Menu Bar agent, no Dock clutter)
cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.maqx.livewallpaper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "🔏 Ad-hoc code signing..."
codesign --force --deep -s - "$APP_DIR"
touch "$APP_DIR"

# Set the icon on the .app bundle using NSWorkspace so Finder updates immediately
swift - <<SWIFT
import AppKit

let iconURL = URL(fileURLWithPath: "$DIR/Resources/AppIcon.icns")
let appURL = URL(fileURLWithPath: "$APP_DIR")
if let image = NSImage(contentsOf: iconURL) {
    NSWorkspace.shared.setIcon(image, forFile: appURL.path, options: [])
    print("🎨 Applied custom icon to Finder bundle!")
}
SWIFT

echo "✅ Successfully built: $APP_DIR"
echo "👉 You can run it now with: open \"$APP_DIR\""
