# Export/Backup Skill

## CSV Export Structure
- **Expense Exports:** Export file columns must map clearly:
  - `id`, `date`, `title`, `amount`, `currency`, `category_name`, `vendor`, `notes`, `receipt_image_uri`, `is_recurring`, `created_at`
- **Itemized Exports:** Export grocery items or receipt breakdown details in a separate related sheet or nested list.
- **Encoding:** Output files must use `UTF-8` encoding and standard comma separations to support compatibility across spreadsheets.

## Local ZIP Backup Layout
Backups are packed into a single zip file containing:
```text
backup_archive.zip
├── wallet_melt_backup.db      # Copy of the SQLite database
├── metadata.json              # App version, creation timestamp, and backup info
└── receipts/                  # Directory containing copies of all receipt images
    ├── receipt_1.jpg
    └── receipt_2.png
```

## Metadata JSON Schema
Define metadata properties clearly:
```json
{
  "app_id": "com.walletmelt.app",
  "app_version": "0.1.0+1",
  "database_schema_version": 2,
  "backup_timestamp": "2026-06-14T13:54:56Z",
  "device_info": "Android API 34",
  "total_records": {
    "expenses": 142,
    "categories": 12,
    "budgets": 8,
    "receipts": 5
  }
}
```

## Receipt Storage Preservation
- **Path Adjustments:** Receipt paths inside the database must be stored relative to the local app document folder (e.g. `receipts/receipt_1.jpg`) rather than absolute device file system paths. This ensures attachments load correctly when restored on different devices.

## Restore Safety & Verification
- **Validation Steps:**
  1. Parse `metadata.json` first to confirm matching package name and compatible database version.
  2. Perform SQLite integrity check (`PRAGMA integrity_check;`) on the backup database before overwrite.
  3. Extract receipt images to the app document receipts folder.
  4. Perform atomic replacement of the active database file (`wallet_melt.db`) to prevent data loss.
  5. Restart the database connection session and call `AppState.refresh()` to update the UI.
