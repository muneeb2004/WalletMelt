#!/usr/bin/env bash
# WalletMelt docs guard: code changes must travel with vault (WalletMelt/) updates.
# Usage: docs_guard.sh staged   -> checks the git index (used by .githooks/commit-msg)
#        docs_guard.sh stale    -> checks file mtimes of dirty files (used by the Claude Stop hook)
# Exit 0 = ok, 1 = docs missing/stale (reason on stderr).
set -u
mode="${1:-staged}"
CODE_RE='^(lib/|android/|ios/|test/|integration_test/|scripts/|\.claude/|\.githooks/|pubspec\.yaml$)'
VAULT_RE='^WalletMelt/[^.]'

if [ "$mode" = staged ]; then
  files=$(git diff --cached --name-only)
else
  files=$(git status --porcelain -uall | sed -E 's/^...//; s/.* -> //')
fi

code=$(printf '%s\n' "$files" | grep -E "$CODE_RE" | grep -vE '/build/|\.gradle/' || true)
vault=$(printf '%s\n' "$files" | grep -E "$VAULT_RE" | grep -vE '^WalletMelt/\.obsidian/' || true)
[ -z "$code" ] && exit 0

if [ "$mode" = stale ]; then
  newest_vault=$(find WalletMelt -name '*.md' -not -path 'WalletMelt/.obsidian/*' -exec stat -c %Y {} + 2>/dev/null | sort -n | tail -1)
  newest_code=$(printf '%s\n' "$code" | while read -r f; do stat -c %Y "$f" 2>/dev/null; done | sort -n | tail -1)
  [ "${newest_code:-0}" -le "${newest_vault:-0}" ] && exit 0
  echo "Code changed after the last vault update. Update the relevant notes in WalletMelt/ (see scripts/docs_map.txt) and bump 'updated:' in their frontmatter. Changed code:" >&2
  printf '%s\n' "$code" | head -15 >&2
  exit 1
fi

fail=0
if [ -z "$vault" ]; then
  echo "docs-guard: code changed but no WalletMelt/ vault note is staged." >&2
  printf '%s\n' "$code" | head -15 >&2
  fail=1
fi

# Path -> required note rules, one per line in scripts/docs_map.txt: "regex => NoteFile.md"
if [ -f scripts/docs_map.txt ]; then
  while IFS= read -r line; do
    re=${line%% => *}; note=${line##* => }
    case "$line" in ''|\#*) continue;; esac
    if printf '%s\n' "$code" | grep -qE "$re" && ! printf '%s\n' "$vault" | grep -qF "/$note"; then
      echo "docs-guard: changes matching /$re/ require an update to $note" >&2
      fail=1
    fi
  done < scripts/docs_map.txt
fi

if [ $fail -eq 1 ]; then
  echo "docs-guard: update the vault, or add [skip-docs] to the commit message for changes with no doc impact." >&2
fi
exit $fail
