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

## Now (Current Release v1.2.1)
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
