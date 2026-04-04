# imagemagick-build

[![Build](https://github.com/jksy/imagemagick-build/actions/workflows/build.yml/badge.svg)](https://github.com/jksy/imagemagick-build/actions/workflows/build.yml)
[![Latest Release](https://img.shields.io/github/v/release/jksy/imagemagick-build)](https://github.com/jksy/imagemagick-build/releases/latest)

## Overview

This repository builds [ImageMagick](https://imagemagick.org/) from source with all required libraries statically bundled, and publishes pre-built tarballs for Ubuntu 22.04 and 24.04 (x86\_64) as GitHub Releases. New ImageMagick versions are detected automatically every week and released without manual intervention.

---

このリポジトリは [ImageMagick](https://imagemagick.org/) を必要なライブラリごとソースからビルドし、Ubuntu 22.04 / 24.04 (x86\_64) 向けの事前ビルド済みアーカイブを GitHub Releases として公開します。新しい ImageMagick バージョンは毎週自動的に検出され、手動操作なしにリリースされます。

## Supported Formats / 対応フォーマット

JPEG, PNG, TIFF, WebP, AVIF, PDF

## Bundled Libraries / 同梱ライブラリ

| Library | Version |
|---|---|
| ImageMagick | 7.1.2-13 |
| libjpeg-turbo | 3.0.3 |
| libpng | 1.6.43 |
| libtiff | 4.7.0 |
| lcms2 | 2.16 |
| libwebp | 1.4.0 |
| libaom | 3.9.1 |
| libheif | 1.18.1 |

> Versions are managed in [`versions/default.json`](versions/default.json).

## Usage: Download Pre-built Binary

> **For GitHub Actions users:** [jksy/setup-imagemagick](https://github.com/jksy/setup-imagemagick) provides a ready-to-use action that downloads and sets up ImageMagick from these releases automatically.
>
> **GitHub Actions をお使いの場合:** [jksy/setup-imagemagick](https://github.com/jksy/setup-imagemagick) を使うと、このリリースから ImageMagick を自動でセットアップできます。

Download the tarball for your Ubuntu version from the [Releases page](https://github.com/jksy/imagemagick-build/releases), then extract and set environment variables:

```bash
# Example for Ubuntu 22.04
tar -xzf imagemagick-7.1.2-13-ubuntu22.04-x86_64.tar.gz -C /opt

export PATH="/opt/imagemagick/7.1.2-13/bin:$PATH"
export PKG_CONFIG_PATH="/opt/imagemagick/7.1.2-13/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="/opt/imagemagick/7.1.2-13/lib:$LD_LIBRARY_PATH"

magick -version
```

---

[Releases ページ](https://github.com/jksy/imagemagick-build/releases) から対象の Ubuntu バージョン向けアーカイブをダウンロードし、展開して環境変数を設定するだけで使えます。

```bash
# Ubuntu 22.04 の例
tar -xzf imagemagick-7.1.2-13-ubuntu22.04-x86_64.tar.gz -C /opt

export PATH="/opt/imagemagick/7.1.2-13/bin:$PATH"
export PKG_CONFIG_PATH="/opt/imagemagick/7.1.2-13/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="/opt/imagemagick/7.1.2-13/lib:$LD_LIBRARY_PATH"

magick -version
```

## Build Manually / ローカルでのビルド方法

### Prerequisites / 必要なパッケージ

```bash
sudo apt-get install -y \
  build-essential git cmake nasm ninja-build \
  autoconf automake libtool pkg-config jq \
  ghostscript zlib1g-dev ca-certificates
```

### Build / ビルド

```bash
git clone https://github.com/jksy/imagemagick-build.git
cd imagemagick-build

# Build all libraries and ImageMagick
VERSION_FILE=versions/default.json PREFIX=/opt/imagemagick bash scripts/build.sh

# Run verification smoke tests
PREFIX=/opt/imagemagick bash scripts/verify.sh
```

### Package / パッケージ化

```bash
VERSION_FILE=versions/default.json \
  UBUNTU_VERSION=22.04 \
  PREFIX=/opt/imagemagick \
  ARCHIVE_DIR=/tmp/artifacts \
  bash scripts/package.sh
```

The output tarball will be at `/tmp/artifacts/imagemagick-<version>-ubuntu22.04-x86_64.tar.gz`.

出力ファイルは `/tmp/artifacts/imagemagick-<version>-ubuntu22.04-x86_64.tar.gz` に生成されます。

## How Automation Works / 自動化の仕組み

| Workflow | Trigger | Description |
|---|---|---|
| [`build.yml`](.github/workflows/build.yml) | Push to `main`, tag push, manual | Builds for Ubuntu 22.04 & 24.04, creates GitHub Release on tag push |
| [`check-new-version.yml`](.github/workflows/check-new-version.yml) | Weekly (Mon 09:00 UTC), manual | Detects latest ImageMagick release, bumps `versions/default.json`, pushes a new tag |
| [`ci.yml`](.github/workflows/ci.yml) | Pull request to `main` | Lints workflows with actionlint and runs a test build |

The typical automated flow:

1. `check-new-version.yml` detects a new upstream release → updates `versions/default.json` → pushes tag `vX.Y.Z-N`
2. The tag push triggers `build.yml` → compiles on both Ubuntu versions → publishes a GitHub Release with the tarballs attached

---

自動化の典型的なフローは以下の通りです。

1. `check-new-version.yml` が新しいアップストリームリリースを検出 → `versions/default.json` を更新 → タグ `vX.Y.Z-N` をプッシュ
2. タグのプッシュにより `build.yml` がトリガー → 両 Ubuntu バージョンでコンパイル → アーカイブ付きで GitHub Release を公開