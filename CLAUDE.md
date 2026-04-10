# CLAUDE.md — imagemagick-build

ImageMagickを必要なライブラリごとソースからビルドし、Ubuntu 22.04/24.04 および Amazon Linux 2023 向けの事前ビルド済みアーカイブをGitHub Releasesとして公開する自動化リポジトリ。

## Key Files

- `libraries.json` — 全ライブラリのバージョン管理の単一ソース。Renovateが自動更新する（ImageMagick自体は除く）。
- `scripts/build.sh` — メインビルドスクリプト。`libraries.json` からバージョンを読み込み各ライブラリをソースビルドする。
- `scripts/verify.sh` — ビルド後の動作確認。`identify -list format` で対応フォーマットを検証。
- `scripts/package.sh` — `tar.gz` アーカイブ作成。
- `scripts/generate-sbom.sh` — SBOM (Software Bill of Materials) 生成。
- `install.sh` — エンドユーザー向けワンライナーインストールスクリプト。
- `.github/actions/build-imagemagick/action.yml` — ビルドを担う再利用可能コンポジットアクション。

## Workflows

| ファイル | トリガー | 目的 |
|---|---|---|
| `ci.yml` | PR to main | actionlint + マルチプラットフォームビルドテスト |
| `build.yml` | タグ push / main push / 手動 | ビルド・リリース・SLSA provenance生成 |
| `check-new-version.yml` | 毎週月曜 / 手動 | ImageMagick新バージョン検出・自動タグ付け |
| `rebuild-on-library-update.yml` | main pushでlibraries.json変更時 | Renovate更新後の自動リビルド |
| `test-installer.yml` | install.sh変更PR / 手動 | install.shの各OS動作確認 |

## リリースタグ命名規則

- `vX.Y.Z-N` — 通常リリース (例: `v7.1.2-18-1`)。`-N` はビルド番号。
- `vX.Y.Z-N-YYYYMMDD` — ライブラリのみ更新時のスナップショット。

## バージョン管理の注意

- **ImageMagickのバージョンは手動管理** — Renovate対象外。`check-new-version.yml` が自動検出してタグを打つ。
- **バンドルライブラリはRenovateが自動更新** — `libraries.json` のPR作成 → mainマージ → `rebuild-on-library-update.yml` が自動リビルド。

## よく使うコマンド

```bash
# ワークフローファイルのlint
actionlint .github/workflows/*.yml .github/actions/**/*.yml

# シェルスクリプトのチェック
shellcheck scripts/*.sh install.sh

# libraries.jsonの整合性確認
jq . libraries.json

# CI状況確認
gh pr checks <PR番号>

# 最新リリース確認
gh release list --limit 5
```

## Hooks (自動実行)

`.claude/settings.local.json` に以下のフックが設定されている:

- **actionlint**: `.github/workflows/` または `.github/actions/` 以下のYAMLファイル保存時に自動実行
- **shellcheck**: `.sh` ファイル保存時に自動実行
