#!/usr/bin/env bash

set -e

if [ $# -eq 0 ]; then
    echo "Error: Version is required"
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.0.0"
    exit 1
fi

VERSION="$1"
REPO_URL="https://github.com/amvera-cloud/cli/releases/download"

# Check if version is provided
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format"
    echo "Version should be in format: vX.Y.Z (e.g., v1.0.0)"
    exit 1
else
    echo "Chosen version ${VERSION}"
fi

# Detect OS
OS="$(uname | tr '[:upper:]' '[:lower:]')"
case "$OS" in
  linux) OS="linux" ;;
  darwin) OS="macos" ;;
  msys*|cygwin*|mingw*) OS="windows" ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

# Detect ARCH
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) ARCH="x64" ;;
  arm64|aarch64) ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Set binary name and archive name
BINARY_NAME="amvera"

# Set archive name based on OS and ARCH
case "$OS" in
  windows)
    ZIP_NAME="${BINARY_NAME}-windows.zip"
    ;;
  macos)
    if [[ "$ARCH" == "x64" ]]; then
      ZIP_NAME="${BINARY_NAME}-macos-x64.zip"
    elif [[ "$ARCH" == "aarch64" ]]; then
      ZIP_NAME="${BINARY_NAME}-macos-arm.zip"
    fi
    ;;
  linux)
    ZIP_NAME="${BINARY_NAME}-ubuntu.zip"
    ;;
esac

DOWNLOAD_URL="${REPO_URL}/${VERSION}/${ZIP_NAME}"
echo "Downloading ${DOWNLOAD_URL}"

# Target install dir
if [[ "$OS" == "windows" ]]; then
    # For Windows, use Program Files or user's local directory
    if [[ -w "C:/Program Files" ]]; then
        INSTALL_DIR="C:/Program Files/amvera"
    else
        INSTALL_DIR="$LOCALAPPDATA/amvera"
    fi
else
    INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
    [[ ! -w "$INSTALL_DIR" ]] && INSTALL_DIR="${HOME}/.local/bin"
fi

echo "Installing amvera cli ${VERSION} for ${OS}/${ARCH} to ${INSTALL_DIR}"

# Download and extract
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"
curl -L "$DOWNLOAD_URL" -o "$ZIP_NAME"

if [[ "$OS" == "windows" ]]; then
    # For Windows, use PowerShell to extract
    powershell -Command "Expand-Archive -Path '$ZIP_NAME' -DestinationPath '.' -Force"
else
    unzip "$ZIP_NAME"
fi

# Rename binary for Windows
[[ "$OS" == "windows" ]] && BINARY_NAME="${BINARY_NAME}.exe"

# Set permissions
if [[ "$OS" != "windows" ]]; then
    chmod +x "$BINARY_NAME"
fi

# Create install directory if it doesn't exist
if [[ ! -w "$INSTALL_DIR" ]]; then
    sudo mkdir -p "$INSTALL_DIR"
else
    mkdir -p "$INSTALL_DIR"
fi

# Move binary to install directory
if [[ "$OS" == "windows" ]]; then
    # For Windows, use PowerShell to move file
    powershell -Command "Move-Item -Path '$BINARY_NAME' -Destination '$INSTALL_DIR/$BINARY_NAME' -Force"
else
    if [[ ! -w "$INSTALL_DIR" ]]; then
        sudo mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    else
        mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    fi
fi

cd ..
echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Installed to $INSTALL_DIR/$BINARY_NAME"

# Add to PATH instructions
if [[ "$OS" == "windows" ]]; then
    # Check if running as administrator
    if powershell -Command "([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"; then
        echo "Adding $INSTALL_DIR to PATH..."
        powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';$INSTALL_DIR', 'Machine')"
        echo "Successfully added to PATH"
        echo "Please restart your terminal for changes to take effect"
    else
        echo "Warning: Script is not running as administrator"
        echo "To add to PATH manually:"
        echo "1. Open System Properties (Win + Pause/Break)"
        echo "2. Click 'Advanced system settings'"
        echo "3. Click 'Environment Variables'"
        echo "4. Under 'System variables', find and select 'Path'"
        echo "5. Click 'Edit' and add: $INSTALL_DIR"
    fi
else
    echo "Make sure $INSTALL_DIR is in your PATH"
fi