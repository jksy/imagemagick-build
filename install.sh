#!/usr/bin/env bash
set -euo pipefail

REPO="jksy/imagemagick-build"
INSTALL_BASE="${IMAGEMAGICK_INSTALL_BASE:-/opt}"

# OS check
if [[ ! -f /etc/os-release ]]; then
  echo "Error: /etc/os-release not found. Supported OS: Ubuntu 22.04/24.04, Amazon Linux 2023." >&2
  exit 1
fi
# shellcheck source=/dev/null
source /etc/os-release

OS_TAG=""
case "${ID:-}" in
  ubuntu)
    case "${VERSION_ID:-}" in
      22.04|24.04) OS_TAG="ubuntu${VERSION_ID}" ;;
      *) echo "Error: Unsupported Ubuntu version: ${VERSION_ID} (supported: 22.04, 24.04)" >&2; exit 1 ;;
    esac
    ;;
  amzn)
    case "${VERSION_ID:-}" in
      2023) OS_TAG="amzn2023" ;;
      *) echo "Error: Unsupported Amazon Linux version: ${VERSION_ID} (supported: 2023)" >&2; exit 1 ;;
    esac
    ;;
  *)
    echo "Error: Unsupported OS: ${ID:-unknown} (supported: Ubuntu 22.04/24.04, Amazon Linux 2023)" >&2
    exit 1
    ;;
esac

# Architecture detection
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|aarch64) ;;
  *) echo "Error: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

echo "Detected: ${PRETTY_NAME:-${ID} ${VERSION_ID}} / ${ARCH}"

# Fetch release asset URL (specific version or latest)
if [[ -n "${IMAGEMAGICK_VERSION:-}" ]]; then
  echo "Fetching release ${IMAGEMAGICK_VERSION} from GitHub..."
  RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/tags/${IMAGEMAGICK_VERSION}")
else
  echo "Fetching latest release from GitHub..."
  RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")
fi
ASSET_URL=$(echo "$RELEASE_JSON" \
  | grep '"browser_download_url"' \
  | grep "${OS_TAG}-${ARCH}" \
  | cut -d'"' -f4)

if [[ -z "$ASSET_URL" ]]; then
  echo "Error: No matching asset found for ${OS_TAG} ${ARCH}" >&2
  exit 1
fi

TARBALL=$(basename "$ASSET_URL")
IM_VERSION=$(echo "$TARBALL" | sed "s/^imagemagick-//" | sed "s/-${OS_TAG}-${ARCH}\.tar\.gz$//")

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
