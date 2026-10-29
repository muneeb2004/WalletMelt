---
type: work-tracker
status: active
priority: high
created: 2026-09-13
updated: 2026-10-29
domain: work
related:
  - "[[Current-Project-State]]"
---

# Active Work & Roadmap Registry

## Now (Current Release v1.7.0)
- [x] v1.7.0 (build 14): committees (BC) with confirm-on-paid installments and payout.

## Previous Release (v1.6.0)
- [x] v1.6.0 (build 13): savings goals set aside inside accounts, free to spend.

## Previous Release (v1.5.1)
- [x] v1.5.1 (build 12): link or unlink existing debts and subscriptions to an account.

## Previous Release (v1.5.0)
- [x] v1.5.0 (build 11): debts and subscriptions linked to accounts ([[ADR-0014-Debts-and-Subscriptions-Move-Account-Balances]]).

## Previous Release (v1.4.0)
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

## Added 2026-10-18 (v1.5.0)
- **Done**: account links on debts and subscriptions; renewals post to the subscription account.
- **Next**: edit form to link existing debts and subscriptions; savings goals / committees; Phase 3 notification capture (parsers: JazzCash, Easypaisa, Meezan, HBL, UBL, NayaPay, SadaPay, Mashreq; Play policy review before the Play Store listing).

## Added 2026-10-18 (v1.5.1)
- **Done**: edit-time account linking for debts and subscriptions.
- **Next**: savings goals set aside inside an account, then committees (BC) with payout turn: each needs an ADR (ADR-0015+), version bump and plain-language What's New.
- Verified 1.5.1: analyzer clean, 614 tests passing.

## Added 2026-10-18 (v1.6.0)
- **Done**: savings goals (ADR-0015).
- **Next**: committees (BC) with monthly installment and payout turn (ADR-0016); then Phase 3 notification capture.
- Verified 1.6.0: analyzer clean, full suite passing, 35 screenshots.

## Added 2026-10-18 (v1.7.0)
- **Done**: committees (ADR-0016).
- **Next**: Phase 3 notification capture: needs sample alert texts for JazzCash, Easypaisa, Meezan, HBL, UBL, NayaPay, SadaPay and Mashreq, an ADR, a Play policy review and an on-device parser design.
- Verified 1.7.0: analyzer clean, full suite passing, 36 screenshots.

## Blocked (2026-10-18)
- **Notification capture** ([[ADR-0017-Optional-Notification-Capture]], proposed): on hold until the owner sends sample alert texts for JazzCash, Easypaisa, Meezan, HBL, UBL, NayaPay, SadaPay and Mashreq; Play policy still to be verified in the Play Console.

## Release 1.7.1 (2026-10-18)
- **Done**: simpler accounts (3 types, name-only Add account, Add money / Spend money, Correct balance in the overflow menu). What's New updated in plain language.
- Verified 1.7.1: analyzer clean, full suite passing (643 tests), 36 screenshots.

## Release 1.7.2 (2026-10-19)
- **Done**: uniform, fluid lists. New `lib/src/widgets/fluid_list.dart` (`FluidList` padding/gap/physics, `FluidItem` staggered fade and slide, 320 ms ease-out, max 8 staggered rows, respects reduced motion). Applied to accounts, goals, committees, income, debts-adjacent payees, merchants, subscriptions, essentials and history (spacing and scroll physics). What's New updated in plain language.

## Release 1.7.3 (2026-10-19)
- **Done**: option menus and dropdowns follow the design system. `popupMenuTheme` and `menuTheme` in the theme set a 16 px radius, hairline border and raised surface; every `DropdownButton`/`DropdownButtonFormField` passes the same radius, colour and a 320 px max height. What's New updated in plain language.

## Release 1.8.0 (2026-10-27)
- **Done**: category editing (name, icon, colour) for all categories including defaults; icon bank (69 SVG presets plus standard icons, emoji, own SVG upload) with picker, Categories screen and Icon library; raw SVG code editor removed; multicolour uploads keep their colours; ZIP backups carry uploaded and edited icons; dashboard shows spend and balance as equal tiles; account sheet and forms redesigned with Correct balance visible; Add expense is amount-first; currency labels drop flags; activity rows wrap to two lines; sparkle removed from the Settings version badge and What's New header. What's New written in plain language. Version 1.8.0+18.
- **Open**: stable names for uploaded icons; one-time "tap your balance" hint (not built).
- **Build**: release APKs are produced with `scripts/build_apks.ps1`, which regenerates `lib/src/constants/app_version.dart` from `pubspec.yaml` (1.8.0+18).

## Release 1.10.0 (2026-10-29)
- **Done**: the dashboard balance hide/show choice is now a saved setting (`WalletMeltSettings.hideBalance`, key `settings.hideBalance` in SharedPreferences, `AppState.setHideBalance`) instead of widget state, so it survives restarts. It is a device preference and is not part of backups. What's New: bug fix entry. Version 1.10.0+20.
- **Build**: release APKs via `scripts/build_apks.ps1` (1.10.0+20).

## Release 1.9.0 (2026-10-29)
- **Done**: renewals confirmed calendar-aware (anchor day, month-end clamp, leap years) and documented against Stripe behaviour; one `SubscriptionFormSheet` creates and edits (name, category, amount, tax, cycle incl. weekly, next renewal date, account, reminder, notes) with a live three-date preview; manual date becomes the new anchor; resume rolls forward instead of back-filling paused cycles; shared `monthlyEquivalent` replaces three hardcoded 30-day formulas (average month 30.4375 days); subscription list card and actions sheet moved to `WMCard` and theme text. What's New written in plain language. Version 1.9.0+19.
- **Build**: release APKs via `scripts/build_apks.ps1` (1.9.0+19).
