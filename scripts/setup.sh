#!/usr/bin/env bash
set -e

echo "==========================================="
echo "       AudioBy - Project Setup & Tooling    "
echo "==========================================="

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew is not installed. Please install Homebrew from https://brew.sh/"
fi

# Check XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing XcodeGen via Homebrew..."
    brew install xcodegen
else
    echo "✅ XcodeGen found: $(xcodegen --version)"
fi

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode command line tools not found. Please install Xcode from Mac App Store."
    exit 1
else
    echo "✅ Xcode tools found: $(xcodebuild -version | head -n 1)"
fi

echo "🔨 Generating Xcode project..."
xcodegen generate

echo "==========================================="
echo "✅ Setup Complete!"
echo "Open 'AudioBy.xcodeproj' in Xcode to run."
echo "Or run 'make test' / 'make build' from CLI."
echo "==========================================="
