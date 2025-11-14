#!/bin/bash

# Build and Install Script for afm-cli
# This script compiles the CLI tool and installs it to your system

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="afm-cli"
SCHEME="afm-cli"
BUILD_CONFIG="Release"
INSTALL_DIR="/usr/local/bin"
LOCAL_BIN_DIR="$HOME/bin"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/afm-cli.xcodeproj/project.pbxproj" ]; then
    print_error "Xcode project not found. Please run this script from the project root directory."
    exit 1
fi

print_info "Building $PROJECT_NAME..."

# Clean and build the project
cd "$PROJECT_DIR"

# Build the project
print_info "Compiling in $BUILD_CONFIG mode..."
if ! xcodebuild -project afm-cli.xcodeproj \
                -scheme "$SCHEME" \
                -configuration "$BUILD_CONFIG" \
                clean build \
                > /dev/null 2>&1; then
    print_error "Build failed. Showing build output:"
    xcodebuild -project afm-cli.xcodeproj \
               -scheme "$SCHEME" \
               -configuration "$BUILD_CONFIG" \
               clean build
    exit 1
fi

# Find the built executable
# The build directory path is dynamic, so we need to find it
BUILD_OUTPUT=$(xcodebuild -project afm-cli.xcodeproj \
                         -scheme "$SCHEME" \
                         -configuration "$BUILD_CONFIG" \
                         -showBuildSettings 2>/dev/null | \
               grep "BUILT_PRODUCTS_DIR" | \
               head -1 | \
               sed 's/.*= *//')

if [ -z "$BUILD_OUTPUT" ]; then
    print_error "Could not determine build output directory."
    exit 1
fi

EXECUTABLE_PATH="$BUILD_OUTPUT/$PROJECT_NAME"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    print_error "Executable not found at: $EXECUTABLE_PATH"
    exit 1
fi

print_info "Build successful! Executable found at: $EXECUTABLE_PATH"

# Determine installation method
USE_SUDO=false
TARGET_DIR="$INSTALL_DIR"

# Test if we can write to the install directory by attempting to create a test file
TEST_FILE="$INSTALL_DIR/.afm-cli-install-test-$$"
if touch "$TEST_FILE" 2>/dev/null && rm -f "$TEST_FILE" 2>/dev/null; then
    print_info "Installing to $TARGET_DIR (no sudo required)"
elif command -v sudo >/dev/null 2>&1; then
    USE_SUDO=true
    print_info "Installing to $TARGET_DIR (sudo required)"
    print_info "You may be prompted for your password"
else
    # Fallback to local bin directory
    TARGET_DIR="$LOCAL_BIN_DIR"
    print_warning "Cannot write to $INSTALL_DIR and sudo not available."
    print_info "Installing to $TARGET_DIR instead"
    mkdir -p "$TARGET_DIR"
fi

# Install the executable
TARGET_PATH="$TARGET_DIR/$PROJECT_NAME"

print_info "Installing $PROJECT_NAME to $TARGET_PATH..."

# Try to install, fallback to sudo if needed
if [ "$USE_SUDO" = true ]; then
    if sudo cp "$EXECUTABLE_PATH" "$TARGET_PATH" && sudo chmod +x "$TARGET_PATH"; then
        print_info "Successfully installed $PROJECT_NAME to $TARGET_PATH"
    else
        print_error "Failed to install $PROJECT_NAME (sudo copy failed)"
        exit 1
    fi
else
    # Try without sudo first
    if cp "$EXECUTABLE_PATH" "$TARGET_PATH" 2>/dev/null && chmod +x "$TARGET_PATH" 2>/dev/null; then
        print_info "Successfully installed $PROJECT_NAME to $TARGET_PATH"
    elif command -v sudo >/dev/null 2>&1; then
        # Fallback to sudo if regular copy failed
        print_warning "Regular copy failed, trying with sudo..."
        if sudo cp "$EXECUTABLE_PATH" "$TARGET_PATH" && sudo chmod +x "$TARGET_PATH"; then
            print_info "Successfully installed $PROJECT_NAME to $TARGET_PATH (using sudo)"
        else
            print_error "Failed to install $PROJECT_NAME"
            exit 1
        fi
    else
        print_error "Failed to install $PROJECT_NAME (permission denied and sudo not available)"
        print_info "You can manually copy the executable:"
        print_info "  cp $EXECUTABLE_PATH $TARGET_PATH"
        exit 1
    fi
fi

# Verify installation
if command -v "$PROJECT_NAME" >/dev/null 2>&1; then
    INSTALLED_VERSION=$("$PROJECT_NAME" version 2>/dev/null || echo "unknown")
    print_info "Installation verified! Run '$PROJECT_NAME --help' to get started."
    print_info "Installed version: $INSTALLED_VERSION"
    
    # Check if local bin is in PATH
    if [ "$TARGET_DIR" = "$LOCAL_BIN_DIR" ] && [[ ":$PATH:" != *":$LOCAL_BIN_DIR:"* ]]; then
        print_warning "$LOCAL_BIN_DIR is not in your PATH."
        print_info "Add this line to your ~/.zshrc or ~/.bashrc:"
        echo "  export PATH=\"\$HOME/bin:\$PATH\""
    fi
else
    print_warning "Installation completed, but $PROJECT_NAME is not in your PATH."
    print_info "You can run it directly from: $TARGET_PATH"
fi

print_info "Done!"

