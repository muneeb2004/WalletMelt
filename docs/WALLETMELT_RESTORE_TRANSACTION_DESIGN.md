# WalletMelt Restore Transaction Design

Phase: 14D/14E/14F/14G/14H - Restore Transaction Design, Dry-Run Preconditions, Safe-Merge Mutation Candidate, Restore Hardening, and UX Recovery Messaging

Status: Safe-merge restore execution exists behind validation, preview, conflict detection, dry-run planning, explicit confirmation, pre-restore safety backup creation, duplicate-heavy backup preflight, pre-commit relationship verification, idempotent Drift V1-to-V2 migration replay guards, and one Drift transaction. Phase 14H polished user-facing recovery messages without changing restore scope. Full replace, overwrite, uncontrolled merge, conflict resolution execution, manual ID remapping UI, receipt recovery, URI rewriting, and ZIP restore remain unsupported.

## 1. Current Boundary

WalletMelt currently supports export, backup generation, file picking, parse-only validation, preview, read-only conflict detection, dry-run restore planning, and a tightly gated safe-merge restore candidate. The Settings restore surface keeps restore disabled for invalid plans and only enables `Safe merge` when the dry-run plan has no unresolved blockers.

The current safe path is:

1. Pick JSON backup file.
2. Read file content.
3. Validate JSON format and supported version.
4. Build preview metadata and counts.
5. Compare backup content against current local data.
6. Show warnings/conflicts.
7. Build a dry-run plan with proposed future actions, proposed ID mappings, blockers, warnings, and safety-gate status.
8. If the dry-run plan has blockers, keep restore disabled and make no data changes.
9. If the dry-run plan is valid and blocker-free, require explicit user confirmation.
10. Create a pre-restore safety backup of current local data.
11. Execute safe merge inside one Drift transaction.
12. Refresh AppState after commit succeeds.

Any future mutation phase must preserve this validation, preview, conflict, dry-run, confirmation, and safety-backup sequence as the mandatory precondition path.

## 2. Restore Modes

### Preview-Only

Preview-only is the current and default mode.

- Validates the backup file.
- Shows metadata, counts, warnings, and conflict summary.
- Does not require a transaction.
- Does not require a pre-restore backup.
- Does not mutate expenses, grocery items, categories, budgets, settings, receipts, or canonical item data.

### Safe Merge

Safe merge is the first supported mutation mode as of Phase 14F.

- Adds missing records from a backup into the current local database.
- Preserves local data by default.
- Remaps duplicate IDs before insertion.
- Requires explicit user confirmation.
- Requires a pre-restore safety backup.
- Runs inside one database transaction.
- Rolls back the transaction on any failure.

Safe merge remains the only supported restore mutation mode.

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

Phase 14F implemented explicit-confirmed safe merge. Phase 14G hardened that path with duplicate-heavy backup blockers, service-level duplicate preflight, relationship verification before commit, restore-in-progress UI gating, idempotent migration replay guards for stale `user_version` databases, and additional rollback/refresh tests. Phase 14H improved the Settings restore wording, recovery messages, safety-backup communication, receipt limitation copy, and restore-in-progress messaging without adding a new restore mode.

Future full restore work should continue from this baseline and must not add full replace, overwrite, or silent merge until separate controls exist.

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
- Duplicate IDs inside the backup for categories, expenses, grocery items, or budgets.
- Duplicate category names inside the backup.
- Duplicate budget `month + category_id` pairs inside the backup.
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

## 5.5 Implemented Safe-Merge Execution

Phase 14F added `WalletMeltJsonRestoreService`.

The restore service:

- Supports safe merge only.
- Rejects full replace and unsupported restore modes.
- Requires `WalletMeltJsonRestoreOptions.confirmed == true`.
- Requires a valid, blocker-free `RestoreDryRunPlan`.
- Requires a non-empty `ExportFileResult` safety backup file before any write.
- Validates backup JSON again before mutation.
- Repeats duplicate-heavy backup preflight checks before transaction start.
- Uses dry-run ID mappings as the source of category, expense, grocery item, and budget target IDs.
- Writes database entities inside one Drift transaction.
- Verifies inserted expense/category, grocery item/expense, and budget/category relationships before commit.
- Rolls back the transaction on insert failures, unresolved mappings, foreign-key failures, count mismatches, relationship verification failures, or test-simulated failures.
- Returns `WalletMeltJsonRestoreResult` with inserted counts, skipped counts, warnings, safety backup path, and error text.

The Settings UI calls restore through `AppState.restoreJsonBackupSafeMerge`, not directly as a database consumer. AppState passes the existing Drift database runtime that it opened during initialization into the restore service, so the restore path does not open a competing database handle. If that Drift runtime is unavailable, production restore fails closed with a user-facing failure instead of attempting mutation through a new handle. AppState refresh runs only after the restore service reports success.

Phase 14G also hardened the Drift migration runtime used before restore. If a previous failed or interrupted V1-to-V2 migration left V2 tables/columns in place while `PRAGMA user_version` remained `1`, migration replay now skips already-existing V2 tables/columns instead of failing on duplicate table/column SQL. This does not change the schema version, add a migration, or edit generated Drift code; it only makes the existing V1-to-V2 migration idempotent for partially applied schemas.

Phase 14H keeps the same execution semantics and only improves user-facing communication:

- Validation success states the backup is valid, summarizes counts, and says no data has been imported.
- Preview text explains that safe merge preserves local data and does not recover receipt files.
- Blocker text says restore is unavailable until blockers are resolved and WalletMelt will not resolve conflicts automatically.
- Confirmation text explains safe merge, local preservation, duplicate ID remapping, safety backup creation, and receipt limitations.
- Success text reports inserted counts, safety backup filename when available, local-data preservation, and receipt text-reference behavior.
- Failure text avoids stack traces, states the restore failed safely, and explains transaction rollback should prevent partial imports.
- Safety-backup creation failure is shown immediately and states restore did not start and no data changed.

## 5.6 Implemented Safety Backup Behavior

Before safe merge starts, Settings creates a current-data JSON backup through the existing `WalletMeltJsonBackupService`.

The restore service verifies:

- the safety backup result has a path,
- the file exists,
- the reported byte count is greater than zero,
- the file length is greater than zero.

If any safety-backup check fails, restore aborts before transaction start.

## 6. Transaction Boundary

All future database writes must run inside a single transaction owned by one database runtime for the duration of the restore.

Required transaction properties:

- Atomicity: either all selected entity changes commit, or none commit.
- Relationship integrity: foreign keys and remapped references must be valid before commit.
- Deterministic order: writes must follow the import order above.
- No mixed uncontrolled handles: do not open competing database connections during restore.
- No UI state refresh until after commit succeeds.

Phase 14F/14G uses the AppState-owned Drift database instance as the restore transaction runtime because the migrated Drift database covers `categories`, `expenses`, `grocery_items`, `expense_items`, `category_budgets`, and `receipts`. sqflite fallback remains intact and was not removed. Restore does not use sqflite fallback for mutation.

## 7. Rollback Strategy

Rollback has two layers.

### Transaction Rollback

Any failure inside the transaction must abort and roll back all writes:

- Insert failure.
- Foreign key failure.
- Unique constraint failure.
- Failed ID remap lookup.
- Count mismatch.
- Relationship verification mismatch before commit.
- Unexpected database exception.
- Settings write failure if settings import is selected and included in the transaction boundary.

### Pre-Restore Safety Backup

Before starting mutation, create a pre-restore safety backup of the current local data. This backup must complete successfully before transaction start.

The safety backup should be retained if restore fails so the user has a recovery artifact.

### Post-Restore Verification

Before transaction commit, verify:

- Imported category count matches the accepted plan.
- Imported expense count matches the accepted plan.
- Imported grocery item count matches the accepted plan.
- Imported budget count matches the accepted plan.
- Every inserted expense references an existing category.
- Every inserted grocery item references an existing expense.
- Every inserted budget references an existing category.
- Settings changed only if settings import was selected.

If verification fails before commit, rollback. If any future post-commit verification is added and fails, surface a high-priority failure message and preserve the pre-restore backup for manual recovery.

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

Phase 14F keeps Settings UI import disabled. The restore service supports explicit settings import for future callers, but the production Settings action uses the safe default: `importSettings: false`.

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

## 14.1 Phase 14G Runtime QA Matrix

Target device: `Test_API_36` / `emulator-5554`.

Performed runtime scenarios:

- Clean install launched with empty dashboard state.
- Clean Settings JSON backup opened Android share sheet and returned stable.
- Valid backup selection opened preview, conflict/risk section, dry-run plan, and enabled safe merge when blockers were absent.
- Malformed JSON selection failed gracefully with an invalid-backup SnackBar.
- Cancelled picker returned to Settings without crash.
- Restore confirmation cancel returned to Settings without mutation.
- Confirmed safe merge created the pre-restore safety backup before mutation.
- Confirmed clean safe merge imported 1 expense, 1 grocery item, 1 category, and 1 budget.
- Dashboard, History, and Insights refreshed after successful commit.
- Receipt paths remained text references only; no receipt file was copied or URI rewritten.
- Old/inconsistent DB state reproduced a stale `user_version` migration failure, failed closed before mutation, and then passed after the idempotent migration guard.
- No `MissingPluginException`, Drift double-open warning, or runtime crash loop was observed in filtered logs.

Runtime scenario documented as automated-only:

- Non-empty duplicate-ID remap is covered by restore service tests and Settings widget tests. It was not repeated manually after the clean runtime restore because the stale `user_version` migration replay bug became the higher-risk emulator finding.

## 15. Phase 14D/14E/14F/14G Exclusions

These phases do not implement:

- Full replace restore.
- Overwrite restore.
- Silent merge.
- Conflict-resolution UI for category or budget ambiguity.
- Receipt recovery or file packaging.
- Receipt URI rewriting.
- ZIP/archive packaging.
- Receipt packaging.
- Cloud backup.
- Broad storage permissions.
- Settings import controls in Settings UI.
- sqflite restore executor.
