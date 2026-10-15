---
type: architecture
status: stable
priority: medium
created: 2026-09-13
updated: 2026-10-15
domain: architecture
related:
  - "[[ADR-0005-Safe-Merge-Transactional-Restore]]"
  - "[[Database-and-Drift-Architecture]]"
---

# Backup and Restore Architecture

## 1. Architectural Guardrails
WalletMelt backup and restore (`lib/src/services/export/`) is **Safe-Merge by constitutional rule**. **Code reality (2026-10-15): a `RestoreMode.fullReplace` also exists** (`wallet_melt_json_restore_service.dart` `restoreFullReplace`, selectable in `backup_restore_dialog.dart` behind a confirmation; wipes tables inside a transaction with a pre-restore safety backup). This contradicts the Constitution and ADR-0005 and is tracked as [[Technical-Debt-Registry]] TD-004 pending a user decision. Guardrails for safe-merge:
- Destructive table drops, truncated databases, or blind row replacements are forbidden.
- Restores execute entirely within a single Drift database transaction. If any entity fails foreign-key validation, the entire operation aborts and rolls back cleanly.

## 2. Restore Pipeline Stages
```text
1. User Selects JSON File
   ↓
2. Verify Format & Metadata (Validate schema version, top-level keys, SHA checksum)
   ↓
3. Read-Only Preview & Conflict Detection (Detect duplicate IDs, category collisions)
   ↓
4. Dry-Run Planner (Generates deterministic ID remapping table, checks blockers)
   ↓
5. Pre-Restore Safety Backup (Automatically writes snapshot to local disk)
   ↓
6. Transactional Safe-Merge (Additive writes using remapped IDs under Drift transaction)
   ↓
7. Post-Merge Verification & State Refresh (AppState reloads and notifies listeners)
```

## 3. Verified Container & Encryption (2026-10-15)
- JSON: `metadata.format = "walletmelt.local_json_backup"`, `format_version = 1` (snake_case). ZIP variant (when receipts included): `backup.json`, `metadata.json`, `receipts/*`. Files: `walletmelt-backup-<timestamp>.json|.zip`.
- Optional encryption: header `WMENC01`, PBKDF2-HMAC-SHA256 100k, AES-256-CTR, HMAC-SHA256 tag.
- Written keys: metadata, expenses, grocery_items, categories, budgets, monthly_budgets, settings. **Debts, subscriptions, payees, essentials, fuel are not exported** (data-loss risk on restore; see TD-005).
