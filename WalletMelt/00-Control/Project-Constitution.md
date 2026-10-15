---
type: constitution
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: control
related:
  - "[[AI-Engineering-Protocol]]"
  - "[[Current-Project-State]]"
---

# Project Constitution

## 1. Purpose & Product Boundaries
- **Core Mission**: WalletMelt is an offline-first personal financial management application designed to answer one question: *“Where did my money melt this month?”*
- **Strict Privacy**: Financial transactions, receipts, categories, budgets, and debts reside exclusively on the user's device. No mandatory remote account creation, cloud tracking, or external telemetry in current releases.
- **Product Boundaries**:
  - In Scope: Expenses, grocery itemization, fuel logging, monthly/category budgets, financial metrics & allowances, debts/repayments, subscriptions, essential expenses, payee/merchant normalization, PIN/biometric authentication, local JSON/CSV backup & restore, receipt camera/gallery capture, and SVG category customization.
  - Out of Scope (Current): Remote accounts, cloud databases, automatic bank syncing, third-party advertising SDKs, and speculative background daemons.

## 2. Engineering Philosophy & Non-Negotiable Invariants
1. **Local-First Reliability**: All write paths must succeed without network connectivity.
2. **Determinism in Calculations**: All financial calculations (allowances, pace, tax, repayments, unit pricing) must use deterministic integer or strict rounding models (e.g. `FinancialMetricsCalculator`, minor-unit database columns).
3. **Database Integrity & Lifecycle**:
   - Drift (`WalletMeltDatabase`) is the primary persistence engine.
   - The sqflite fallback layer (`AppDatabase`) remains intact for legacy migration safety.
   - `WalletMeltDatabase.open()` must always return the unified static singleton instance. Dual-instance creation is strictly prohibited.
4. **State Layer Coexistence**:
   - Screen-level UI state is coordinated by Provider (`AppState`).
   - Do NOT rewrite or replace `AppState` with Riverpod in UI screens without a formal, approved ADR.
   - Riverpod is used exclusively for dependency injection of Drift repositories.
5. **Fail-Closed Security**:
   - Authentication (PIN / Biometrics) defaults to locked if secure storage or hardware checks fail.
   - 5 consecutive failed PIN attempts enforce a strict 30-second lockout.
   - Background grace period is fixed at 30 seconds before locking.
   - `FLAG_SECURE` prevents sensitive financial data from appearing in the OS app switcher.
6. **Data Safety in Restores & Migrations**:
   - Restores run inside a single transactional rollback boundary. **Safe-Merge** is the default. Full Replace is permitted only for complete format-v2 backups, with explicit confirmation, a pre-restore safety backup and foreign-key verification ([[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]], amended 2026-10-15).
   - Silent destructive overwrites or silent collision deletions are forbidden.
   - Schema upgrades must increment `currentSchemaVersion` and include idempotent table migration steps in `WalletMeltDatabase`.

## 3. Rules for AI Agents
- **Source of Truth**: The codebase is the source of truth for implemented behavior. The Obsidian vault is the source of truth for intent, architecture, decisions, and governance.
- **No Scope Invention**: Never infer undocumented product requirements or expand scope merely because an implementation possibility exists.
- **No Speculative Refactoring**: Never refactor working subsystems or introduce new third-party libraries while completing an unrelated task.
- **Authority Hierarchy**:
  1. `Project-Constitution.md` (Overrides all other documentation)
  2. `AI-Engineering-Protocol.md` (Governs agent operations)
  3. `Current-Project-State.md` (Verified repository baseline)
  4. Architecture Decision Records (`04-Decisions/`)
  5. Architecture & Subsystem Notes (`02-Architecture/`, `01-Product/`)
  6. Codebase Implementation
