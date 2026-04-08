#!/usr/bin/env bash
# package.sh — Package the ImageMagick build into a tarball for release
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_FILE="${VERSION_FILE:-${REPO_ROOT}/versions/default.json}"

PREFIX="${PREFIX:-/opt/imagemagick}"
IM_VERSION=$(jq -r '.imagemagick' "${VERSION_FILE}")
OS_TAG="${OS_TAG:-ubuntu22.04}"
ARCH="${ARCH:-$(uname -m)}"

ARCHIVE_NAME="imagemagick-${IM_VERSION}-${OS_TAG}-${ARCH}.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR:-/tmp}/${ARCHIVE_NAME}"

echo "=== Packaging ImageMagick ${IM_VERSION} ==="
echo "  Source : ${PREFIX}"
echo "  Archive: ${ARCHIVE_PATH}"

# Collect license files from source directories into LICENSES/ inside PREFIX
BUILD_DIR="${BUILD_DIR:-/tmp/imagemagick-build}"
LICENSES_DIR="${PREFIX}/LICENSES"
mkdir -p "${LICENSES_DIR}"
trap 'rm -rf "${LICENSES_DIR}"' EXIT

collect_license() {
  local name="$1"
  local src_dir="$2"
  if [ ! -d "${src_dir}" ]; then
    echo "  WARNING: source dir not found, skipping license for ${name}: ${src_dir}"
    return
  fi
  for fname in LICENSE LICENSE.md LICENSE.txt COPYING COPYING.txt NOTICE NOTICE.md COPYRIGHT; do
    if [ -f "${src_dir}/${fname}" ]; then
      cp "${src_dir}/${fname}" "${LICENSES_DIR}/${name}.txt"
      echo "  License: ${name} (${fname})"
      return
    fi
  done
  echo "  WARNING: no license file found for ${name} in ${src_dir}"
}

echo "::group::Collecting licenses"
collect_license "libjpeg-turbo" "${BUILD_DIR}/libjpeg-turbo"
collect_license "libpng"        "${BUILD_DIR}/libpng"
collect_license "libtiff"       "${BUILD_DIR}/libtiff"
collect_license "lcms2"         "${BUILD_DIR}/lcms2"
collect_license "libaom"        "${BUILD_DIR}/libaom"
collect_license "libwebp"       "${BUILD_DIR}/libwebp"
collect_license "libheif"       "${BUILD_DIR}/libheif"
collect_license "ImageMagick"   "${BUILD_DIR}/imagemagick"
echo "::endgroup::"

# Create tarball with directory structure: imagemagick/<version>/...
PARENT="$(dirname "${PREFIX}")"
BASE="$(basename "${PREFIX}")"

echo "::group::Creating tarball"
tar -czf "${ARCHIVE_PATH}" \
  -C "${PARENT}" \
  --transform "s|^${BASE}|imagemagick/${IM_VERSION}|" \
  "${BASE}"

echo "  Size   : $(du -sh "${ARCHIVE_PATH}" | cut -f1)"
echo "::endgroup::"
echo "=== Package complete: ${ARCHIVE_PATH} ==="

# Export path for use in CI
echo "ARCHIVE_PATH=${ARCHIVE_PATH}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
echo "ARCHIVE_NAME=${ARCHIVE_NAME}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
