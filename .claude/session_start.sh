#!/usr/bin/env bash
# Claude Code SessionStart hook: inject the vault entry points so every session starts oriented.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
f=WalletMelt/00-Control/Current-Project-State.md
[ -f "$f" ] || exit 0
echo "WalletMelt vault is authoritative for intent/architecture; code is authoritative for behavior. Docs guard: code changes need matching WalletMelt/ updates (see AGENTS.md). Current state note follows."
cat "$f"
