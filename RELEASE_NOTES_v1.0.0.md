# WalletMelt v1.0.0 — Release Notes

**WalletMelt** is a local-first personal finance application engineered for privacy, financial accuracy, and visual clarity.

---

## 1. Core Financial Features
* **Personal Expense Tracking**: Progressive disclosure expense entry (Amount → Category → Date → Save) with optional vendor, notes, and store association.
* **Monthly & Category Budgets**: Visual budget progress bars, real-time remaining calculations (`Remaining = Budget - Actual Spending`), and spending pace tracking.
* **Comprehensive Planning**: Subscriptions manager with renewal countdowns and automated expense generation; essential expense allocation and tracking.
* **Debt & Receivable Management**: Net financial position calculation (`Net Position = Receivables - Liabilities`), overdue reminders, and dedicated repayment tracking.

---

## 2. Specialized Workflows
* **Grocery Itemization**: Itemized unit-cost calculations (`Quantity × Unit Price`) with reusable templates and receipt attachments.
* **Fuel Logging**: Multi-fuel split logging (`Litres × Price/L`), station tagging, and odometer tracking.
* **Sales Tax Support**: Deterministic tax calculation (`Total = Subtotal + Tax Amount`) supporting zero and fractional tax percentages.
* **Receipt Capture**: Compressed receipt image capture and local encrypted-path storage.

---

## 3. Privacy & Security Architecture
* **Local-First SQLite Storage**: All financial transactions, categories, budgets, and debts reside exclusively on the device (`wallet_melt.db`). No account creation or cloud sync required.
* **Master PIN Authentication**: 4-digit PIN lock with SHA-256 deterministic hashing and fail-closed storage validation.
* **Biometric Unlock**: Platform-adaptive biometric integration (Face ID, Touch ID, Fingerprint) with in-flight concurrency guards and fallback to master PIN.
* **Lockout Throttling**: 5-attempt threshold enforcing a 30-second cooldown period with real-time non-shifting timer.
* **Lifecycle Protection**: Deterministic 30-second background grace period and `FLAG_SECURE` app-switcher screen protection.
* **User-Controlled Backups**: Encrypted local JSON safety backup packaging with checksum verification, dry-run conflict detection, and transactional rollback.
