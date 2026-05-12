#!/usr/bin/env bash
# Regenerate the "Bundled Libraries" table in README.md from libraries.json.
# Usage:
#   scripts/sync-readme.sh           # rewrite README.md in place
#   scripts/sync-readme.sh --check   # exit 1 if README.md is out of sync (no write)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARIES_JSON="${REPO_ROOT}/libraries.json"
README="${REPO_ROOT}/README.md"
START_MARKER="<!-- BUNDLED_LIBRARIES_START -->"
END_MARKER="<!-- BUNDLED_LIBRARIES_END -->"

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=true
elif [ -n "${1:-}" ]; then
  echo "Unknown argument: $1" >&2
  echo "Usage: $0 [--check]" >&2
  exit 2
fi

if ! grep -qF "${START_MARKER}" "${README}" || ! grep -qF "${END_MARKER}" "${README}"; then
  echo "ERROR: README.md is missing ${START_MARKER} / ${END_MARKER} markers." >&2
  exit 2
fi

TABLE=$(jq -r '
  ["| Library | Version |", "|---|---|"] +
  [.[] | select(.bundled == true) | "| \(.name) | \(.version) |"]
  | .[]
' "${LIBRARIES_JSON}")

NEW_README=$(awk -v start="${START_MARKER}" -v end="${END_MARKER}" -v table="${TABLE}" '
  $0 == start {
    print
    print table
    in_block = 1
    next
  }
  $0 == end {
    print
    in_block = 0
    next
  }
  !in_block { print }
' "${README}")

if [ "${CHECK_ONLY}" = true ]; then
  if ! diff -u "${README}" <(printf '%s\n' "${NEW_README}") >/dev/null; then
    echo "README.md is out of sync with libraries.json. Run: scripts/sync-readme.sh" >&2
    diff -u "${README}" <(printf '%s\n' "${NEW_README}") || true
    exit 1
  fi
  exit 0
fi

printf '%s\n' "${NEW_README}" > "${README}"
