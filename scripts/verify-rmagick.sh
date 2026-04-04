#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"

bundle init >/dev/null 2>&1 || true
if ! grep -q 'gem "rmagick"' Gemfile; then
  echo 'gem "rmagick"' >> Gemfile
fi
BUNDLE_PATH="$tmpdir/vendor/bundle" bundle install
ruby -e 'require "rmagick"; puts Magick::Magick_version'
