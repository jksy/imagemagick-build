#!/usr/bin/env bash
# Generate a CycloneDX 1.4 JSON SBOM from libraries.json.
#
# Usage:
#   OS_TAG=<os> ARCH=<arch> bash scripts/generate-sbom.sh <output.sbom.json>
#
# Bundled libraries are read from libraries.json.
# System runtime dependencies (NOT bundled, scope=optional) are marked accordingly.
set -euo pipefail

OUTPUT="${1:?Usage: OS_TAG=<os> ARCH=<arch> $0 <output.sbom.json>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIBRARIES_FILE="${LIBRARIES_FILE:-${REPO_ROOT}/libraries.json}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
IM_VERSION=$(jq -r '.[] | select(.key == "imagemagick") | .version' "${LIBRARIES_FILE}")

jq -n \
  --arg ts        "$TIMESTAMP" \
  --arg name      "imagemagick-${IM_VERSION}-${OS_TAG}-${ARCH}" \
  --slurpfile libs "${LIBRARIES_FILE}" \
  '{
    bomFormat:   "CycloneDX",
    specVersion: "1.4",
    version:     1,
    metadata: {
      timestamp: $ts,
      component: {
        type:    "application",
        name:    $name,
        version: "'${IM_VERSION}'"
      }
    },
    components: (
      [
        ($libs[0][] | select(.bundled == true) | {
          type:    "library",
          name:    .name,
          version: .version,
          purl:    (.purl_base + "@" + .version)
        }),
        ($libs[0][] | select(.bundled == false) | {
          type:        "library",
          name:        .name,
          scope:       .scope,
          description: .description
        })
      ]
    )
  }' > "$OUTPUT"
