#!/usr/bin/env python3
"""PreToolUse(Agent) hook: enforce Opus=advisor, Sonnet=main, Haiku=mechanical read-only sub-agents."""
import json, os, sys

ALLOWED = {"haiku-explorer", "Explore", "claude-code-guide"}
if os.environ.get("WALLETMELT_ALLOW_ANY_AGENT") == "1":
    sys.exit(0)
try:
    ti = json.load(sys.stdin).get("tool_input", {})
except Exception:
    sys.exit(0)
agent = ti.get("subagent_type") or "general-purpose"
model = (ti.get("model") or "haiku").lower()

def deny(reason):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
        "permissionDecision": "deny", "permissionDecisionReason": reason}}))
    sys.exit(0)

if agent not in ALLOWED:
    deny(f"Model routing policy (AGENTS.md): sub-agents are Haiku and STRICTLY mechanical read-only. "
         f"'{agent}' is not allowed; use haiku-explorer or Explore (model haiku), or do the work as the main Sonnet agent.")
if model != "haiku":
    deny(f"Model routing policy: sub-agents must run on haiku, not '{model}'. Opus is advisor-only; Sonnet is the main agent.")
