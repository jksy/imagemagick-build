#!/usr/bin/env bash
set -euo pipefail

# Build ImageMagick and required dependencies into a single prefix.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${VERSIONS_FILE:-$ROOT_DIR/versions/default.json}"
PREFIX="${PREFIX:-/opt/imagemagick}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.build}"
JOBS="${JOBS:-$(nproc)}"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required to parse ${VERSIONS_FILE}" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR" "$PREFIX"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export PATH="$PREFIX/bin:${PATH}"

read_version() {
  jq -r ".$1" "$VERSIONS_FILE"
}

fetch_and_extract() {
  local url="$1"
  local archive="$2"
  local dir="$3"

  mkdir -p "$BUILD_DIR/src"
  if [[ ! -f "$BUILD_DIR/src/$archive" ]]; then
    curl -fL "$url" -o "$BUILD_DIR/src/$archive"
  fi

  rm -rf "$BUILD_DIR/$dir"
  mkdir -p "$BUILD_DIR/$dir"
  tar -xf "$BUILD_DIR/src/$archive" -C "$BUILD_DIR/$dir" --strip-components=1
}

build_libjpeg_turbo() {
  local ver
  ver="$(read_version libjpeg_turbo)"
  fetch_and_extract \
    "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${ver}.tar.gz" \
    "libjpeg-turbo-${ver}.tar.gz" \
    "libjpeg-turbo-${ver}"

  cmake -S "$BUILD_DIR/libjpeg-turbo-${ver}" -B "$BUILD_DIR/libjpeg-turbo-${ver}/build" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DENABLE_SHARED=1 \
    -DENABLE_STATIC=0
  cmake --build "$BUILD_DIR/libjpeg-turbo-${ver}/build" -j"$JOBS"
  cmake --install "$BUILD_DIR/libjpeg-turbo-${ver}/build"
}

build_libpng() {
  local ver
  ver="$(read_version libpng)"
  fetch_and_extract \
    "https://download.sourceforge.net/libpng/libpng-${ver}.tar.gz" \
    "libpng-${ver}.tar.gz" \
    "libpng-${ver}"

  (cd "$BUILD_DIR/libpng-${ver}" && ./configure --prefix="$PREFIX")
  make -C "$BUILD_DIR/libpng-${ver}" -j"$JOBS"
  make -C "$BUILD_DIR/libpng-${ver}" install
}

build_libtiff() {
  local ver
  ver="$(read_version libtiff)"
  fetch_and_extract \
    "https://download.osgeo.org/libtiff/tiff-${ver}.tar.gz" \
    "tiff-${ver}.tar.gz" \
    "libtiff-${ver}"

  cmake -S "$BUILD_DIR/libtiff-${ver}" -B "$BUILD_DIR/libtiff-${ver}/build" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DBUILD_SHARED_LIBS=ON
  cmake --build "$BUILD_DIR/libtiff-${ver}/build" -j"$JOBS"
  cmake --install "$BUILD_DIR/libtiff-${ver}/build"
}

build_lcms2() {
  local ver
  ver="$(read_version lcms2)"
  fetch_and_extract \
    "https://github.com/mm2/Little-CMS/releases/download/lcms${ver}/lcms2-${ver}.tar.gz" \
    "lcms2-${ver}.tar.gz" \
    "lcms2-${ver}"

  (cd "$BUILD_DIR/lcms2-${ver}" && ./configure --prefix="$PREFIX")
  make -C "$BUILD_DIR/lcms2-${ver}" -j"$JOBS"
  make -C "$BUILD_DIR/lcms2-${ver}" install
}

build_libaom() {
  local ver
  ver="$(read_version libaom)"
  fetch_and_extract \
    "https://storage.googleapis.com/aom-releases/libaom-${ver}.tar.gz" \
    "libaom-${ver}.tar.gz" \
    "libaom-${ver}"

  cmake -S "$BUILD_DIR/libaom-${ver}" -B "$BUILD_DIR/libaom-${ver}/build" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DBUILD_SHARED_LIBS=1 \
    -DENABLE_TESTS=0
  cmake --build "$BUILD_DIR/libaom-${ver}/build" -j"$JOBS"
  cmake --install "$BUILD_DIR/libaom-${ver}/build"
}

build_libwebp() {
  local ver
  ver="$(read_version libwebp)"
  fetch_and_extract \
    "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${ver}.tar.gz" \
    "libwebp-${ver}.tar.gz" \
    "libwebp-${ver}"

  (cd "$BUILD_DIR/libwebp-${ver}" && ./configure --prefix="$PREFIX" --enable-shared --disable-static)
  make -C "$BUILD_DIR/libwebp-${ver}" -j"$JOBS"
  make -C "$BUILD_DIR/libwebp-${ver}" install
}

build_libheif() {
  local ver
  ver="$(read_version libheif)"
  fetch_and_extract \
    "https://github.com/strukturag/libheif/releases/download/v${ver}/libheif-${ver}.tar.gz" \
    "libheif-${ver}.tar.gz" \
    "libheif-${ver}"

  cmake -S "$BUILD_DIR/libheif-${ver}" -B "$BUILD_DIR/libheif-${ver}/build" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DWITH_AOM=ON \
    -DWITH_X265=OFF \
    -DWITH_DAV1D=OFF
  cmake --build "$BUILD_DIR/libheif-${ver}/build" -j"$JOBS"
  cmake --install "$BUILD_DIR/libheif-${ver}/build"
}

build_imagemagick() {
  local ver
  ver="$(read_version imagemagick)"
  fetch_and_extract \
    "https://github.com/ImageMagick/ImageMagick/archive/refs/tags/${ver}.tar.gz" \
    "ImageMagick-${ver}.tar.gz" \
    "ImageMagick-${ver}"

  (cd "$BUILD_DIR/ImageMagick-${ver}" && ./configure \
    --prefix="$PREFIX" \
    --with-heic=yes \
    --with-webp=yes \
    --enable-shared \
    --disable-static)
  make -C "$BUILD_DIR/ImageMagick-${ver}" -j"$JOBS"
  make -C "$BUILD_DIR/ImageMagick-${ver}" install
}

main() {
  build_libjpeg_turbo
  build_libpng
  build_libtiff
  build_lcms2
  build_libaom
  build_libwebp
  build_libheif
  build_imagemagick

  echo "Build finished. Installed at: $PREFIX"
}

main "$@"
