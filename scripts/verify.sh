#!/usr/bin/env bash
# verify.sh — Verify the ImageMagick build artifacts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
echo "::group::magick -version"
"${MAGICK}" -version
echo "::endgroup::"

# Format support
echo ""
echo "::group::Format support"
MISSING=0
for fmt in JPEG PNG TIFF WEBP AVIF HEIC PDF; do
  if "${MAGICK}" -list format | grep -q "^  *${fmt}"; then
    echo "  [OK] ${fmt}"
  else
    echo "  [MISSING] ${fmt}" >&2
    MISSING=1
  fi
done
echo "::endgroup::"

if [ "${MISSING:-0}" = "1" ]; then
  echo ""
  echo "ERROR: One or more required formats are missing." >&2
  exit 1
fi

# pkg-config
echo ""
echo "::group::pkg-config"
PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" pkg-config --modversion MagickCore && echo "  [OK] MagickCore pkg-config"
echo "::endgroup::"

# Conversion smoke tests
echo ""
echo "::group::Conversion smoke tests"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

"${MAGICK}" -size 64x64 gradient: "${TMP_DIR}/source.png"
IDENTIFY_ERR="${TMP_DIR}/identify.stderr"

for fmt in JPEG PNG TIFF WEBP AVIF PDF; do
  lower_fmt="$(echo "${fmt}" | tr '[:upper:]' '[:lower:]')"
  out_file="${TMP_DIR}/out.${lower_fmt}"

  "${MAGICK}" "${TMP_DIR}/source.png" "${out_file}"
  if [ ! -s "${out_file}" ]; then
    echo "  [ERROR] Failed writing ${fmt}" >&2
    exit 1
  fi
  if ! "${MAGICK}" identify "${out_file}" >/dev/null 2>"${IDENTIFY_ERR}"; then
    echo "  [ERROR] Invalid or unreadable ${fmt} output: ${out_file}" >&2
    cat "${IDENTIFY_ERR}" >&2
    exit 1
  fi
  echo "  [OK] write ${fmt}"
done

# Smoke test keep PDF check lightweight by validating page 0 rendering.
"${MAGICK}" "${TMP_DIR}/out.pdf[0]" "${TMP_DIR}/pdf_page0.png"
if [ ! -s "${TMP_DIR}/pdf_page0.png" ]; then
  echo "  [ERROR] Failed converting PDF to PNG" >&2
  exit 1
fi
if ! "${MAGICK}" identify "${TMP_DIR}/pdf_page0.png" >/dev/null 2>"${IDENTIFY_ERR}"; then
  echo "  [ERROR] Invalid or unreadable PNG output converted from PDF" >&2
  cat "${IDENTIFY_ERR}" >&2
  exit 1
fi
echo "  [OK] PDF -> PNG"
echo "::endgroup::"

# HEIC read smoke test (decode only — no encoder required)
echo ""
echo "::group::HEIC read smoke test"
HEIC_SAMPLE="${REPO_ROOT}/testdata/soundboard.heic"
if [ ! -f "${HEIC_SAMPLE}" ]; then
  echo "  [SKIP] testdata/soundboard.heic not found, skipping HEIC read test" >&2
else
  "${MAGICK}" "${HEIC_SAMPLE}" "${TMP_DIR}/heic_to_png.png" 2>"${IDENTIFY_ERR}" || {
    echo "  [ERROR] Failed to convert HEIC to PNG" >&2
    cat "${IDENTIFY_ERR}" >&2
    exit 1
  }
  if [ ! -s "${TMP_DIR}/heic_to_png.png" ]; then
    echo "  [ERROR] HEIC -> PNG produced empty output" >&2
    exit 1
  fi
  if ! "${MAGICK}" identify "${TMP_DIR}/heic_to_png.png" >/dev/null 2>"${IDENTIFY_ERR}"; then
    echo "  [ERROR] Invalid or unreadable PNG output converted from HEIC" >&2
    cat "${IDENTIFY_ERR}" >&2
    exit 1
  fi
  echo "  [OK] HEIC -> PNG (soundboard.heic)"
fi
echo "::endgroup::"

echo ""
echo "=== Verification passed ==="
