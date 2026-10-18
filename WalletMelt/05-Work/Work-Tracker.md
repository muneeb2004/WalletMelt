---
type: work-tracker
status: active
priority: high
created: 2026-09-13
updated: 2026-10-17
domain: work
related:
  - "[[Current-Project-State]]"
---

# Active Work & Roadmap Registry

## Now (Current Release v1.4.0)
- [x] v1.4.0 (build 10): budget period start day (payday budgeting), plain-language What's New, screenshots with balance and income ([[ADR-0013-Budget-Period-Start-Day]]).

## Previous Release (v1.3.0)
- [x] v1.3.0 (build 9): accounts and derived balance, income and confirm-on-arrival recurring income, budget suggestion, optional backup keys; What's New written in plain language ([[ADR-0011-Accounts-Derived-Balance-and-Transfers]], [[ADR-0012-Income-Schedules-and-Budget-Suggestion]]).

## Previous Release (v1.2.1)
- [x] v1.2.1 (build 8): SVG modify tools, save-as-new, 29 more default icons, built-in icon edits now apply to default categories (alias keys). See [[ADR-0007-SVG-Customization-and-Global-Overrides]].

## Previous Release (v1.2.0)
- [x] v1.2.0 (build 7): Tonal Material 3 design system, single indigo brand, simpler navigation, higher-contrast text, safer backups, atomic renewals; What's New updated ([[ADR-0010-Tonal-Material3-Design-System-and-Brand]]).

## Previous Release (v1.1.2)
- [x] Across-the-board SVG customization & live override reflection (`v1.1.2`).
- [x] Deterministic financial metrics engine (`FinancialMetricsCalculator`).
- [x] Explicit metric calculations transparency menu in Settings.
- [x] Standardized 5-target release APK compilation & verification.
- [x] Establish Obsidian vault engineering control plane.

## Next (Upcoming Incremental Refinements)
- [ ] Investigate Kotlin Gradle Plugin (KGP) warnings in `flutter_image_compress_common` and `share_plus` when upstream updates release.
- [ ] Add selective conflict resolution UI for manual category/budget choice during backup restore.
- [ ] Add compressed ZIP media archiving for receipt photos during backup.

## Later (Future Architectural Horizons - V3 Roadmap)
- [ ] Monorepo Turborepo backend foundation (NestJS / PostgreSQL 16 / Prisma).
- [ ] Cloud sync metadata transport layer (`sync_metadata` integration).
- [ ] Receipt OCR processing queue with Google Document AI / BullMQ.
- [ ] Multi-device Web/Desktop client access.

## Blocked
- *None currently.*

## Added 2026-10-15
- **Now**: Resolve TD-007 (commit `app_version.dart`) and decide TD-004 (fullReplace).
- **Next**: Validate student strategy via interviews ([[Student-Market-Strategy]] §6); draft ADR proposals for income inflows, semester budgets, student categories.
- **Later**: Backup coverage for all domains (TD-005); localization foundation (TD-008).

## Added 2026-10-17
- **Done**: Tonal design system foundation ([[ADR-0010-Tonal-Material3-Design-System-and-Brand]]): theme, `WMCard`, Material 3 shell navigation, dashboard.
- **Done 2026-10-17**: History, Add expense, Planning, Budget, Subscriptions, Essentials, Debts migrated by codemod to colour roles and the six-step scale.
- **Done 2026-10-17**: Settings, Insights, Security, Onboarding, Merchants, Payees, Privacy, What's new and shared widgets migrated; app-wide design-system migration complete.
- **Next**: Fix screenshot suite hang (pre-existing, see TD-010); lower the baselines in `design_token_guard_test.dart` ([[Technical-Debt-Registry]] TD-010). Update screenshot harness expectations.

## Added 2026-10-17 (accounts)
- **Done**: Phase 1 of [[Balance-Income-and-Auto-Capture-Exploration]] implemented per [[ADR-0011-Accounts-Derived-Balance-and-Transfers]]: schema v10, `DriftAccountRepository`, `BalanceCalculator`, backup support, Accounts screen (`/accounts`), Dashboard balance card, expense account picker.
- **Next**: Phase 2 ADR (income, recurring income, pay-cycle budget). Add a What's New entry and a screenshots demo account when the next release is cut.
- **Later**: Link debt repayments to accounts; Phase 3 opt-in notification capture (needs Play-policy check and its own ADR).

## Added 2026-10-17 (income, Phase 2)
- **Done**: [[ADR-0012-Income-Schedules-and-Budget-Suggestion]] implemented: schema v11, `DriftIncomeRepository`, `IncomePlanner`, shared `recurrence.dart`, backup support, `/income` screen, Dashboard confirm-on-arrival card, budget-sheet suggestion.
- **Done**: fixed two Phase 1 UI bugs found by new widget tests (infinite-width buttons in the account detail sheet; `setState` returning a Future).
- **Next**: Pay-cycle / semester budget ADR; What's New entry and screenshot demo data (account, income) for the next release.
- **Later**: Phase 3 opt-in notification capture; link debt repayments and subscription renewals to accounts.

## Release rule (2026-10-17)
Every release bumps `pubspec.yaml` and ships a plain-language, non-technical What's New entry in `lib/src/widgets/whats_new_dialog.dart` (and its test) in the same commit.

## Added 2026-10-18
- **Done**: pay-cycle (start day) budgets; screenshot demo accounts and income (34 screenshots).
- **Next**: link debt repayments and subscription renewals to accounts; savings goals / committees; Phase 3 notification capture (needs Play policy review before the Play Store listing).

- **Known flake (2026-10-18)**: `test/screenshots/publication_screenshot_test.dart` fails roughly 1 run in 4 on a single, varying target (passes on rerun and in isolation); see [[Technical-Debt-Registry]] TD-010 for the older screenshot-suite hang.
