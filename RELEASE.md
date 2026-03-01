# Release Guide

How to build, package, and distribute Fireplace.

## Build a release binary

```bash
swift build -c release
```

The binary is at `.build/release/Fireplace`.

## Create the .app bundle

SPM produces a bare executable. You need to wrap it in an .app bundle for macOS to treat it as a real application.

```bash
mkdir -p Fireplace.app/Contents/MacOS
cp .build/release/Fireplace Fireplace.app/Contents/MacOS/
```

Create the Info.plist:

```bash
cat > Fireplace.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Fireplace</string>
    <key>CFBundleDisplayName</key>
    <string>Fireplace</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.fireplace</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>Fireplace</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
```

Update `CFBundleIdentifier` with your actual identifier and bump `CFBundleShortVersionString` for each release.

## Create the DMG

```bash
hdiutil create -volname "Fireplace" -srcfolder Fireplace.app -ov -format UDZO Fireplace.dmg
```

This produces `Fireplace.dmg`. Users open it, drag to Applications, done.

## Code signing and notarization (optional)

Requires an Apple Developer account ($99/year). Without this, users will see "app from unidentified developer" on first launch and need to right-click > Open. Many open source Mac apps ship unsigned.

### Sign the app

```bash
codesign --deep --force --sign "Developer ID Application: Your Name (TEAMID)" Fireplace.app
```

### Notarize the DMG

```bash
xcrun notarytool submit Fireplace.dmg \
    --apple-id you@email.com \
    --password your-app-specific-password \
    --team-id TEAMID \
    --wait
```

### Staple the notarization ticket

```bash
xcrun stapler staple Fireplace.dmg
```

After stapling, Gatekeeper will allow the app without any warnings.

## Distribute on GitHub Releases

### Tag the release

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Create the release on GitHub

1. Go to your repo > Releases > Draft a new release.
2. Select the tag you just pushed.
3. Title: `Fireplace 1.0.0`
4. Upload `Fireplace.dmg` as a release asset.
5. Add release notes (see template below).
6. Publish.

### Release notes template

```
## Fireplace 1.0.0

A tiny cozy focus timer for macOS.

### Download

Download `Fireplace.dmg`, open it, and drag Fireplace to your Applications folder.

> First launch: right-click the app > Open (required for unsigned apps).

### What's included

- Pixel-art campfire that burns in your Dock while you focus
- Ambient sound mixer (fire, rain, wind, noise) in the menu bar
- Session history with 30-day calendar
- Built entirely in Swift with zero dependencies

### Requirements

- macOS 14 (Sonoma) or later

See the [README](README.md) for full details.
```

### Direct download link

After publishing, the DMG is available at:

```
https://github.com/your-username/fireplace/releases/latest/download/Fireplace.dmg
```

Use this URL on your landing page or anywhere you link to the download.

## Quick reference (all commands)

```bash
# Build
swift build -c release

# Package
mkdir -p Fireplace.app/Contents/MacOS
cp .build/release/Fireplace Fireplace.app/Contents/MacOS/
# (create Info.plist as shown above)

# DMG
hdiutil create -volname "Fireplace" -srcfolder Fireplace.app -ov -format UDZO Fireplace.dmg

# Tag and push
git tag v1.0.0
git push origin v1.0.0

# Then upload Fireplace.dmg to GitHub Releases
```
