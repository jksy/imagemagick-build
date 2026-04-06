# imagemagick-build

[![Build](https://github.com/jksy/imagemagick-build/actions/workflows/build.yml/badge.svg)](https://github.com/jksy/imagemagick-build/actions/workflows/build.yml)
[![Latest Release](https://img.shields.io/github/v/release/jksy/imagemagick-build)](https://github.com/jksy/imagemagick-build/releases/latest)

## Overview

This repository builds [ImageMagick](https://imagemagick.org/) from source with all required libraries statically bundled, and publishes pre-built tarballs for Ubuntu 22.04 and 24.04 (x86\_64 and aarch64) as GitHub Releases. New ImageMagick versions are detected automatically every week, and bundled library updates are also rebuilt automatically via Renovate.

---

このリポジトリは [ImageMagick](https://imagemagick.org/) を必要なライブラリごとソースからビルドし、Ubuntu 22.04 / 24.04 (x86\_64 / aarch64) 向けの事前ビルド済みアーカイブを GitHub Releases として公開します。新しい ImageMagick バージョンは毎週自動的に検出され、同梱ライブラリの更新も Renovate により自動的にリビルドされます。

## Supported Formats / 対応フォーマット

JPEG, PNG, TIFF, WebP, AVIF, PDF

## Bundled Libraries / 同梱ライブラリ

| Library | Version |
|---|---|
| ImageMagick | 7.1.2-18 |
| libjpeg-turbo | 3.0.3 |
| libpng | 1.6.43 |
| libtiff | 4.7.0 |
| lcms2 | 2.16 |
| libwebp | 1.4.0 |
| libaom | 3.9.1 |
| libheif | 1.18.1 |

> Versions are managed in [`versions/default.json`](versions/default.json).

## Quick Install

Ubuntu 22.04 / 24.04 (x86_64 / aarch64) に1行でインストールできます:

```bash
curl -fsSL https://raw.githubusercontent.com/jksy/imagemagick-build/main/install.sh | bash
```

特定バージョンを指定する場合 / To install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/jksy/imagemagick-build/main/install.sh | IMAGEMAGICK_VERSION=v7.1.2-18 bash
```

カスタムインストール先を指定する場合 / Custom install location:

```bash
curl -fsSL https://raw.githubusercontent.com/jksy/imagemagick-build/main/install.sh | IMAGEMAGICK_INSTALL_BASE=$HOME/.local bash
```

## Usage: Download Pre-built Binary

> **For GitHub Actions users:** [jksy/setup-imagemagick](https://github.com/jksy/setup-imagemagick) provides a ready-to-use action that downloads and sets up ImageMagick from these releases automatically.
>
> **GitHub Actions をお使いの場合:** [jksy/setup-imagemagick](https://github.com/jksy/setup-imagemagick) を使うと、このリリースから ImageMagick を自動でセットアップできます。

Download the tarball for your Ubuntu version from the [Releases page](https://github.com/jksy/imagemagick-build/releases), then extract and set environment variables:

```bash
# Example for Ubuntu 22.04
tar -xzf imagemagick-7.1.2-18-ubuntu22.04-x86_64.tar.gz -C /opt

export PATH="/opt/imagemagick/7.1.2-18/bin:$PATH"
export PKG_CONFIG_PATH="/opt/imagemagick/7.1.2-18/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="/opt/imagemagick/7.1.2-18/lib:$LD_LIBRARY_PATH"

magick -version
```

---

[Releases ページ](https://github.com/jksy/imagemagick-build/releases) から対象の Ubuntu バージョン向けアーカイブをダウンロードし、展開して環境変数を設定するだけで使えます。

```bash
# Ubuntu 22.04 の例
tar -xzf imagemagick-7.1.2-18-ubuntu22.04-x86_64.tar.gz -C /opt

export PATH="/opt/imagemagick/7.1.2-18/bin:$PATH"
export PKG_CONFIG_PATH="/opt/imagemagick/7.1.2-18/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="/opt/imagemagick/7.1.2-18/lib:$LD_LIBRARY_PATH"

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
| [`build.yml`](.github/workflows/build.yml) | Tag push (`v*`), manual | Builds for Ubuntu 22.04 & 24.04 (x86\_64 / aarch64), creates GitHub Release on tag push |
| [`check-new-version.yml`](.github/workflows/check-new-version.yml) | Weekly (Mon 09:00 UTC), manual | Detects latest ImageMagick release, bumps `versions/default.json`, pushes a new tag |
| [`rebuild-on-library-update.yml`](.github/workflows/rebuild-on-library-update.yml) | Push to `main` (when `versions/default.json` changes) | Detects library-only updates, creates a dated snapshot tag to trigger a rebuild |
| [`ci.yml`](.github/workflows/ci.yml) | Pull request to `main` | Lints workflows with actionlint and runs a test build |

### Release naming / リリースのタグ命名

| Tag | Description |
|---|---|
| `vX.Y.Z-N` | Rolling release — always points to the latest build for that ImageMagick version |
| `vX.Y.Z-N-YYYYMMDD` | Snapshot release — a pinned build created when bundled libraries are updated |

The typical automated flows:

**New ImageMagick version:**
1. `check-new-version.yml` detects a new upstream release → updates `versions/default.json` → pushes tag `vX.Y.Z-N`
2. The tag push triggers `build.yml` → compiles on all 4 platforms → publishes a GitHub Release

**Bundled library update (Renovate):**
1. Renovate merges a PR updating library versions in `versions/default.json`
2. `rebuild-on-library-update.yml` creates a dated snapshot tag `vX.Y.Z-N-YYYYMMDD`
3. The tag push triggers `build.yml` → compiles on all 4 platforms
4. The snapshot release `vX.Y.Z-N-YYYYMMDD` is published, and the rolling release `vX.Y.Z-N` is updated with the new artifacts

---

### ワークフローの説明

自動化の典型的なフローは以下の通りです。

**新しい ImageMagick バージョン:**
1. `check-new-version.yml` が新しいアップストリームリリースを検出 → `versions/default.json` を更新 → タグ `vX.Y.Z-N` をプッシュ
2. タグのプッシュにより `build.yml` がトリガー → 4プラットフォームでコンパイル → アーカイブ付きで GitHub Release を公開

**同梱ライブラリの更新（Renovate）:**
1. Renovate が `versions/default.json` のライブラリバージョンを更新する PR をマージ
2. `rebuild-on-library-update.yml` が日付付きスナップショットタグ `vX.Y.Z-N-YYYYMMDD` を作成
3. タグのプッシュにより `build.yml` がトリガー → 4プラットフォームでコンパイル
4. スナップショットリリース `vX.Y.Z-N-YYYYMMDD` が公開され、ローリングリリース `vX.Y.Z-N` の成果物も更新される