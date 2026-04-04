#!/usr/bin/env bash
# verify.sh — Verify the ImageMagick build artifacts
set -euo pipefail

PREFIX="${PREFIX:-/opt/imagemagick}"
MAGICK="${PREFIX}/bin/magick"

echo "=== Verifying ImageMagick build ==="

# Check binary exists
if [ ! -x "${MAGICK}" ]; then
  echo "ERROR: ${MAGICK} not found or not executable" >&2
  exit 1
fi

export LD_LIBRARY_PATH="${PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# Version
echo ""
echo "--- magick -version ---"
"${MAGICK}" -version

# Format support
echo ""
echo "--- Format support ---"
MISSING=0
for fmt in JPEG PNG TIFF WEBP AVIF; do
  if "${MAGICK}" -list format | grep -q "^  *${fmt}"; then
    echo "  [OK] ${fmt}"
  else
    echo "  [MISSING] ${fmt}" >&2
    MISSING=1
  fi
done

if [ "${MISSING:-0}" = "1" ]; then
  echo ""
  echo "ERROR: One or more required formats are missing." >&2
  exit 1
fi

# pkg-config
echo ""
echo "--- pkg-config ---"
PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" pkg-config --modversion MagickCore && echo "  [OK] MagickCore pkg-config"

echo ""
echo "=== Verification passed ==="
