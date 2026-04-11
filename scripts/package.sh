#!/usr/bin/env bash
# package.sh — Package the ImageMagick build into a tarball for release
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIBRARIES_FILE="${LIBRARIES_FILE:-${REPO_ROOT}/libraries.json}"

PREFIX="${PREFIX:-/opt/imagemagick}"
IM_VERSION=$(jq -r '.[] | select(.key == "imagemagick") | .version' "${LIBRARIES_FILE}")
OS_TAG="${OS_TAG:-ubuntu22.04}"
ARCH="${ARCH:-$(uname -m)}"

ARCHIVE_NAME="imagemagick-${IM_VERSION}-${OS_TAG}-${ARCH}.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR:-/tmp}/${ARCHIVE_NAME}"

echo "=== Packaging ImageMagick ${IM_VERSION} ==="
echo "  Source : ${PREFIX}"
echo "  Archive: ${ARCHIVE_PATH}"

VERSIONS_FILE="${PREFIX}/VERSIONS"
trap 'rm -rf "${VERSIONS_FILE}"' EXIT

echo "::group::Generating VERSIONS file"
jq -r '.[] | select(.bundled == true) | "\(.name)=\(.version)"' "${LIBRARIES_FILE}" \
  > "${VERSIONS_FILE}"
cat "${VERSIONS_FILE}"
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
