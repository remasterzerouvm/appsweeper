#!/bin/sh
# Builds a universal (arm64 + x86_64), ad-hoc signed "iDevice Apps.app" and zips it (with README.md) for sharing.
cd "$(dirname "$0")" || exit 1
APP="iDevice Apps.app"
rm -rf "$APP" iDevice-Apps.zip; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for arch in arm64 x86_64; do
  swiftc -swift-version 5 -parse-as-library -O -target "$arch-apple-macos14.0" App.swift -o "/tmp/IDeviceApps-$arch" || exit 1
done
lipo -create /tmp/IDeviceApps-arm64 /tmp/IDeviceApps-x86_64 -output "$APP/Contents/MacOS/IDeviceApps" && rm /tmp/IDeviceApps-*
cp Info.plist "$APP/Contents/"
cp AppIcon.icns "$APP/Contents/Resources/"
cp -R en.lproj es.lproj "$APP/Contents/Resources/"
codesign --force --deep -s - "$APP" || exit 1
STAGE="/tmp/iDevice-Apps"
rm -rf "$STAGE"; mkdir "$STAGE"
cp -R "$APP" README.md "$STAGE/"
ditto -c -k --keepParent "$STAGE" iDevice-Apps.zip && rm -rf "$STAGE"
