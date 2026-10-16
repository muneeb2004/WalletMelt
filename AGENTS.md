# WalletMelt Agent Directives

## Standardized APK Build Rule

Whenever the user states **"I need apks"** (or requests building/generating APKs without qualification), the agent must build all three targets:

1. **Production Universal Release APK** (universal fat APK containing all ABIs):
   ```powershell
   flutter build apk --flavor production --release
   ```
   *Output:* `build/app/outputs/flutter-apk/app-production-release.apk`

2. **Production Split-per-ABI Release APKs** (optimized per-architecture binaries):
   ```powershell
   flutter build apk --flavor production --release --split-per-abi
   ```
   *Outputs:*
   - `build/app/outputs/flutter-apk/app-armeabi-v7a-production-release.apk`
   - `build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk`
   - `build/app/outputs/flutter-apk/app-x86_64-production-release.apk`

3. **Screenshots Release APK** (screenshots flavor pre-seeded with mock data):
   ```powershell
   flutter build apk --flavor screenshots --release --dart-define=SCREENSHOT_MODE=true
   ```
   *Output:* `build/app/outputs/flutter-apk/app-screenshots-release.apk`

Alternatively, execute the standardized script:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_apks.ps1
```
or in Bash:
```bash
./scripts/build_apks.sh
```

Always report the status, paths, and file sizes (in MB) for all 5 generated APK artifacts upon completion.

## Obsidian Vault & Docs Guard

- The vault `WalletMelt/` is the authority for intent, architecture and decisions; code is authority for behavior. Start at `WalletMelt/00-Control/Index.md`.
- **Every code change updates the vault.** `.githooks/commit-msg` rejects commits that change `lib/ android/ ios/ test/ integration_test/ scripts/ pubspec.yaml` without a staged `WalletMelt/` note (rules: `scripts/docs_map.txt`; escape: `[skip-docs]` for no-doc-impact changes). A Claude Code Stop hook (`.claude/`) enforces the same during sessions.
- After cloning run `bash scripts/setup_hooks.sh` (or `scripts/setup_hooks.ps1`) to set `core.hooksPath`.
- Commit the vault with the code; an untracked vault cannot be checked.

## Model Routing

Opus advises (before committing to an approach and before declaring done). Sonnet is the main agent and does all writing, code and judgment. Haiku sub-agents are used STRICTLY for mechanical read-only enumeration (counts, lists, claim-vs-code diffs); never for notes, strategy, code or guards.

### Routing enforcement (committed config, applies whenever Claude Code runs here)
- `.claude/settings.json`: `model: sonnet` (main), `advisorModel: opus` (advisor tool), `CLAUDE_CODE_SUBAGENT_MODEL=haiku` (all sub-agents).
- `.claude/agents/haiku-explorer.md`: Haiku, tools limited to Read/Grep/Glob (read-only, cannot write).
- `.claude/agent_guard.py` (PreToolUse on `Agent`): denies any sub-agent other than `haiku-explorer`, `Explore`, `claude-code-guide`, and any non-haiku model. Opus is never a sub-agent. Override only with `WALLETMELT_ALLOW_ANY_AGENT=1` when the user explicitly asks.
- Call the advisor (Opus) before committing to an approach and before declaring done.

## Brand & Design System Guard

- Brand and UI standard: `WalletMelt/01-Product/Design-System-and-UX.md` (decision: `ADR-0010`). One brand (indigo), Tonal Material 3.
- In `lib/`, never write raw colours (`Color(0x…)`, `Colors.*`) or ad hoc `fontSize` values. Use `Theme.of(context).colorScheme`, `context.money` for status colours, `textTheme` (six-step scale: 34/22/17/14/12/11), `AppSpacing`, and `WMCard` for cards. New hex values go in `lib/src/theme/wm_palette.dart` only, with a vault update first.
- `test/theme/design_token_guard_test.dart` is a ratchet over legacy raw colours and small fonts. Lower its baselines when you migrate code; never raise them.
- UI copy is sentence case, verb-first for buttons; the product name is "WalletMelt".
