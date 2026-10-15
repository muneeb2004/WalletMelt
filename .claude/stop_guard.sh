#!/usr/bin/env bash
# Claude Code Stop hook: block ending a turn while code is newer than the vault.
input=$(cat)
echo "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0
[ "${WALLETMELT_SKIP_DOCS:-}" = 1 ] && exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
out=$(bash scripts/docs_guard.sh stale 2>&1) && exit 0
reason=$(printf '%s' "$out" | tr '\n' ' ' | sed 's/"/\\"/g')
printf '{"decision":"block","reason":"%s Update the vault (WalletMelt/) now, or tell the user why no doc change is needed."}\n' "$reason"
exit 0
