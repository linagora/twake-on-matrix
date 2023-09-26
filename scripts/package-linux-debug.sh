#!/bin/bash

# Setup appimage-builder for packaging
echo "Setting up appimage-builder"
wget -O appimage-builder-x86_64.AppImage https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.1.0/appimage-builder-1.1.0-x86_64.AppImage
chmod +x appimage-builder-x86_64.AppImage
sudo mv appimage-builder-x86_64.AppImage /usr/local/bin/appimage-builder

echo "Packaging."
export BUILD_TYPE=profile
# This is to set environment variable from a file
# https://stackoverflow.com/a/45971167/8296391
set -a; . /etc/os-release; set +a
appimage-builder --recipe appimage/AppImageBuilder.yml --skip-tests
mkdir dist && cp ./*.AppImage dist/
