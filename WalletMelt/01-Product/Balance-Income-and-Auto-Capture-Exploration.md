---
type: product
status: proposed
priority: high
created: 2026-10-17
updated: 2026-10-17
domain: product
related:
  - "[[Student-Market-Strategy]]"
  - "[[Gap-Analysis-vs-Code]]"
  - "[[Project-Constitution]]"
  - "[[Security-and-Authentication]]"
---

# Balance, income and auto-capture exploration (2026-10-17)

> **Status: proposed.** Nothing here changes stable scope. Each phase needs an ADR before code. Triggered by user feedback asking for: total balance, planned monthly spend and limits, updates when salary arrives, and auto-recorded expenses from bank/wallet notifications. App stays offline-only.

## 1. Verified starting point
- No income, account/wallet or payment-method concept exists ([[Gap-Analysis-vs-Code]]). Budgets are `MonthlyBudgets` + `CategoryBudgets`; `daily allowance` is computed in `financial_metrics_calculator.dart`.
- Release manifest declares only biometric permissions: no INTERNET, no SMS, no notification access.
- Expenses carry `currency`, minor units, soft delete, `deletedAt`.

## 2. Phased proposal

### Phase 1: Accounts and balance (core of the feedback)
- New `Accounts` table: name, type (cash, bank, wallet, card), currency, opening balance (minor units), archived flag, colour/icon.
- `Expenses.accountId` (nullable, default account for existing rows).
- Balance = opening balance + inflows - outflows, **derived, never stored**, so edits, deletes and restores stay consistent. Optional "reconcile" action writes a balancing adjustment entry when the user types the real balance.
- Transfers between accounts (cash withdrawal, wallet top-up) as a paired entry, excluded from spending analytics.
- Dashboard: total balance card (sum per currency; no FX), per-account list, hide-balance toggle.

### Phase 2: Income and planning
- New `Incomes` table (or a `kind` on a shared ledger; decide in ADR): amount, account, source (salary, allowance, scholarship, freelance, other), date, recurrence.
- Recurring income reuses the subscription cadence engine, with a confirm-on-arrival prompt ("Salary due today, received?") rather than silent posting.
- Planned monthly spend: make the month budget derive from "expected income - savings target - committed (subscriptions, essentials, debt dues)" with the existing manual override.
- Pay-cycle budget: period starts on salary day (or semester for students) instead of calendar month. Extends `MonthlyBudgets`.
- Limits: per-category and per-account limits, soft/hard warning thresholds (80/100%) as local notifications.
- Runway: balance / average daily spend until next expected income.

### Phase 3: Auto-capture from bank/wallet notifications (opt-in)
**Mechanism options**

| Option | Verdict |
|---|---|
| `NotificationListenerService` (on-device) | Preferred. Needs the user to grant Notification access in system settings; no INTERNET needed; covers bank and wallet apps (JazzCash, Easypaisa, Raast, banking apps). |
| SMS read (`READ_SMS`) | Avoid. Restricted by Play policy, listed out of scope in the Constitution, highest trust cost. |
| Share-sheet / paste a message | Zero-permission fallback. Ship first as a safe path. |
| Cloud/AI parsing | Rejected: breaks offline promise. |

**Design**
- Package allowlist (user picks which apps to watch); everything else is dropped immediately and never stored.
- On-device rule-based parser: regex template per sender (amount, debit/credit, merchant, balance-after, reference). Templates ship as a versioned local asset; user can add custom ones. Optional "balance-after" in the alert can auto-reconcile the account.
- **Never auto-post silently.** Parsed items land in a "Review inbox" (confirm / edit / ignore), with one-tap confirm and optional auto-confirm per trusted template once accuracy is proven.
- Dedupe by (amount, time window, reference) so a bank alert plus a wallet alert for one payment do not double count; also match against manually entered expenses.
- Store only the parsed fields plus a hash of the raw text, not the notification body.

**Risks**
- Android 13+ blocks enabling notification access for sideloaded APKs ("restricted settings"); users must open App info and choose Allow restricted settings, and Android 15 adds confirmation mode. Play Store installs are unaffected ([source](https://dev.to/ahmmedrejowan/android-13s-restricted-setting-a-stronghold-against-malicious-apps-1ea9), [source](https://chromeunboxed.com/android-13-restricted-setting-feature-blocks-sideloaded-apps-from-notifications/)). The current distribution is APKs, so onboarding must walk users through this.
- OEM battery killers (Xiaomi, Oppo, Vivo, Infinix are common in Pakistan) stop the listener; needs a health indicator and battery-exemption guidance.
- Message formats change without notice; parser needs fixtures and a "could not parse" bucket. Most Flutter plugins are thin or unmaintained (e.g. [notification_listener_service](https://pub.dev/packages/notification_listener_service/versions/1.0.0), [flutter_notification_listener forks](https://pub.dev/documentation/flutter_notification_listener_plus/latest/)), so a small in-repo Kotlin service plus method channel is likely safer.
- Google Play policy for notification access in finance apps was **not verified** in this pass; confirm in a Play policy review before a store listing.
- iOS has no equivalent API; this is Android only.
- Constitution: SMS parsing is out of scope. Notification parsing is adjacent; requires an ADR that amends the Constitution explicitly, with the permission opt-in, privacy policy and consent text updated.

### Phase 4: Other upgrades that stay offline
1. **Home-screen widget and quick-add notification** (remaining today / balance).
2. **Savings goals and BC committee** (already ranked in [[Student-Market-Strategy]]).
3. **Payment-method tag** is subsumed by accounts.
4. **Split / shared expenses** building on Payees + Debts.
5. **Reminders**: bill due, salary expected, budget threshold (local notifications only).
6. **Net worth** view: accounts + receivables - liabilities (data exists in Debts).
7. **Reports**: PDF/CSV export, monthly summary share image, year-in-review.
8. **Receipt OCR on-device** (ML Kit offline) to prefill amount/date/merchant.
9. **Encrypted backup file** (passphrase) and scheduled local auto-backup.
10. **Urdu / RTL**, student categories, lite mode (already proposed).
11. **Tags and search filters**, merchant auto-categorisation rules learned locally.
12. **Subscription price-change and duplicate detection**.

## 2a. Status (2026-10-17)
Phase 1 shipped ([[ADR-0011-Accounts-Derived-Balance-and-Transfers]]). Phase 2 shipped except pay-cycle budgets and runway ([[ADR-0012-Income-Schedules-and-Budget-Suggestion]]).

## 3. Suggested order
1. ADR: Accounts + balance + transfers (Phase 1), including backup v2 / migration (schema v10) and analytics exclusions for transfers.
2. ADR: Income + recurring income + pay-cycle budget (Phase 2).
3. Share-text import + review inbox (Phase 3a, no special permission).
4. Notification listener (Phase 3b) after Play-policy check and a parser fixture corpus from real Pakistani bank/wallet alerts.

## 4. Open questions for the owner
- Single currency per account with per-currency totals, or add manual FX rates?
- Is the target store distribution Play Store, sideloaded APK, or both (drives Phase 3b onboarding)?
- Which banks and wallets matter first (sample alert texts needed to build templates)?
- Should balances be opt-in so existing users are not forced into account setup?
