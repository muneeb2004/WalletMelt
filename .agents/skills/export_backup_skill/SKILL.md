---
name: export_backup_skill
description: Specifications for local backup ZIP packaging, JSON metadata schema, CSV export layouts, and database restore validation checks.
---

# WalletMelt Export/Backup Skill

## CSV Export Columns
- **Expenses CSV:** `id`, `date`, `title`, `amount`, `currency`, `category_name`, `vendor`, `notes`, `receipt_image_uri`, `is_recurring`, `created_at`
- **Itemized CSV:** CSV exports should support all expenses, itemized purchases, monthly summaries, annual summaries, and item price histories.

## Local ZIP Backup Layout
Backups must pack the local files into a single ZIP archive:
```text
walletmelt-backup.zip
├── wallet_melt.db         # SQLite database file
├── metadata.json          # Verification metadata
└── receipts/              # Folder containing copy of receipt images
```

## Metadata JSON Schema
```json
{
  "app_version": "0.1.0+1",
  "schema_version": 2,
  "export_timestamp": "2026-06-14T14:22:45Z",
  "platform": "Android",
  "receipt_file_count": 5,
  "database_file_name": "wallet_melt.db"
}
```

## Restore Safety & Recovery Checks
1. Unzip to temporary directories first.
2. Load and inspect `metadata.json` to verify schema version compatibility.
3. Verify SQLite file integrity before overwrite.
4. Replace active database file atomically.
5. Move receipt assets to active directories, adjusting paths as relative routes.

## Hard Rules
- Local-first design only; do not assume cloud syncing is available.
- Overwriting existing database files on restore must check validity and never fail silently.
