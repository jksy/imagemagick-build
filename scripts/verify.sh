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
for fmt in JPEG PNG TIFF WEBP AVIF PDF; do
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

# Conversion smoke tests
echo ""
echo "--- Conversion smoke tests ---"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

"${MAGICK}" -size 64x64 gradient: "${TMP_DIR}/source.png"

for fmt in JPEG PNG TIFF WEBP AVIF PDF; do
  lower_fmt="$(echo "${fmt}" | tr '[:upper:]' '[:lower:]')"
  out_file="${TMP_DIR}/out.${lower_fmt}"

  "${MAGICK}" "${TMP_DIR}/source.png" "${out_file}"
  if [ ! -s "${out_file}" ]; then
    echo "  [ERROR] Failed writing ${fmt}" >&2
    exit 1
  fi
  echo "  [OK] write ${fmt}"
done

"${MAGICK}" "${TMP_DIR}/out.pdf[0]" "${TMP_DIR}/pdf_page0.png"
if [ ! -s "${TMP_DIR}/pdf_page0.png" ]; then
  echo "  [ERROR] Failed converting PDF to PNG" >&2
  exit 1
fi
echo "  [OK] PDF -> PNG"

echo ""
echo "=== Verification passed ==="
