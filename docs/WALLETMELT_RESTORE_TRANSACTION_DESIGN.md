# WalletMelt Restore Transaction Design

Phase: 14D/14E - Restore Transaction Design, Rollback Planning, and Dry-Run Preconditions, Still No Mutation

Status: Design and dry-run planning only. No restore execution, database import, merge, overwrite, ID remapping execution, rollback execution, transaction execution, or backup-driven mutation exists in this phase.

## 1. Current Boundary

WalletMelt currently supports export, backup generation, file picking, parse-only validation, preview, read-only conflict detection, and read-only dry-run restore planning. The Settings restore surface intentionally stops at a disabled `Restore (N/A)` placeholder.

The current safe path is:

1. Pick JSON backup file.
2. Read file content.
3. Validate JSON format and supported version.
4. Build preview metadata and counts.
5. Compare backup content against current local data.
6. Show warnings/conflicts.
7. Build a dry-run plan with proposed future actions, proposed ID mappings, blockers, warnings, and safety-gate status.
8. Make no data changes.

Any future mutation phase must preserve this read-only path as the mandatory precondition sequence.

## 2. Restore Modes

### Preview-Only

Preview-only is the current and default mode.

- Validates the backup file.
- Shows metadata, counts, warnings, and conflict summary.
- Does not require a transaction.
- Does not require a pre-restore backup.
- Does not mutate expenses, grocery items, categories, budgets, settings, receipts, or canonical item data.

### Safe Merge

Safe merge is the recommended first mutation mode for a later phase.

- Adds missing records from a backup into the current local database.
- Preserves local data by default.
- Remaps duplicate IDs before insertion.
- Requires explicit user confirmation.
- Requires a pre-restore safety backup.
- Runs inside one database transaction.
- Rolls back the transaction on any failure.

Safe merge should be implemented before any full replace mode.

### Full Replace / Import

Full replace is not recommended as the first mutation mode.

If ever supported, it must require stronger controls:

- High-visibility warning that local data may be replaced.
- Pre-restore backup creation and verification.
- Post-restore count and relationship verification.
- Recovery instructions if the app is killed mid-restore.
- Separate QA matrix from safe merge.

Full replace remains unsupported until those controls exist.

## 3. Recommended First Mutation Mode

The first future mutation phase should implement either:

1. Explicit-confirmed safe merge, or
2. A sandboxed import path that writes to temporary tables or an isolated temporary database before promoting records.

The safer practical first step is explicit-confirmed safe merge because it can preserve current data and use ID remapping for collisions.

## 4. Entities Covered

The restore transaction design covers the current JSON backup entities:

- `categories`
- `expenses`
- `grocery_items`
- `budgets`
- `settings`
- receipt URI/path references inside `expenses.receipt_image_uri`

Receipt image files are not packaged in the JSON backup. Restore must treat receipt values as text references only.

## 5. Future Import Order

The required future sequence is:

1. Validate format.
2. Parse backup.
3. Build preview.
4. Run conflict detection.
5. Require explicit confirmation.
6. Create pre-restore safety backup.
7. Start database transaction.
8. Import or remap categories.
9. Import or remap expenses.
10. Import or remap grocery items.
11. Import or remap budgets.
12. Import settings only if selected.
13. Verify counts and relationships.
14. Commit or rollback.
15. Refresh AppState and screen-facing state.

No step after confirmation may run unless all prior validation and safety gates are satisfied.

## 5.1 Implemented Dry-Run Planner

Phase 14E added `WalletMeltJsonRestoreDryRunPlanner`.

The dry-run planner:

- Accepts raw JSON backup text and a caller-supplied `LocalAppSnapshot`.
- Reuses the existing backup validator as the boundary for supported format and format version checks.
- Never calls repositories.
- Never opens Drift or sqflite.
- Never mutates AppState.
- Never enables restore.
- Produces `RestoreDryRunPlan`, including proposed actions, proposed ID mappings, blocker/warning issues, entity counts, future transaction steps, and safety-gate status.

The dry-run plan is advisory. It is not an executable import plan and must not be treated as permission to mutate the database.

## 5.2 Implemented Dry-Run ID Mapping Rules

The Phase 14E planner calculates mappings in memory only:

- Category IDs are preserved when no local collision exists.
- Equivalent local categories with the same ID are mapped to the existing local category.
- Default-like category name matches may map to the existing local category with a warning.
- Custom category name ambiguity becomes a blocker until a future user choice exists.
- Conflicting category IDs with different local content receive deterministic proposed replacement IDs.
- Expense IDs are preserved when available and receive deterministic proposed replacement IDs when duplicated locally.
- Grocery item references are planned through `expenseIdMap`.
- Budget category references are planned through `categoryIdMap`.

These mappings are not executed and are not written to storage.

## 5.3 Implemented Dry-Run Blockers And Warnings

Dry-run blockers include:

- Invalid or unsupported backup format/version.
- Missing required IDs on planned entities.
- Expense category references that cannot resolve.
- Grocery items whose parent expense cannot resolve.
- Budgets whose category cannot resolve.
- Budget `month + category_id` collisions with local data.
- Custom category name ambiguity that requires user choice.

Dry-run warnings include:

- Receipt URI/path references that are text-only and may be missing on the device.
- Soft-deleted expenses that would remain soft-deleted.
- Settings present while settings import is not selected.
- Settings differences when settings import is selected.
- Default-like category name mapping.
- Proposed new IDs for safe merge collisions.

## 5.4 Implemented Dry-Run Safety Gate Status

The dry-run planner reports safety gates, including:

- Backup format supported.
- Format version supported.
- Preview generated.
- Conflict summary reviewed.
- Explicit confirmation still required later.
- Pre-restore backup still required later.
- Transaction runtime still required later.
- No unresolved blockers.

Because explicit confirmation, pre-restore backup creation, and transaction runtime are deliberately not implemented in Phase 14E, the dry-run plan cannot start mutation.

## 6. Transaction Boundary

All future database writes must run inside a single transaction owned by one database runtime for the duration of the restore.

Required transaction properties:

- Atomicity: either all selected entity changes commit, or none commit.
- Relationship integrity: foreign keys and remapped references must be valid before commit.
- Deterministic order: writes must follow the import order above.
- No mixed uncontrolled handles: do not open competing database connections during restore.
- No UI state refresh until after commit succeeds.

The future implementation must decide the primary write runtime before mutation. Given the current migration track, Drift should be preferred for transactional restore if it can cover all required tables safely. sqflite fallback must remain intact and must not be removed.

## 7. Rollback Strategy

Rollback has two layers.

### Transaction Rollback

Any failure inside the transaction must abort and roll back all writes:

- Insert failure.
- Foreign key failure.
- Unique constraint failure.
- Failed ID remap lookup.
- Count mismatch.
- Unexpected database exception.
- Settings write failure if settings import is selected and included in the transaction boundary.

### Pre-Restore Safety Backup

Before starting mutation, create a pre-restore safety backup of the current local data. This backup must complete successfully before transaction start.

The safety backup should be retained if restore fails so the user has a recovery artifact.

### Post-Restore Verification

After transaction commit, verify:

- Imported category count matches the accepted plan.
- Imported expense count matches the accepted plan.
- Imported grocery item count matches the accepted plan.
- Imported budget count matches the accepted plan.
- No grocery items reference missing expenses.
- No budgets reference missing categories.
- Settings changed only if settings import was selected.

If verification fails before commit, rollback. If verification fails after commit, surface a high-priority failure message and preserve the pre-restore backup for manual recovery.

## 8. ID Strategy

### Preserve IDs When Safe

Preserve backup IDs only when:

- The ID does not exist locally.
- The record relationship graph remains valid.
- The ID does not collide with any record inserted earlier in the same import plan.

### Remap Duplicate IDs

Duplicate IDs must be remapped before insertion.

The restore planner must build in-memory mapping tables:

- `categoryIdMap`: backup category ID to local category ID.
- `expenseIdMap`: backup expense ID to local expense ID.
- `groceryItemIdMap`: backup grocery item ID to local grocery item ID.
- `budgetIdMap`: backup budget ID to local budget ID.

References must be rewritten using these maps:

- `expenses.category_id` uses `categoryIdMap`.
- `grocery_items.expense_id` uses `expenseIdMap`.
- `budgets.category_id` uses `categoryIdMap`.

No record may be inserted until all referenced IDs can resolve to either an existing local ID or a planned inserted ID.

## 9. Duplicate Handling

### Category ID Conflicts

If a backup category ID exists locally:

- If name/icon/color are equivalent enough, map the backup category ID to the local ID.
- If they differ, generate a new ID for the backup category or block the import until the user chooses a resolution.

### Category Name Conflicts

If a backup category name matches a local category but the ID differs:

- Prefer mapping by name for default-like categories only after a preview warning.
- For custom categories, either map by name with confirmation or generate a new ID.

### Expense ID Conflicts

If a backup expense ID exists locally:

- Generate a new expense ID for safe merge.
- Preserve all expense fields.
- Update grocery item references through `expenseIdMap`.

### Budget Month/Category Conflicts

Budgets are unique by semantic pair: `month + category_id`.

For safe merge:

- If the local pair exists, do not overwrite silently.
- Either skip, keep local, or require explicit user choice in a future conflict-resolution UI.
- If the category ID is remapped, evaluate the conflict against the remapped category ID.

### Grocery Item ID Conflicts

If a grocery item ID exists locally:

- Generate a new grocery item ID.
- Keep `expense_id` linked to the resolved expense ID.

Orphaned grocery items must block mutation unless explicitly skipped by a future plan.

## 10. Receipt URI/Path Strategy

Receipt restore is text-only for JSON backups.

- Preserve `receipt_image_uri` text if the expense is imported.
- Warn that the referenced file may not exist on this device.
- Do not copy receipt files.
- Do not rewrite URIs.
- Do not promise media recovery without a future archive/receipt packaging format.

If future ZIP backups package receipt files, that work must use a separate format/version and a separate restore design.

## 11. Settings Strategy

Settings import must be optional and explicit.

Default behavior:

- Do not import settings.
- Do not silently overwrite currency, theme, onboarding, or export timestamps.

If selected:

- Show a settings diff before confirmation.
- Apply settings only after data entities pass validation.
- Consider applying settings after database entity writes, but still inside the broader restore operation boundary.
- Refresh AppState after commit.

## 12. Safety Gates

Future mutation cannot start unless all safety gates pass:

- Backup format is supported.
- Format version is supported.
- Required arrays are present.
- Backup preview has been generated.
- Conflict summary has been reviewed.
- User gives explicit confirmation.
- Pre-restore backup has been created successfully.
- Transaction runtime is available.
- Restore plan has no unresolved blocker issues.
- Tests for the restore planner and transaction path pass.

Full replace must require additional explicit data-loss confirmation and remains unsupported.

## 13. Failure Cases

The future planner and executor must handle:

- Malformed JSON.
- Missing required arrays.
- Unsupported format.
- Unsupported format version.
- Duplicate IDs.
- Duplicate category names.
- Duplicate budget `month + category_id` pairs.
- Orphaned grocery items.
- Orphaned budgets.
- File read failure.
- Pre-restore backup failure.
- Write failure.
- Partial restore failure.
- Settings write failure.
- App killed mid-restore.
- Missing receipt files.
- AppState refresh failure after commit.

Every failure must produce a user-facing message and must not fail silently.

## 14. Future QA Matrix

Required future restore QA:

- Empty app safe merge.
- Non-empty app safe merge.
- Duplicate-heavy backup.
- Backup with soft-deleted expenses.
- Backup with missing receipt paths.
- Backup with orphaned grocery items.
- Backup with orphaned budgets.
- Settings import disabled.
- Settings import enabled.
- Rollback failure simulation.
- App killed during restore simulation.
- Post-restore dashboard/history/insights consistency.
- No database double-open warning.

## 15. Phase 14D/14E Exclusions

These phases do not implement:

- Restore execution.
- Database import.
- Merge or overwrite mutation.
- ID remapping execution.
- Rollback execution.
- Transaction code.
- Receipt recovery.
- Receipt URI rewriting.
- ZIP/archive packaging.
- AppState restore mutation methods.
- Settings UI restore enablement.
