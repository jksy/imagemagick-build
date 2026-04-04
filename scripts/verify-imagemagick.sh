#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/opt/imagemagick}"
export PATH="$PREFIX/bin:$PATH"

magick -version
magick -list format | grep -E "JPEG|PNG|TIFF|WEBP|AVIF"
pkg-config --exists MagickCore && echo "MagickCore pkg-config: OK"
