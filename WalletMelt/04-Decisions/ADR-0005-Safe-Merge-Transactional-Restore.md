---
type: adr
status: accepted
created: 2026-09-01
updated: 2026-10-15
domain: architecture
related:
  - "[[Backup-and-Restore-Architecture]]"
---

# ADR-0005: Safe-Merge Transactional Restore Strategy

## Status
Accepted

## Context
When restoring a JSON backup, naive approaches often drop tables or perform blind `INSERT OR REPLACE` operations, risking accidental overwrites of newer transactions or custom category IDs.

## Decision
Adopt a strictly **Safe-Merge** restore pipeline:
1. Format validation and SHA-256 integrity check.
2. Read-only preview and conflict detection before mutation.
3. Automatic pre-restore backup snapshot saved to disk.
4. Deterministic ID remapping table to avoid collision.
5. Single Drift database transaction: any failure rolls back 100% of mutations.
6. Blocker-gated UX: restore button remains disabled until conflicts are cleared.

## Alternatives Considered
1. **Full Database Overwrite / Replace**: Rejected due to high catastrophic data-loss risk.
2. **Manual Field-by-Field Merge Dialog**: Deferred to future releases to keep v1 restore robust and simple.

## Consequences
- **Positive**: Zero data loss, fail-safe rollback, guarantees relational integrity between expenses, categories, and items.
- **Negative**: Restore logic requires dry-run planning and remapping tables.

## Related Code
- `lib/src/services/export/wallet_melt_json_restore_service.dart`
- `lib/src/services/export/wallet_melt_json_restore_dry_run_planner.dart`

> **Update 2026-10-15:** refined by [[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]: Full Replace is now allowed for complete v2 backups under strict conditions; Safe Merge remains the default.
