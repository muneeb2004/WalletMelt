---
type: registry
status: active
priority: high
created: 2026-09-13
updated: 2026-10-17
domain: engineering
related:
  - "[[Current-Project-State]]"
---

# Technical Debt Registry

> **Operating Rule**: This technical debt registry documents known liabilities. It is NOT permission for an AI agent to perform opportunistic, speculative refactoring. All debt resolution must be scheduled as deliberate work.

---

### TD-001: Kotlin Gradle Plugin (KGP) Direct Application Warning
- **Problem**: Plugins `flutter_image_compress_common` and `share_plus` apply KGP directly rather than using Flutter's built-in Kotlin integration.
- **Impact**: Emits compiler warnings during Gradle build steps; potential failure in future Flutter releases if not updated.
- **Workaround**: Currently compiles and executes cleanly on Android API 36 with Java 21.
- **Risk**: Low in immediate term; Medium upon future Flutter SDK major upgrades.
- **Priority**: Low
- **Proposed Direction**: Monitor upstream package releases and upgrade when Built-in Kotlin is supported.
- **Related Code**: `android/app/build.gradle`

---

### TD-002: Windows Gradle Cross-Drive Execution Constraints
- **Problem**: Kotlin daemon parallel/incremental compilation can collide across Windows drive letters and pub cache.
- **Impact**: Compilations can fail with file lock errors if parallel builds are enabled on certain Windows hosts.
- **Workaround**: `android/gradle.properties` sets `kotlin.incremental=false`, `kotlin.compiler.execution.strategy=in-process`, and `org.gradle.parallel=false`.
- **Risk**: Build times take slightly longer (~50s per flavor), but builds are 100% reliable.
- **Priority**: Low
- **Proposed Direction**: Maintain these flags as standard build invariants for Windows hosts.
- **Related Code**: `android/gradle.properties`

---

### TD-003: Coexistence of Dual State Packages (Provider + Riverpod)
- **Problem**: The codebase maintains both `provider` and `flutter_riverpod` dependencies.
- **Impact**: Slight mental overhead for developers new to the codebase.
- **Workaround**: Governed strictly by [[ADR-0003-Provider-UI-with-Riverpod-DI]]: Provider manages UI screens via `AppState`; Riverpod is used strictly for repository dependency injection.
- **Risk**: Low, as boundaries are strictly enforced.
- **Priority**: Low
- **Proposed Direction**: Preserve boundary; do NOT execute speculative screen rewrites.
- **Related Code**: `lib/src/app/wallet_melt_app.dart`, `lib/src/providers/`


---

### TD-004: `fullReplace` restore contradicts Constitution / ADR-0005
- **Problem**: `RestoreMode.fullReplace` deletes existing rows; Constitution §2.6 forbids destructive overwrites.
- **Decision needed (user)**: remove it, or amend the Constitution/ADR with a new ADR. Historical rationale: Unknown.
- **Priority**: High. **Related Code**: `lib/src/services/export/*restore_service.dart`, `lib/src/screens/settings/backup_restore_dialog.dart`

### TD-005: Backup omits debts, subscriptions, payees, essentials, fuel
- **Impact**: Restoring a backup silently loses these domains; no checksum either. Spec note is ahead of code.
- **Priority**: High (trust/data safety for a finance app). **Related Code**: `wallet_melt_json_backup_encoder.dart`

### TD-006: Unreferenced security services
- `LedgerIntegrityService` (hard-coded fallback key) and `SecureClipboardService` have tests but no call sites; PIN lockout enforced only in UI layer. **Priority**: Medium.

### TD-007: `app_version.dart` untracked while tracked code imports it
- A clean checkout of committed code will not build until `lib/src/constants/app_version.dart` is committed (as of 2026-10-15). **Priority**: High; commit with the v1.1.2 follow-ups.

### TD-008: No localization infrastructure
- No `flutter_localizations`/ARB/RTL; formatting ignores locale. Blocks Urdu (see [[Student-Market-Strategy]] theme 5). **Priority**: Strategic.


### TD-009: Renewal engine bugs found in 2026-10-15 bug hunt
- Month-end drift/skipped months: **fixed** (anchor-day clamping, see [[Analytics-and-Calculations]]).
- Non-atomic renewal loop (duplicate expenses on partial failure) and no in-flight guard on `refresh()`: **in progress**.
- Debt repayments use `double` math and never write `*MinorUnits`: **in progress**.


### TD-010: Legacy raw colours and small fonts outside the theme
- **Problem**: After [[ADR-0010-Tonal-Material3-Design-System-and-Brand]] the theme, shell, dashboard and card primitive follow the Tonal system, but about 687 raw colour literals and 26 font sizes below 11 remain (down from 1,080 and 50). History, Add expense, Planning, Budget, Subscriptions, Essentials and Debts are migrated except white foregrounds on category-coloured actions; Settings, Insights, Security, Onboarding, Receipt viewer, Merchants, Payees and What's new are not.
- **Impact**: Some screens still look slightly off-system, especially dark-mode text that uses fixed `WalletMeltColors` status constants instead of `context.money` text colours.
- **Also**: `test/screenshots/publication_screenshot_test.dart` hangs 10 minutes after its first capture, verified identical on pristine HEAD (not caused by the redesign). Publication screenshots in `walletmelt_screenshots/` still show the old UI until that is fixed and they are regenerated.
- **Guard**: `test/theme/design_token_guard_test.dart` fails if either count rises (ratchet). Lower the baselines when migrating.
- **Priority**: Medium. Migrate screen by screen (History, Add expense, Planning, Debts, Settings), not in one sweep.
- **Related Code**: `lib/src/screens/`, `lib/src/widgets/`, `lib/src/components/`

---

## Resolution log (2026-10-15)
- **TD-004** `fullReplace` crashed on FK and contradicted the Constitution: **resolved** by [[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]] (complete, verified, v2-only).
- **TD-005** backups omitted debts/subscriptions/etc.: **resolved** (format v2 `extended` section, checksum).
- **TD-007** untracked `app_version.dart`: **resolved** (committed in `1bf9f16`).
- **TD-009** renewal bugs: month-end drift **fixed**; renewals now atomic with an in-flight guard; debt/expense/subscription repositories write minor units (restore back-fills them). Tests: `test/subscription_renewal_test.dart`.
- **TD-006** unused `PinHash.hashPin` static-salt wrapper **removed**; `LedgerIntegrityService` and `SecureClipboardService` still unreferenced (open).
- Open low items: undisposed method-local `TextEditingController`s in sheets (disposing after pop risks use-after-dispose; left as is), remaining `catch (_) {}` in UI/file services, category-budget/grocery repositories do not write minor units (restore back-fills).
