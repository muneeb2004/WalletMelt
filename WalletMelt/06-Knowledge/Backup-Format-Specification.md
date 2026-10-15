---
type: knowledge
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: backup
related:
  - "[[Backup-and-Restore-Architecture]]"
  - "[[ADR-0005-Safe-Merge-Transactional-Restore]]"
---

# Backup Format Specification

## 1. Format Overview
- **Type**: Formatted JSON file exported via system share sheet.
- **Naming Pattern**: `wallet_melt_backup_YYYYMMDD_HHMMSS.json`.
- **Top-Level Structure**:
  ```json
  {
    "metadata": {
      "formatVersion": 2,
      "appVersion": "1.1.2+6",
      "exportedAt": "2026-09-13T14:48:00.000Z",
      "checksum": "sha256:..."
    },
    "categories": [...],
    "expenses": [...],
    "groceryItems": [...],
    "categoryBudgets": [...],
    "monthlyBudgets": [...],
    "debts": [...],
    "subscriptions": [...],
    "settings": {...}
  }
  ```

## 2. Safe-Merge Conflict Rules
1. **Expenses**: If an expense ID already exists locally, check hash. If distinct, remap to new UUID.
2. **Categories**: Standard categories match by name/id. Custom categories match by normalized name. Collisions with mismatched properties are treated as blockers to prevent corruption.
3. **Receipts**: Preserved as text URIs (`receiptImageUri`). Physical image files are not modified during JSON restore.

> **Drift warning (2026-10-15):** this spec describes `formatVersion = 2`, camelCase keys, a `sha256:` checksum and debts/subscriptions. The code writes `format_version = 1`, snake_case keys, **no checksum**, and omits debts/subscriptions. Authoritative sources of truth for current behavior: `wallet_melt_json_backup_encoder.dart` and [[Backup-and-Restore-Architecture]] §3. Treat the rest of this note as a *target* spec, not implemented behavior.
