# リリースフロー

## タグ命名規則

| パターン | 例 | 用途 |
|---|---|---|
| `v{IM_VERSION}` | `v7.1.2-19` | ImageMagick バージョンアップ時の正規リリース |
| `v{IM_VERSION}-{YYYYMMDD}` | `v7.1.2-18-20260415` | ライブラリのみ更新時のスナップショット |
| `v{IM_VERSION}-{YYYYMMDD}-{N}` | `v7.1.2-18-20260415-2` | 同日に複数回スナップショットが作られた場合 |

---

## ケース 1: ImageMagick バージョンアップ（自動・毎週月曜）

```
check-new-version.yml（毎週月曜 09:00 UTC に起動）
  └─ 最新バージョンを検出
  └─ bump/imagemagick-{NEW} ブランチを作成・push
  └─ main への PR を作成（タグはまだ作らない）

↓ CI（ci.yml）が PR を検証

↓ PR をマージ

rebuild-on-library-update.yml（main への push を検知）
  └─ IM バージョン変更を検出
  └─ v{NEW} タグを作成・push

↓ build.yml（v* タグで起動）

  build ジョブ: 6プラットフォーム並列ビルド
    Ubuntu 22.04 / 24.04 × x86_64 / aarch64
    Amazon Linux 2023  × x86_64 / aarch64

  release ジョブ: GitHub Release を作成（tar.gz + SBOM）

  attest ジョブ: ビルド来歴の attestation を生成
```

**タグ形式:** `v7.1.2-19`

---

## ケース 2: ライブラリのみ更新（Renovate による自動 PR）

```
Renovate
  └─ libraries.json を更新する PR を作成

↓ CI が PR を検証

↓ PR をマージ

rebuild-on-library-update.yml（main への push を検知）
  └─ IM バージョンは変わっていないことを確認
  └─ 日付付きスナップショットタグを作成・push（v{IM_VERSION}-{YYYYMMDD}）

↓ build.yml（v* タグで起動）

  build / release / attest ジョブ（ケース 1 と同様）

  release ジョブ追加処理:
    └─ ローリングリリース v{IM_VERSION} のアセットも上書き更新
```

**タグ形式:** `v7.1.2-18-20260415`

> スナップショットリリースは独立した GitHub Release として作成される。
> さらにローリングリリース（`v7.1.2-18`）のアセットも最新に上書きされるため、
> バージョンを固定せずインストールするユーザーは常に最新ライブラリ入りを取得できる。

---

## ケース 3: 特定バージョンの手動ビルド

Actions タブから `Check for new ImageMagick release` を `workflow_dispatch` で起動し、
`version` 入力欄にビルドしたいバージョン（例: `7.1.2-10`）を指定する。

```
check-new-version.yml（workflow_dispatch）
  └─ 指定バージョンを一時ブランチ build-{VERSION} でコミット
  └─ タグ v{VERSION} のみ push（main・PR は作らない）

↓ build.yml（v* タグで起動）

  build / release / attest ジョブ（ケース 1 と同様）
```

**タグ形式:** `v7.1.2-10`（正規リリースと同じ形式）

> main は変更されない。過去バージョンや緊急ビルドに使う。

---

## 関連ワークフロー早見表

| ファイル | トリガー | 役割 |
|---|---|---|
| `check-new-version.yml` | 毎週月曜 / 手動 | IM バージョン検出・bump ブランチ作成・PR 作成 |
| `rebuild-on-library-update.yml` | main への push（libraries.json 変更時） | タグ作成（IM バージョンアップ時は `v{NEW}`、ライブラリのみ更新時は日付付き） |
| `build.yml` | `v*` タグ push / main への push / 手動 | ビルド・リリース・attestation |
| `ci.yml` | main への PR | lint・shellcheck など基本検証 |
| `test-installer.yml` | install.sh 変更を含む PR | インストールスクリプトの動作確認 |
