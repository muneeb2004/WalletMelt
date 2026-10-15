---
type: product
status: stable
priority: high
created: 2026-09-13
updated: 2026-09-13
domain: product
related:
  - "[[Design-System-and-UX]]"
  - "[[Project-Constitution]]"
---

# Product Requirements

## 1. Product Purpose & Value Proposition
WalletMelt answers the question: **"Where did my money melt this month?"**
It empowers privacy-conscious users to track expenses with zero cloud tracking, granular itemization, real-time pace monitoring, and deterministic budget safety.

## 2. Core Functional Requirements (Current Stable Scope)

| Domain | Requirement Description | Status | Verification Reference |
|---|---|---|---|
| **Expenses** | Fast amount entry, custom/standard category attribution, note, vendor/merchant tagging, receipt image attachment, and date selection. | Stable | `AddExpenseScreen`, `Expense` |
| **Grocery Itemization** | Optional breakdown for groceries (`Quantity × Unit Price`), running subtotal check, and mismatch approval dialog. | Stable | `GroceryItem`, `ItemizationStatus` |
| **Fuel Tracking** | Multi-fuel splitting (regular, premium, diesel), litres, price/L, and odometer logging. | Stable | `FuelTransactions`, `FuelComponents` |
| **Dynamic Monthly Budgets** | Monthly budget limits set per calendar month with 1-tap historical copy forward. | Stable | `MonthlyBudgets`, `BudgetScreen` |
| **Category Budgets** | Monthly limits set per category with progress visualization and remaining calculations. | Stable | `CategoryBudgets`, `BudgetProgress` |
| **Daily Spend Allowance** | Live remaining daily allowance calculated as `Remaining Budget / Days Remaining in Month` (with +1 for active day). Drops to 0.00 when over budget. | Stable | `FinancialMetricsCalculator` |
| **Metric Transparency** | Dedicated menu in Settings detailing mathematical formulas and real-time breakdowns. | Stable | `MetricCalculationsScreen` |
| **History & Recycle Bin** | Search, filter by category/date, sort, soft delete with `deletedAt`, and restore from recycle bin. | Stable | `HistoryScreen`, `AppState` |
| **Debts & Obligations** | Receivables (owed to me) and liabilities (I owe), loan tracking, repayment logging, and net position calculation. | Stable | `DebtScreen`, `DebtRecords` |
| **Subscriptions** | Recurring subscription tracking, renewal countdowns, monthly equivalent normalization, and payment logging. | Stable | `PlanningScreen`, `Subscriptions` |
| **Essential Expenses** | Baseline commitments tracking (rent, bills, utilities) to understand non-discretionary burn. | Stable | `EssentialExpenseTemplates` |
| **Merchant / Payee Stores** | Normalized merchant profiles and payee counterparties. | Stable | `MerchantsScreen`, `PayeesScreen` |
| **Icon Customization** | Edit SVG paths/colors, live preview, 1-tap palette replacer, and custom file upload reflecting across all category icons. | Stable | `SvgManagerScreen`, `CategoryIcon` |
| **Security Lock** | Optional 4-digit master PIN with salt, platform biometrics (Face ID/Fingerprint), 30s background grace period, and 5-attempt/30s lockout throttle. | Stable | `PinLockController`, `PinLockScreen` |
| **Export & Safe Merge** | Export CSV & JSON backups. Safe-merge restore verifying format, conflict detection, dry run, and transactional merge. | Stable | `WalletMeltJsonRestoreService` |

## 3. Explicitly Out-of-Scope (Current Release)
- **Cloud Accounts & Server DBs**: No remote user authentication, PostgreSQL backends, or cloud synchronization.
- **Bank Feeds / Plaid**: No automated SMS parsing or financial institution scraping.
- **Destructive Full Restore**: Overwriting existing records on restore is prohibited.
- **Cross-Device Web/Desktop Sync**: Sync engines remain documented for future V3 roadmap only.
