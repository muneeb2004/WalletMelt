---
type: knowledge
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-17
domain: backup
related:
  - "[[Backup-and-Restore-Architecture]]"
  - "[[ADR-0005-Safe-Merge-Transactional-Restore]]"
  - "[[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]"
---

# Backup Format Specification (matches code as of 2026-10-15)

## 1. Container
- **JSON**: `walletmelt-backup-<timestamp>.json` (pretty-printed UTF-8).
- **ZIP** (when receipts are packaged): `backup.json`, `metadata.json`, `receipts/<basename>`.
- **Encrypted** (optional passphrase): `WMENC01` header | 16-byte salt | 16-byte IV | ciphertext | 32-byte HMAC-SHA256 tag. PBKDF2-HMAC-SHA256 100k iterations -> 64 bytes (32 AES-256-CTR key + 32 HMAC key). The whole JSON or ZIP is encrypted.

## 2. `backup.json` (format_version 2)
```json
{
  "metadata": {
    "format": "walletmelt.local_json_backup",
    "format_version": 2,
    "schema_version": 10,
    "app_version": "1.1.2+6",
    "exported_at": "2026-10-15T12:00:00.000",
    "includes": ["expenses", "grocery_items", "categories", "budgets", "monthly_budgets", "settings", "extended"],
    "checksum": "sha256:<hex>"
  },
  "expenses": [], "grocery_items": [], "categories": [], "budgets": [],
  "monthly_budgets": [], "settings": {},
  "extended": {
    "tables": { "units": [], "payees": [], "stores": [], "items": [], "item_aliases": [],
                "debt_records": [], "debt_repayments": [], "grocery_templates": [],
                "subscriptions": [], "essential_expense_templates": [],
                "fuel_template_components": [], "expense_items": [], "receipts": [],
                "fuel_transactions": [], "fuel_components": [],
                "accounts": [], "account_movements": [] },
    "expense_store_links": [{ "expense_id": "...", "store_id": "..." }],
    "expense_account_links": [{ "expense_id": "...", "account_id": "..." }]
  }
}
```
- v1 files (no `extended`, no checksum, `format_version: 1`) are still accepted; they can only be Safe-Merged.
- Core sections use snake_case keys written by `WalletMeltJsonBackupEncoder`. `extended.tables.*` rows use Drift's generated JSON (column names, e.g. `normalizedName`).
- **Checksum**: SHA-256 of `jsonEncode` (compact) of the root map with `metadata.checksum` removed. Required for v2; mismatch => rejected as corrupted/modified.
- `schema_version` newer than the app's Drift schema => rejected.
- Not exported: `migration_audit`, `sync_metadata`.

## 3. Restore rules
1. **Safe Merge**: expenses/categories/budgets by existing conflict rules; monthly budgets skipped if the month exists; extended rows: PK collision keeps local row; natural-key (`normalizedName`) collision maps to the existing row and children are re-pointed; expense-scoped children (expense items, receipts, fuel) only for expenses newly inserted by this restore; derived rows (expense item per grocery item, `legacy_receipt_*`) are deduplicated by id or by (expense, name, total) / (expense, uri). Commit is refused if foreign-key violations increase.
2. **Full Replace** (v2 only): deletes all 23 data tables child-first (`account_movements` then `accounts` after `expenses`), re-inserts parent-first with foreign keys ON, `foreign_key_check` must be clean, then back-fills minor units. Any failure rolls back everything.
3. Receipts: file copy only from ZIP backups; JSON backups carry text references.

## 4. Accounts (schema v10, 2026-10-17)
- `accounts` and `account_movements` are **optional** extended tables and `expense_account_links` is an optional list: a v2 file written before v10 lacks them and still validates and restores (accounts empty, expenses unassigned). Missing keys mean "no rows", never an error. Format version stays 2.
- Expenses are serialized by the core encoder, which has no `accountId`; the link is carried by `expense_account_links` and applied after accounts are inserted (mirrors `expense_store_links`). Safe Merge applies a link only for expenses newly inserted by that restore. Accounts merge by id (PK collision keeps the local row); movements follow the same rule.
- Tests: `test/services/export/backup_v2_roundtrip_test.dart` (round trip, replace over existing accounts, pre-accounts v2 file).
