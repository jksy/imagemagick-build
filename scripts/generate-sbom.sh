#!/usr/bin/env bash
# Generate a CycloneDX 1.4 JSON SBOM from versions/default.json.
#
# Usage:
#   VERSION_FILE=<path> OS_TAG=<os> ARCH=<arch> bash scripts/generate-sbom.sh <output.sbom.json>
#
# Bundled libraries (compiled from source, included in tarball):
#   ImageMagick, libjpeg-turbo, libpng, libtiff, lcms2, libwebp, libaom, libheif
#
# System runtime dependencies (NOT bundled, scope=optional):
#   ghostscript (PDF support), freetype, zlib
set -euo pipefail

OUTPUT="${1:?Usage: VERSION_FILE=<path> OS_TAG=<os> ARCH=<arch> $0 <output.sbom.json>}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --arg ts        "$TIMESTAMP" \
  --arg name      "imagemagick-$(jq -r '.imagemagick' "$VERSION_FILE")-${OS_TAG}-${ARCH}" \
  --argjson v     "$(cat "$VERSION_FILE")" \
  '{
    bomFormat:   "CycloneDX",
    specVersion: "1.4",
    version:     1,
    metadata: {
      timestamp: $ts,
      component: {
        type:    "application",
        name:    $name,
        version: $v.imagemagick
      }
    },
    components: [
      {
        type:    "library",
        name:    "ImageMagick",
        version: $v.imagemagick,
        purl:    ("pkg:github/ImageMagick/ImageMagick@" + $v.imagemagick)
      },
      {
        type:    "library",
        name:    "libjpeg-turbo",
        version: $v.libjpeg_turbo,
        purl:    ("pkg:github/libjpeg-turbo/libjpeg-turbo@" + $v.libjpeg_turbo)
      },
      {
        type:    "library",
        name:    "libpng",
        version: $v.libpng,
        purl:    ("pkg:github/glennrp/libpng@" + $v.libpng)
      },
      {
        type:    "library",
        name:    "libtiff",
        version: $v.libtiff,
        purl:    ("pkg:gitlab/libtiff/libtiff@" + $v.libtiff)
      },
      {
        type:    "library",
        name:    "lcms2",
        version: $v.lcms2,
        purl:    ("pkg:github/mm2/Little-CMS@" + $v.lcms2)
      },
      {
        type:    "library",
        name:    "libwebp",
        version: $v.libwebp,
        purl:    ("pkg:github/webmproject/libwebp@" + $v.libwebp)
      },
      {
        type:    "library",
        name:    "libaom",
        version: $v.libaom,
        purl:    ("pkg:github/AOMediaCodec/libaom@" + $v.libaom)
      },
      {
        type:    "library",
        name:    "libheif",
        version: $v.libheif,
        purl:    ("pkg:github/strukturag/libheif@" + $v.libheif)
      },
      {
        type:        "library",
        name:        "ghostscript",
        scope:       "optional",
        description: "System-provided runtime dependency for PDF support. Not bundled in the tarball; version depends on the host OS."
      },
      {
        type:        "library",
        name:        "freetype",
        scope:       "optional",
        description: "System-provided runtime dependency. Not bundled in the tarball."
      },
      {
        type:        "library",
        name:        "zlib",
        scope:       "optional",
        description: "System-provided runtime dependency. Not bundled in the tarball."
      }
    ]
  }' > "$OUTPUT"
