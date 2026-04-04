# imagemagick-build

Build scripts for producing a reusable ImageMagick SDK tarball for RMagick/CI workloads.

## Scope

- OS: Ubuntu 24.04
- Architecture: x86_64
- libc: glibc
- ImageMagick: 7.1.2-13
- Required formats: JPEG / PNG / TIFF / WEBP / AVIF

## Versions

Pinned versions are stored in `versions/default.json`.

## Build

```bash
PREFIX=/opt/imagemagick ./scripts/build-imagemagick.sh
```

The build script installs everything into a single prefix and follows this order:

1. libjpeg-turbo
2. libpng
3. libtiff
4. lcms2
5. libaom
6. libwebp
7. libheif
8. ImageMagick

## Verify

```bash
PREFIX=/opt/imagemagick ./scripts/verify-imagemagick.sh
```

## RMagick smoke test

```bash
PREFIX=/opt/imagemagick ./scripts/verify-rmagick.sh
```

## Tarball layout

Expected output tree:

```text
imagemagick/
  7.1.2-13/
    bin/
    include/
    lib/
    lib/pkgconfig/
    share/
```

## GitHub Releases

A release workflow is available at `.github/workflows/release.yml`.

- Push a tag such as `v7.1.2-13-1` to build and publish assets to GitHub Releases.
- Or run the workflow manually (`workflow_dispatch`) and provide `release_tag`.

Published assets:

- `imagemagick-<version>-ubuntu-24.04-x86_64.tar.gz`
- `imagemagick-<version>-ubuntu-24.04-x86_64.tar.gz.sha256`
