#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/opt/imagemagick}"
export PATH="$PREFIX/bin:$PATH"

magick -version
formats="$(magick -list format)"
for required_format in JPEG PNG TIFF WEBP AVIF; do
  printf '%s\n' "$formats" | grep -Eq "^[[:space:]]*${required_format}[[:space:]]"
  echo "${required_format} format: OK"
done
pkg-config --exists MagickCore && echo "MagickCore pkg-config: OK"
