#!/usr/bin/env bash
set -euo pipefail

REPO="jksy/imagemagick-build"
INSTALL_BASE="${IMAGEMAGICK_INSTALL_BASE:-/opt}"

# OS check
if [[ ! -f /etc/os-release ]]; then
  echo "Error: /etc/os-release not found. Only Ubuntu is supported." >&2
  exit 1
fi
# shellcheck source=/dev/null
source /etc/os-release
UBUNTU_VERSION="${VERSION_ID:-}"

case "$UBUNTU_VERSION" in
  22.04|24.04) ;;
  *) echo "Error: Unsupported Ubuntu version: $UBUNTU_VERSION (supported: 22.04, 24.04)" >&2; exit 1 ;;
esac

# Architecture detection
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|aarch64) ;;
  *) echo "Error: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

echo "Detected: Ubuntu ${UBUNTU_VERSION} / ${ARCH}"

# Fetch latest release asset URL
echo "Fetching latest release from GitHub..."
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")
ASSET_URL=$(echo "$RELEASE_JSON" \
  | grep '"browser_download_url"' \
  | grep "ubuntu${UBUNTU_VERSION}-${ARCH}" \
  | cut -d'"' -f4)

if [[ -z "$ASSET_URL" ]]; then
  echo "Error: No matching asset found for Ubuntu ${UBUNTU_VERSION} ${ARCH}" >&2
  exit 1
fi

TARBALL=$(basename "$ASSET_URL")
IM_VERSION=$(echo "$TARBALL" | sed 's/imagemagick-\(.*\)-ubuntu.*/\1/')

echo "Installing ImageMagick ${IM_VERSION}..."
echo "  Source:      ${ASSET_URL}"
echo "  Destination: ${INSTALL_BASE}/imagemagick/${IM_VERSION}/"

# Download to temp dir
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL --progress-bar -o "${TMP_DIR}/${TARBALL}" "$ASSET_URL"

# Extract (use sudo if INSTALL_BASE is not writable)
if [[ -w "$INSTALL_BASE" ]] || [[ ! -e "$INSTALL_BASE" && -w "$(dirname "$INSTALL_BASE")" ]]; then
  mkdir -p "$INSTALL_BASE"
  tar -xzf "${TMP_DIR}/${TARBALL}" -C "$INSTALL_BASE"
else
  echo "No write permission to ${INSTALL_BASE}, using sudo..."
  sudo mkdir -p "$INSTALL_BASE"
  sudo tar -xzf "${TMP_DIR}/${TARBALL}" -C "$INSTALL_BASE"
fi

BIN_DIR="${INSTALL_BASE}/imagemagick/${IM_VERSION}/bin"
LIB_DIR="${INSTALL_BASE}/imagemagick/${IM_VERSION}/lib"

echo ""
echo "ImageMagick ${IM_VERSION} installed successfully!"
echo ""
echo "Add the following to your shell profile (~/.bashrc or ~/.zshrc):"
echo ""
echo "  export PATH=\"${BIN_DIR}:\$PATH\""
echo "  export LD_LIBRARY_PATH=\"${LIB_DIR}:\$LD_LIBRARY_PATH\""
echo "  export PKG_CONFIG_PATH=\"${LIB_DIR}/pkgconfig:\$PKG_CONFIG_PATH\""
echo ""
echo "Then reload your shell and run: magick -version"
