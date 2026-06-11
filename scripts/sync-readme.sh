#!/usr/bin/env bash
# Regenerate the auto-managed sections of README.md from libraries.json:
#   * the "Bundled Libraries" table
#   * the "Supported Formats" line
# Usage:
#   scripts/sync-readme.sh           # rewrite README.md in place
#   scripts/sync-readme.sh --check   # exit 1 if README.md is out of sync (no write)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARIES_JSON="${REPO_ROOT}/libraries.json"
README="${REPO_ROOT}/README.md"
LIB_START_MARKER="<!-- BUNDLED_LIBRARIES_START -->"
LIB_END_MARKER="<!-- BUNDLED_LIBRARIES_END -->"
FORMATS_START_MARKER="<!-- SUPPORTED_FORMATS_START -->"
FORMATS_END_MARKER="<!-- SUPPORTED_FORMATS_END -->"

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=true
elif [ -n "${1:-}" ]; then
  echo "Unknown argument: $1" >&2
  echo "Usage: $0 [--check]" >&2
  exit 2
fi

for marker in "${LIB_START_MARKER}" "${LIB_END_MARKER}" \
              "${FORMATS_START_MARKER}" "${FORMATS_END_MARKER}"; do
  if ! grep -qF "${marker}" "${README}"; then
    echo "ERROR: README.md is missing the ${marker} marker." >&2
    exit 2
  fi
done

TABLE=$(jq -r '
  ["| Library | Version |", "|---|---|"] +
  [.[] | select(.bundled == true) | "| \(.name) | \(.version) |"]
  | .[]
' "${LIBRARIES_JSON}")

# Base formats are always produced by the build. RAW is appended only when
# LibRaw is bundled (its presence in libraries.json), so the line stays in
# sync automatically as libraries.json changes — no manual editing needed.
FORMATS="JPEG, PNG, TIFF, WebP, AVIF, HEIC (read), PDF"
if jq -e '.[] | select(.key == "libraw")' "${LIBRARIES_JSON}" >/dev/null 2>&1; then
  FORMATS="${FORMATS}, RAW (read: DNG, CR2/CR3, NEF, ARW, RAF, ORF, RW2, PEF, SRW, ほか — via LibRaw)"
fi

# Replace everything between a START/END marker pair with the given content.
replace_block() {
  local content="$1" start="$2" end="$3" body="$4"
  awk -v start="${start}" -v end="${end}" -v body="${body}" '
    $0 == start { print; print body; in_block = 1; next }
    $0 == end   { print; in_block = 0; next }
    !in_block   { print }
  ' <<<"${content}"
}

NEW_README=$(cat "${README}")
NEW_README=$(replace_block "${NEW_README}" "${LIB_START_MARKER}" "${LIB_END_MARKER}" "${TABLE}")
NEW_README=$(replace_block "${NEW_README}" "${FORMATS_START_MARKER}" "${FORMATS_END_MARKER}" "${FORMATS}")

if [ "${CHECK_ONLY}" = true ]; then
  if ! diff -u "${README}" <(printf '%s\n' "${NEW_README}") >/dev/null; then
    echo "README.md is out of sync with libraries.json. Run: scripts/sync-readme.sh" >&2
    diff -u "${README}" <(printf '%s\n' "${NEW_README}") || true
    exit 1
  fi
  exit 0
fi

printf '%s\n' "${NEW_README}" > "${README}"
