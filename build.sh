#!/bin/bash

set -e

APP_NAME="QuickMic"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME..."

# Clean previous build
rm -rf "$BUILD_DIR"

# Create app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Compile Swift code
echo "Compiling Swift code..."
swiftc -O -o "$MACOS_DIR/$APP_NAME" QuickMic.swift

# Copy Info.plist
cp Info.plist "$CONTENTS_DIR/"

echo "✅ Build complete: $APP_BUNDLE"
echo ""
echo "To install:"
echo "  cp -r $APP_BUNDLE /Applications/"
echo ""
echo "To run from here:"
echo "  open $APP_BUNDLE"
