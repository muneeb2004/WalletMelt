---
type: protocol
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: control
related:
  - "[[Project-Constitution]]"
  - "[[Current-Project-State]]"
  - "[[Context-Loading-Guide]]"
---

# AI Engineering Protocol

## 1. Operating Cycle

Every AI session modifying or auditing the WalletMelt codebase must execute this standardized cycle:

```text
Orient (00-Control/Current-Project-State.md)
  ↓
Load Context (Follow 00-Control/Context-Loading-Guide.md)
  ↓
Inspect Implementation (Read relevant code files directly)
  ↓
Identify Constraints & Invariants (Check Constitution & ADRs)
  ↓
Plan Minimally (Create implementation plan if non-trivial)
  ↓
Implement Smallest Coherent Change
  ↓
Test & Verify (flutter analyze, flutter test, build scripts)
  ↓
Update Documentation & Record ADR if Architectural Decision was Made
  ↓
Report Structured Summary
```

## 2. Mandatory Rules of Engagement

1. **The Critical Operating Principle**:
   > The repository is the source of truth for implemented behavior. The Obsidian vault is the source of truth for project intent, constraints, decisions, architecture, and engineering governance. When they disagree, do not silently choose one. Identify the discrepancy, determine which artifact is authoritative for the specific question, and update the appropriate source after resolving the conflict.

2. **No Speculative Scope**:
   > Never expand project scope merely because an implementation possibility exists.

3. **No Unrelated Refactors**:
   > Never perform a speculative refactor while completing an unrelated task. Preserve working abstractions.

4. **Honest Rationale**:
   > Never invent historical reasoning. Unknown rationale must be explicitly recorded as `Historical rationale: Unknown.`

5. **Parsimony**:
   > Prefer the smallest coherent change that satisfies the requirement while preserving existing architecture and behavior.

6. **Toolchain Execution**:
   - Always invoke Flutter using PowerShell command syntax with the verified binary: `& "D:\flutter\bin\flutter.bat"`.
   - Before committing, verify `flutter analyze` has 0 warnings / 0 errors and targeted tests pass.

## 3. Drift Check Procedure
Before applying any non-trivial code modification, verify:
1. Is this requirement documented in `01-Product/`?
2. Does the proposed change violate any invariant in `[[Project-Constitution]]`?
3. Does an existing ADR in `04-Decisions/` govern this subsystem?
4. Does this change create a new architectural precedent requiring a new ADR?
5. Are database schemas or serialization contracts affected?
6. Does `[[Current-Project-State]]` need an update upon completion?

## 4. Mandatory Session Output Format
When concluding an engineering session, the AI agent must report:
- **Inspected Files**: What code and notes were read to ground the task.
- **Modifications**: Exact list of files changed and the rationale.
- **Intentionally Unchanged**: Areas considered but preserved to avoid drift.
- **Verification Results**: Static analysis status, test counts, and APK build metrics.
- **Documentation & Decision Updates**: Vault notes or ADRs created or revised.
- **Unresolved Risks**: Known debt or edge cases requiring user awareness.

## 5. Model Routing (user directive, 2026-10-15)
- **Opus = advisor**: consulted before approach is committed and before declaring done; does not do bulk work.
- **Sonnet = main agent**: all judgment, writing, code edits, strategy and guard logic.
- **Haiku = sub-agents, STRICTLY mechanical read-only work**: enumerating files/tables/routes, counting, listing claim-vs-code mismatches, looking up docs. Haiku never writes notes, strategy, code or guards.

## 6. Docs Guard (enforced, do not bypass silently)
- `.githooks/commit-msg` blocks commits where `lib/`, `android/`, `ios/`, `test/`, `integration_test/`, `scripts/` or `pubspec.yaml` change without a staged `WalletMelt/` note. Path-specific rules live in `scripts/docs_map.txt`. Escape hatch: `[skip-docs]` in the commit message, only for changes with no doc impact (state why in the message).
- Claude Code `Stop` hook (`.claude/stop_guard.sh`) blocks ending a turn while dirty code files are newer than the newest vault note.
- Enable hooks per clone: `bash scripts/setup_hooks.sh` (or `.ps1`). The vault must be committed, otherwise the guard cannot see it.
- Update the `updated:` frontmatter date on every note you touch.

## 7. Routing Enforcement (mechanical, not advisory)
Committed in `.claude/`: `settings.json` pins `model: sonnet`, `advisorModel: opus`, `CLAUDE_CODE_SUBAGENT_MODEL=haiku`; `agents/haiku-explorer.md` is a read-only Haiku agent (Read/Grep/Glob); `agent_guard.py` is a PreToolUse hook on the `Agent` tool that denies any sub-agent except `haiku-explorer`/`Explore`/`claude-code-guide` and any non-Haiku model. Changes under `.claude/` or `.githooks/` require an update to this note (docs guard rule). Override `WALLETMELT_ALLOW_ANY_AGENT=1` only on explicit user request.
