---
type: product
status: stable
priority: medium
created: 2026-09-13
updated: 2026-09-13
domain: product
related:
  - "[[Product-Requirements]]"
---

# Design System and UX Conventions

## 1. Design Language: "Warm Liquid Glass"
- **Backgrounds**: Soft mint/cream canvas in light mode (`0xFFF8FAF9`); deep obsidian slate in dark mode (`0xFF0B0E14` / `0xFF131720`).
- **Glass Surfaces**: `WMGlassSurface` tiered blur panels (`tier1`, `tier2`, `tier3`) providing subtle translucency, rounded corners (16–24dp), and delicate contrast borders (`0xFFE2E8F0` / `0xFF1E293B`).
- **Accent Palette**:
  - **Melt Gold / Amber** (`WalletMeltColors.brand` / `0xFFF59E0B`): Primary interactive elements and hero metrics.
  - **Positive Mint** (`WalletMeltColors.positive` / `0xFF10B981`): Healthy budget utilization, repayments, receivables.
  - **Warning Orange** (`WalletMeltColors.warning` / `0xFFF97316`): Utilization approaching 80–90%, overdue warnings.
  - **Danger Red** (`WalletMeltColors.danger` / `0xFFEF4444`): Over-budget states, liabilities, deletions.

## 2. Navigation Architecture
- **Persistent App Shell**: 4 bottom navigation branches via `go_router` `StatefulShellRoute.indexedStack`:
  1. `Dashboard` (`/`): Summary burn, allowance hero, fast-action button, recent items, insight card.
  2. `History` (`/history`): Searchable, filterable transaction ledger with monthly selector.
  3. `Planning` (`/planning`): Unified 3-tab planning hub (Monthly Budgets, Subscriptions, Essentials).
  4. `Debts` (`/debt`): Receivables and liabilities tracking.
- **Full-Screen Workflows**: Add/Edit expense (`/expense/new`), Receipt viewer (`/receipt/:id`), Settings (`/settings`), PIN lock (`/pin-lock`).

## 3. UX Rules & Progressive Disclosure
1. **Zero-Friction Fast Entry**: Expense creation requires only Amount and Category to save. Notes, merchant, receipt, and grocery lines are optional progressive disclosure.
2. **Clear Empty States**: Empty states must teach the immediate next action rather than displaying dead ends or promotional copy.
3. **Fail-Safe Confirmation**: All destructive operations (permanently delete, restore backup, reset PIN) require explicit confirmation dialogs.
