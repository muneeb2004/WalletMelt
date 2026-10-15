---
type: product
status: verified
priority: high
created: 2026-10-15
updated: 2026-10-15
domain: product
related:
  - "[[Student-Market-Strategy]]"
  - "[[Current-Project-State]]"
---

# Gap Analysis vs Code (verified 2026-10-15)

Findings from read-only code audits against `lib/src/**`. Re-run when schema/routes change.

| Capability | In code? | Evidence |
|---|---|---|
| Income / inflows | **No** | No income table/column in `wallet_melt_database.dart` (22 tables) |
| Payment method / account / wallet | **No** | No column on Expenses |
| Tags | **No** | — |
| Split / shared expenses | **No** | Nearest: DebtRecords + Payees |
| Savings goals / BC committee | **No** | — |
| Recurring income | **No** | Recurrence only on Expenses and Subscriptions |
| Currency per expense | Yes | `Expenses.currency` (also budgets, debts, subs) |
| FX conversion | **No** | — |
| PKR default + ~146 currencies | Yes | `types/settings.dart:49`, `constants/currencies.dart` |
| Locale-aware formatting | **No** | `formatMoney` passes no locale; dates use `DateFormat` without locale |
| Urdu / RTL / l10n | **No** | No flutter_localizations, no .arb, all strings hardcoded |
| Student-oriented default categories | **No** | 9 seeded: Electricity, Gas, Grocery, Internet, Water, Rent, Maintenance, Fuel, Other |
| Semester budgeting | **No** | Budgets are per calendar month (`MonthlyBudgets`) |
| Network/telemetry | **None** (good) | Release manifest has no INTERNET permission; no HTTP/analytics SDK ([[Security-and-Authentication]] §4). Any INTERNET need requires an ADR |

## Doc/Code drift found and fixed in this pass
- Routes list in [[Current-Project-State]] omitted `/privacy-policy`, `/expense/:id/edit`, and the `/subscriptions` + `/essentials` redirects; bottom-nav labels are Home/History/Planning/Debts.
- Budget is Planning tab 0, not a separate screen.
- Working tree is **not** clean (uncommitted v1.1.2 follow-ups); the old note claimed clean.
- Build pipeline = 3 Gradle invocations producing 5 APKs (AGENTS.md says "three targets"; consistent, but older notes said "5-target").
- Migration guide says every migration writes `MigrationAudit`; code only audits v1→v2, v7→v8, v8→v9.
