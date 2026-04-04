#!/usr/bin/env bash
# package.sh — Package the ImageMagick build into a tarball for release
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_FILE="${VERSION_FILE:-${REPO_ROOT}/versions/default.json}"

PREFIX="${PREFIX:-/opt/imagemagick}"
IM_VERSION=$(jq -r '.imagemagick' "${VERSION_FILE}")

ARCHIVE_NAME="imagemagick-${IM_VERSION}-ubuntu24.04-x86_64.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR:-/tmp}/${ARCHIVE_NAME}"

echo "=== Packaging ImageMagick ${IM_VERSION} ==="
echo "  Source : ${PREFIX}"
echo "  Archive: ${ARCHIVE_PATH}"

# Create tarball with directory structure: imagemagick/<version>/...
PARENT="$(dirname "${PREFIX}")"
BASE="$(basename "${PREFIX}")"

tar -czf "${ARCHIVE_PATH}" \
  -C "${PARENT}" \
  --transform "s|^${BASE}|imagemagick/${IM_VERSION}|" \
  "${BASE}"

echo "  Size   : $(du -sh "${ARCHIVE_PATH}" | cut -f1)"
echo "=== Package complete: ${ARCHIVE_PATH} ==="

# Export path for use in CI
echo "ARCHIVE_PATH=${ARCHIVE_PATH}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
echo "ARCHIVE_NAME=${ARCHIVE_NAME}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
