#!/usr/bin/env bash
# build.sh — Build ImageMagick with all required dependencies
# Usage: LIBRARIES_FILE=libraries.json ./scripts/build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIBRARIES_FILE="${LIBRARIES_FILE:-${REPO_ROOT}/libraries.json}"

# ---------------------------------------------------------------------------
# Parse versions from libraries.json
# ---------------------------------------------------------------------------
IM_VERSION=$(jq -r '.[] | select(.key == "imagemagick") | .version' "${LIBRARIES_FILE}")
JPEG_VERSION=$(jq -r '.[] | select(.key == "libjpeg_turbo") | .version' "${LIBRARIES_FILE}")
PNG_VERSION=$(jq -r '.[] | select(.key == "libpng") | .version' "${LIBRARIES_FILE}")
TIFF_VERSION=$(jq -r '.[] | select(.key == "libtiff") | .version' "${LIBRARIES_FILE}")
LCMS_VERSION=$(jq -r '.[] | select(.key == "lcms2") | .version' "${LIBRARIES_FILE}")
WEBP_VERSION=$(jq -r '.[] | select(.key == "libwebp") | .version' "${LIBRARIES_FILE}")
AOM_VERSION=$(jq -r '.[] | select(.key == "libaom") | .version' "${LIBRARIES_FILE}")
DE265_VERSION=$(jq -r '.[] | select(.key == "libde265") | .version' "${LIBRARIES_FILE}")
HEIF_VERSION=$(jq -r '.[] | select(.key == "libheif") | .version' "${LIBRARIES_FILE}")

echo "=== Build versions ==="
echo "  ImageMagick : ${IM_VERSION}"
echo "  libjpeg-turbo: ${JPEG_VERSION}"
echo "  libpng      : ${PNG_VERSION}"
echo "  libtiff     : ${TIFF_VERSION}"
echo "  lcms2       : ${LCMS_VERSION}"
echo "  libwebp     : ${WEBP_VERSION}"
echo "  libaom      : ${AOM_VERSION}"
echo "  libde265    : ${DE265_VERSION}"
echo "  libheif     : ${HEIF_VERSION}"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PREFIX="${PREFIX:-/opt/imagemagick}"
BUILD_DIR="${BUILD_DIR:-/tmp/imagemagick-build}"
NPROC=$(nproc 2>/dev/null || echo 4)

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
export LD_LIBRARY_PATH="${PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
clone_or_update() {
  local url="$1"
  local dir="$2"
  local ref="${3:-}"

  if [ -d "${dir}/.git" ]; then
    echo "  [skip clone] ${dir} already exists"
    return
  fi
  git clone --depth=1 ${ref:+--branch "${ref}"} "${url}" "${dir}"
}

# ---------------------------------------------------------------------------
# 1. libjpeg-turbo
# ---------------------------------------------------------------------------
echo "::group:: Building libjpeg-turbo ${JPEG_VERSION}"
clone_or_update https://github.com/libjpeg-turbo/libjpeg-turbo.git \
  libjpeg-turbo "${JPEG_VERSION}"
cmake -S libjpeg-turbo -B libjpeg-turbo/build \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DENABLE_SHARED=1 \
  -DENABLE_STATIC=0
cmake --build libjpeg-turbo/build -j"${NPROC}"
cmake --install libjpeg-turbo/build
echo "::endgroup::"

# ---------------------------------------------------------------------------
# 2. libpng
# ---------------------------------------------------------------------------
echo "::group::Building libpng ${PNG_VERSION}"
clone_or_update https://github.com/glennrp/libpng.git \
  libpng "v${PNG_VERSION}"
cd libpng
if [ ! -f configure ]; then
  autoreconf -fi
fi
./configure --prefix="${PREFIX}"
make -j"${NPROC}"
make install
cd "${BUILD_DIR}"
echo "::endgroup::"

# ---------------------------------------------------------------------------
# 3. libtiff
# ---------------------------------------------------------------------------
echo "::group::Building libtiff ${TIFF_VERSION}"
clone_or_update https://gitlab.com/libtiff/libtiff.git \
  libtiff "v${TIFF_VERSION}"
cmake -S libtiff -B libtiff/build \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_SHARED_LIBS=ON
cmake --build libtiff/build -j"${NPROC}"
cmake --install libtiff/build
echo "::endgroup::"

# ---------------------------------------------------------------------------
# 4. lcms2
# ---------------------------------------------------------------------------
echo "::group::Building lcms2 ${LCMS_VERSION}"
clone_or_update https://github.com/mm2/Little-CMS.git \
  lcms2 "lcms${LCMS_VERSION}"
cd lcms2
if [ ! -f configure ]; then
  autoreconf -fi
fi
./configure --prefix="${PREFIX}"
make -j"${NPROC}"
make install
cd "${BUILD_DIR}"
echo "::endgroup::"

# ---------------------------------------------------------------------------
# 5. libaom
# ---------------------------------------------------------------------------
echo "::group::Building libaom ${AOM_VERSION}"
clone_or_update https://aomedia.googlesource.com/aom \
  libaom "v${AOM_VERSION}"
cmake -S libaom -B libaom/build \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_SHARED_LIBS=1 \
  -DENABLE_TESTS=0
cmake --build libaom/build -j"${NPROC}"
cmake --install libaom/build
echo "::endgroup::"

# ---------------------------------------------------------------------------
# 6. libwebp
# ---------------------------------------------------------------------------
echo "::group::Building libwebp ${WEBP_VERSION}"
clone_or_update https://github.com/webmproject/libwebp.git \
  libwebp "v${WEBP_VERSION}"
cd libwebp
./autogen.sh || true
./configure --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${NPROC}"
make install
cd "${BUILD_DIR}"
echo "::endgroup::"

# ---------------------------------------------------------------------------
# 7. libde265
# ---------------------------------------------------------------------------
echo ""
echo "=== Building libde265 ${DE265_VERSION} ==="
clone_or_update https://github.com/strukturag/libde265.git \
  libde265 "v${DE265_VERSION}"
cd libde265
if [ ! -f configure ]; then
  autoreconf -fi
fi
./configure --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --disable-sherlock265
make -j"${NPROC}"
make install
cd "${BUILD_DIR}"

# ---------------------------------------------------------------------------
# 8. libheif
# ---------------------------------------------------------------------------
echo "::group::Building libheif ${HEIF_VERSION}"
clone_or_update https://github.com/strukturag/libheif.git \
  libheif "v${HEIF_VERSION}"
cmake -S libheif -B libheif/build \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DWITH_AOM_DECODER=ON \
  -DWITH_AOM_ENCODER=ON \
  -DWITH_LIBDE265=ON \
  -DWITH_X265=OFF \
  -DWITH_DAV1D=OFF \
  -DENABLE_TESTING=OFF
cmake --build libheif/build -j"${NPROC}"
cmake --install libheif/build
echo "::endgroup::"

# ---------------------------------------------------------------------------
# 9. ImageMagick
# ---------------------------------------------------------------------------
echo "::group::Building ImageMagick ${IM_VERSION}"
clone_or_update https://github.com/ImageMagick/ImageMagick.git \
  imagemagick "${IM_VERSION}"
cd imagemagick
./configure \
  --prefix="${PREFIX}" \
  --with-heic=yes \
  --with-webp=yes \
  --with-jpeg=yes \
  --with-png=yes \
  --with-tiff=yes \
  --with-lcms=yes \
  --with-gslib=yes \
  --enable-shared \
  --disable-static \
  --without-perl \
  --without-python \
  PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"
make -j"${NPROC}"
make install
echo "::endgroup::"

if [ "${SKIP_TESTS:-0}" != "1" ]; then
  echo "::group::Running ImageMagick test suite"
  make check VERBOSE=1 || {
    echo "ERROR: make check failed. Test log:" >&2
    if [ -f tests/test-suite.log ]; then
      cat tests/test-suite.log >&2
    fi
    exit 1
  }
  echo "=== Test suite passed ==="
  echo "::endgroup::"
fi

cd "${BUILD_DIR}"

echo "=== Build complete ==="
echo "  Installed to: ${PREFIX}"
