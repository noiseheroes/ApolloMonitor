#!/bin/bash

# Apollo Monitor - DMG Build Script
# Creates a professional DMG installer

set -e

# Configuration
APP_NAME="ApolloMonitor"
VOL_NAME="Apollo Monitor"
DMG_NAME="ApolloMonitor-v2.0.0"
BUNDLE_ID="com.noiseheroes.ApolloMonitor"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DMG_DIR="$BUILD_DIR/dmg"
APP_PATH="$BUILD_DIR/Release/${APP_NAME}.app"

echo "🔨 Building Apollo Monitor..."
echo "   Project: $PROJECT_DIR"

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the app
echo "📦 Building app with xcodebuild..."
cd "$PROJECT_DIR"
xcodebuild -project ApolloMonitor.xcodeproj \
    -scheme ApolloMonitor \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/ApolloMonitor.xcarchive" \
    archive \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Export the app
echo "📤 Exporting app..."
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/ApolloMonitor.xcarchive" \
    -exportPath "$BUILD_DIR/Release" \
    -exportOptionsPlist "$PROJECT_DIR/scripts/ExportOptions.plist"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH"
    echo "   Trying alternative location..."
    APP_PATH="$BUILD_DIR/DerivedData/Build/Products/Release/${APP_NAME}.app"
    if [ ! -d "$APP_PATH" ]; then
        APP_PATH="$BUILD_DIR/ApolloMonitor.xcarchive/Products/Applications/${APP_NAME}.app"
    fi
fi

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Could not find built app!"
    exit 1
fi

echo "✅ App built: $APP_PATH"

# Create DMG structure
echo "📀 Creating DMG structure..."
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Copy background
mkdir -p "$DMG_DIR/.background"
cp "$PROJECT_DIR/Installer/background.png" "$DMG_DIR/.background/"
cp "$PROJECT_DIR/Installer/background@2x.png" "$DMG_DIR/.background/"

# Create temporary DMG
echo "💿 Creating DMG..."
TEMP_DMG="$BUILD_DIR/temp.dmg"
hdiutil create -srcfolder "$DMG_DIR" -volname "$VOL_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW "$TEMP_DMG"

# Mount and customize
echo "🎨 Customizing DMG appearance..."
MOUNT_DIR="/Volumes/$VOL_NAME"
hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen

# Wait for mount
sleep 2

# Set custom icon positions and window size using AppleScript
osascript << EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 640, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set background picture of viewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {135, 180}
        set position of item "Applications" of container window to {405, 180}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Set volume icon
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_512.png" "$MOUNT_DIR/.VolumeIcon.icns" 2>/dev/null || true
SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns" 2>/dev/null || true
SetFile -a C "$MOUNT_DIR" 2>/dev/null || true

# Unmount
sync
hdiutil detach "$MOUNT_DIR"

# Convert to compressed DMG
echo "🗜️  Compressing DMG..."
FINAL_DMG="$BUILD_DIR/${DMG_NAME}.dmg"
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"
rm "$TEMP_DMG"

# Add license to DMG (if hdiutil supports it)
# Note: This requires the license to be in a specific format

echo ""
echo "✅ DMG created successfully!"
echo "   📍 $FINAL_DMG"
echo "   📊 Size: $(du -h "$FINAL_DMG" | cut -f1)"
echo ""
echo "🚀 Ready for distribution!"
