#!/bin/bash

# Port Manager Build Script
# This script compiles the Port Manager app from Swift source files

set -e  # Exit on any error

echo "🔨 Building Port Manager..."
echo ""

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p PortManager.app/Contents/MacOS

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp PortManager/Info.plist PortManager.app/Contents/

# Compile Swift files
echo "⚙️  Compiling Swift files..."
swiftc -o PortManager.app/Contents/MacOS/PortManager \
    -framework Cocoa \
    -O \
    PortManager/Sources/main.swift \
    PortManager/Sources/AppDelegate.swift \
    PortManager/Sources/StaticPortListViewController.swift \
    PortManager/Sources/PreferencesWindowController.swift

echo ""
echo "✅ Build complete!"
echo ""
echo "To run the app, execute:"
echo "  open PortManager.app"
echo ""
echo "Or run this script with the --run flag:"
echo "  ./build.sh --run"
echo ""

# Auto-run if --run flag is provided
if [ "$1" = "--run" ] || [ "$1" = "-r" ]; then
    echo "🚀 Launching Port Manager..."
    open PortManager.app
fi
