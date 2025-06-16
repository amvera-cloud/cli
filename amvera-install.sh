#!/bin/bash

set -e

VERSION="v1.0.0"
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

TAR_URL="https://github.com/amvera-cloud/cli/releases/download/v0.9.20/amvera-macos-x64.zip"

echo "Downloading $TAR_URL..."
curl -L "$TAR_URL" -o amvera-macos-x64.zip

echo "Extracting..."
tar -xzf amvera-macos-x64.zip

echo "Installing to /usr/local/bin..."
chmod +x amvera
sudo mv amvera /usr/local/bin/amvera

echo "Installation complete. Run 'amvera help' to get started."