#!/bin/sh
# Builds a universal (arm64 + x86_64), ad-hoc signed "AppSweeper.app" and zips it (with README.md) for sharing.
cd "$(dirname "$0")" || exit 1
APP="AppSweeper.app"
rm -rf "$APP" AppSweeper.zip; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for arch in arm64 x86_64; do
  swiftc -swift-version 5 -parse-as-library -O -target "$arch-apple-macos14.0" App.swift -o "/tmp/AppSweeper-$arch" || exit 1
done
lipo -create /tmp/AppSweeper-arm64 /tmp/AppSweeper-x86_64 -output "$APP/Contents/MacOS/AppSweeper" && rm /tmp/AppSweeper-*
cp Info.plist "$APP/Contents/"
cp AppIcon.icns "$APP/Contents/Resources/"
cp -R en.lproj es.lproj "$APP/Contents/Resources/"
codesign --force --deep -s - "$APP" || exit 1
STAGE="/tmp/AppSweeper"
rm -rf "$STAGE"; mkdir "$STAGE"
cp -R "$APP" README.md "$STAGE/"
ditto -c -k --keepParent "$STAGE" AppSweeper.zip && rm -rf "$STAGE"
