import 'wallet_melt_json_backup_extended_tables.dart';
import 'dart:convert';
import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/wallet_melt_database.dart' as local;
import '../../services/settings/settings_service.dart';
import '../../types/settings.dart';
import 'export_file_writer.dart';
import 'wallet_melt_json_backup_validator.dart';
import 'wallet_melt_json_restore_dry_run_planner.dart';
import 'wallet_melt_json_restore_plan.dart';

class WalletMeltJsonRestoreOptions {
  const WalletMeltJsonRestoreOptions({
    this.mode = RestoreMode.safeMerge,
    this.importSettings = false,
    this.skipBudgetConflicts = false,
    this.skipOrphanGroceryItems = false,
    this.confirmed = false,
    this.expenseResolutions = const {},
    this.categoryResolutions = const {},
    this.budgetResolutions = const {},
  });

  final RestoreMode mode;
  final bool importSettings;
  final bool skipBudgetConflicts;
  final bool skipOrphanGroceryItems;
  final bool confirmed;
  final Map<String, ConflictResolution> expenseResolutions;
  final Map<String, ConflictResolution> categoryResolutions;
  final Map<String, ConflictResolution> budgetResolutions;
}


class WalletMeltJsonRestoreResult {
  const WalletMeltJsonRestoreResult({
    required this.success,
    this.safetyBackupPath,
    this.insertedCategories = 0,
    this.insertedExpenses = 0,
    this.insertedGroceryItems = 0,
    this.insertedBudgets = 0,
    this.settingsImported = false,
    this.skippedItems = 0,
    this.warnings = const [],
    this.errorMessage,
  });

  factory WalletMeltJsonRestoreResult.failure(
    String message, {
    String? safetyBackupPath,
    List<String> warnings = const [],
  }) {
    return WalletMeltJsonRestoreResult(
      success: false,
      safetyBackupPath: safetyBackupPath,
      errorMessage: message,
      warnings: warnings,
    );
  }

  final bool success;
  final String? safetyBackupPath;
  final int insertedCategories;
  final int insertedExpenses;
  final int insertedGroceryItems;
  final int insertedBudgets;
  final bool settingsImported;
  final int skippedItems;
  final List<String> warnings;
  final String? errorMessage;
}

class WalletMeltJsonRestoreService {
  const WalletMeltJsonRestoreService({
    local.WalletMeltDatabase? database,
    SettingsService? settingsService,
    WalletMeltJsonBackupValidator validator =
        const WalletMeltJsonBackupValidator(),
    @visibleForTesting this.debugOnStep,
  })  : _database = database,
        _settingsService = settingsService,
        _validator = validator;

  final local.WalletMeltDatabase? _database;
  final SettingsService? _settingsService;
  final WalletMeltJsonBackupValidator _validator;

  @visibleForTesting
  final Future<void> Function(RestoreExecutionStep step)? debugOnStep;

  Future<WalletMeltJsonRestoreResult> restoreSafeMerge({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required WalletMeltJsonRestoreOptions options,
    required ExportFileResult safetyBackup,
    local.WalletMeltDatabase? database,
    io.Directory? zipExtractDir,
  }) async {
    final preflightFailure = await _preflightFailure(
      jsonText: jsonText,
      dryRunPlan: dryRunPlan,
      options: options,
      safetyBackup: safetyBackup,
    );
    if (preflightFailure != null) return preflightFailure;

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return WalletMeltJsonRestoreResult.failure(
          'Backup root is not a JSON object.',
          safetyBackupPath: safetyBackup.path,
        );
      }

      final backup = decoded.cast<String, Object?>();
      final categoryMaps = _mappingsFor(
        dryRunPlan,
        RestoreDryRunEntity.category,
      );
      final expenseMaps = _mappingsFor(
        dryRunPlan,
        RestoreDryRunEntity.expense,
      );
      final groceryItemMaps = _mappingsFor(
        dryRunPlan,
        RestoreDryRunEntity.groceryItem,
      );
      final budgetMaps = _mappingsFor(
        dryRunPlan,
        RestoreDryRunEntity.budget,
      );

      final db = database ?? _database ?? await local.WalletMeltDatabase.open();
      final state = _RestoreMutationState(safetyBackupPath: safetyBackup.path);

      await _onStep(RestoreExecutionStep.startTransaction);
      await db.transaction(() async {
        await _onStep(RestoreExecutionStep.importOrRemapCategories);
        state.insertedCategories = await _mergeCategories(
          db,
          _asMaps(backup['categories']),
          categoryMaps,
        );

        await _onStep(RestoreExecutionStep.importOrRemapExpenses);
        state.insertedExpenses = await _mergeExpenses(
          db,
          _asMaps(backup['expenses']),
          categoryMaps,
          expenseMaps,
          state,
          zipExtractDir: zipExtractDir,
          options: options,
        );

        await _onStep(RestoreExecutionStep.importOrRemapGroceryItems);
        state.insertedGroceryItems = await _mergeGroceryItems(
          db,
          _asMaps(backup['grocery_items']),
          expenseMaps,
          groceryItemMaps,
          state,
        );

        await _onStep(RestoreExecutionStep.importOrRemapBudgets);
        final budgetResult = await _mergeBudgets(
          db,
          _asMaps(backup['budgets']),
          categoryMaps,
          budgetMaps,
          state: state,
          skipConflicts: options.skipBudgetConflicts,
        );
        state.insertedBudgets = budgetResult.inserted;
        state.skippedItems += budgetResult.skipped;
        state.warnings.addAll(budgetResult.warnings);

        final violationsBefore = await _foreignKeyViolationCount(db);
        await _mergeMonthlyBudgets(db, _asMaps(backup['monthly_budgets']));
        final extendedSection = backup[BackupExtendedTables.sectionKey];
        if (extendedSection is Map) {
          state.extendedCounts = await BackupExtendedTables.importInto(
            db,
            extendedSection.cast<String, Object?>(),
            replace: false,
            categoryMap: categoryMaps,
            expenseMap: expenseMaps,
            importedExpenseIds: state.insertedExpenseIds.toSet(),
          );
        }

        if (options.importSettings) {
          await _onStep(RestoreExecutionStep.importSettingsIfSelected);
          state.settingsImported = await _importSettings(backup['settings']);
        }

        await db.backfillMinorUnits();
        await _onStep(RestoreExecutionStep.verifyCounts);
        _verifyCounts(dryRunPlan, state);
        await _verifyInsertedRelationships(db, state);
        await _requireNoForeignKeyViolations(db, baseline: violationsBefore);
      });
      await _onStep(RestoreExecutionStep.commitOrRollback);

      return WalletMeltJsonRestoreResult(
        success: true,
        safetyBackupPath: safetyBackup.path,
        insertedCategories: state.insertedCategories,
        insertedExpenses: state.insertedExpenses,
        insertedGroceryItems: state.insertedGroceryItems,
        insertedBudgets: state.insertedBudgets,
        settingsImported: state.settingsImported,
        skippedItems: state.skippedItems,
        warnings: List.unmodifiable(state.warnings),
      );
    } catch (error) {
      return WalletMeltJsonRestoreResult.failure(
        'Safe merge restore failed: $error',
        safetyBackupPath: safetyBackup.path,
      );
    }
  }

  Future<WalletMeltJsonRestoreResult> restoreFullReplace({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required WalletMeltJsonRestoreOptions options,
    required ExportFileResult safetyBackup,
    local.WalletMeltDatabase? database,
    io.Directory? zipExtractDir,
  }) async {
    final preflightFailure = await _preflightFailure(
      jsonText: jsonText,
      dryRunPlan: dryRunPlan,
      options: options,
      safetyBackup: safetyBackup,
    );
    if (preflightFailure != null) return preflightFailure;

    final db = database ?? _database ?? await local.WalletMeltDatabase.open();
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      return WalletMeltJsonRestoreResult.failure(
        'Backup root is not a JSON object.',
        safetyBackupPath: safetyBackup.path,
      );
    }
    final backup = decoded.cast<String, Object?>();

    if (backup[BackupExtendedTables.sectionKey] is! Map) {
      return WalletMeltJsonRestoreResult.failure(
        'Full replace needs a complete (format v2) backup. This backup does '
        'not contain debts, subscriptions, payees, essentials or fuel data, so '
        'replacing the database with it would lose them. Use Safe Merge instead.',
        safetyBackupPath: safetyBackup.path,
      );
    }

    try {
      final state = _RestoreMutationState(safetyBackupPath: safetyBackup.path);

      await _onStep(RestoreExecutionStep.startTransaction);
      await db.transaction(() async {
        // Foreign keys stay ON: children are deleted before parents and
        // inserted after them, and a foreign_key_check gates the commit.
        await _deleteAllUserData(db);

        // Identity ID maps (the database is empty, so nothing can collide).
        final categoryMaps = <String, String>{
          for (final c in _asMaps(backup['categories']))
            _requiredString(c, 'id'): _requiredString(c, 'id'),
        };
        final expenseMaps = <String, String>{
          for (final e in _asMaps(backup['expenses']))
            _requiredString(e, 'id'): _requiredString(e, 'id'),
        };
        final groceryItemMaps = <String, String>{
          for (final i in _asMaps(backup['grocery_items']))
            _requiredString(i, 'id'): _requiredString(i, 'id'),
        };
        final budgetMaps = <String, String>{
          for (final b in _asMaps(backup['budgets']))
            _requiredString(b, 'id'): _requiredString(b, 'id'),
        };

        state.insertedCategories = await _mergeCategories(
          db,
          _asMaps(backup['categories']),
          categoryMaps,
        );
        state.insertedExpenses = await _mergeExpenses(
          db,
          _asMaps(backup['expenses']),
          categoryMaps,
          expenseMaps,
          state,
          zipExtractDir: zipExtractDir,
          options: options,
        );
        state.insertedGroceryItems = await _mergeGroceryItems(
          db,
          _asMaps(backup['grocery_items']),
          expenseMaps,
          groceryItemMaps,
          state,
        );
        final budgetResult = await _mergeBudgets(
          db,
          _asMaps(backup['budgets']),
          categoryMaps,
          budgetMaps,
          state: state,
          skipConflicts: false,
        );
        state.insertedBudgets = budgetResult.inserted;
        state.skippedItems += budgetResult.skipped;
        state.warnings.addAll(budgetResult.warnings);

        await _mergeMonthlyBudgets(db, _asMaps(backup['monthly_budgets']));
        state.extendedCounts = await BackupExtendedTables.importInto(
          db,
          (backup[BackupExtendedTables.sectionKey]! as Map)
              .cast<String, Object?>(),
          replace: true,
          categoryMap: categoryMaps,
          expenseMap: expenseMaps,
          importedExpenseIds: state.insertedExpenseIds.toSet(),
        );

        if (options.importSettings) {
          state.settingsImported = await _importSettings(backup['settings']);
        }

        await db.backfillMinorUnits();
        await _onStep(RestoreExecutionStep.verifyCounts);
        _verifyCounts(dryRunPlan, state);
        await _verifyInsertedRelationships(db, state);
        await _requireNoForeignKeyViolations(db, baseline: 0);
      });
      await _onStep(RestoreExecutionStep.commitOrRollback);

      return WalletMeltJsonRestoreResult(
        success: true,
        safetyBackupPath: safetyBackup.path,
        insertedCategories: state.insertedCategories,
        insertedExpenses: state.insertedExpenses,
        insertedGroceryItems: state.insertedGroceryItems,
        insertedBudgets: state.insertedBudgets,
        settingsImported: state.settingsImported,
        skippedItems: state.skippedItems,
        warnings: List.unmodifiable(state.warnings),
      );
    } catch (error) {
      // The transaction has already rolled back; no destructive "recovery"
      // pass is attempted. The safety backup stays on disk for manual recovery.
      return WalletMeltJsonRestoreResult.failure(
        'Replace restore failed and the database was rolled back unchanged: $error',
        safetyBackupPath: safetyBackup.path,
      );
    }
  }

  Future<WalletMeltJsonRestoreResult?> _preflightFailure({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required WalletMeltJsonRestoreOptions options,
    required ExportFileResult safetyBackup,
  }) async {
    if (options.mode != RestoreMode.safeMerge && options.mode != RestoreMode.fullReplace) {
      return WalletMeltJsonRestoreResult.failure(
        'Unsupported restore mode.',
      );
    }
    if (!options.confirmed) {
      return WalletMeltJsonRestoreResult.failure(
        'Restore requires explicit confirmation.',
      );
    }
    if (options.skipOrphanGroceryItems) {
      return WalletMeltJsonRestoreResult.failure(
        'Skipping orphan grocery items is not supported yet.',
      );
    }
    final validation = _validator.validate(jsonText);
    if (!validation.isValid) {
      return WalletMeltJsonRestoreResult.failure(
        validation.error ?? 'Backup validation failed.',
      );
    }
    final backupPreflightIssues = _backupPreflightIssues(jsonText);
    if (backupPreflightIssues.isNotEmpty) {
      return WalletMeltJsonRestoreResult.failure(
        'Backup cannot be restored safely: ${backupPreflightIssues.join('; ')}',
      );
    }
    if (!dryRunPlan.isValid) {
      return WalletMeltJsonRestoreResult.failure(
        dryRunPlan.error ?? 'Dry-run plan is invalid.',
      );
    }
    if (options.mode == RestoreMode.safeMerge && dryRunPlan.hasBlockers) {
      return WalletMeltJsonRestoreResult.failure(
        'Restore blocked by dry-run issues: '
        '${dryRunPlan.issues.where((issue) => issue.isBlocker).map((issue) => issue.message).join('; ')}',
      );
    }
    if (!_dryRunGateSatisfied(
      dryRunPlan,
      RestoreDryRunSafetyGate.backupFormatSupported,
    )) {
      return WalletMeltJsonRestoreResult.failure(
        'Backup format was not accepted by the dry-run plan.',
      );
    }
    if (!_dryRunGateSatisfied(
      dryRunPlan,
      RestoreDryRunSafetyGate.formatVersionSupported,
    )) {
      return WalletMeltJsonRestoreResult.failure(
        'Backup format version was not accepted by the dry-run plan.',
      );
    }
    if (!_dryRunGateSatisfied(
      dryRunPlan,
      RestoreDryRunSafetyGate.previewGenerated,
    )) {
      return WalletMeltJsonRestoreResult.failure(
        'Backup preview must be generated before restore.',
      );
    }
    if (options.mode == RestoreMode.safeMerge && !_dryRunGateSatisfied(
      dryRunPlan,
      RestoreDryRunSafetyGate.conflictSummaryReviewed,
    )) {
      return WalletMeltJsonRestoreResult.failure(
        'Conflict summary must be reviewed before restore.',
      );
    }

    final safetyFile = io.File(safetyBackup.path);
    if (safetyBackup.byteCount <= 0 || !await safetyFile.exists()) {
      return WalletMeltJsonRestoreResult.failure(
        'Pre-restore safety backup was not created.',
      );
    }
    final safetyFileSize = await safetyFile.length();
    if (safetyFileSize <= 0) {
      return WalletMeltJsonRestoreResult.failure(
        'Pre-restore safety backup is empty.',
      );
    }
    return null;
  }


  Future<int> _mergeCategories(
    local.WalletMeltDatabase db,
    List<Map<String, Object?>> categories,
    Map<String, String> categoryMaps,
  ) async {
    var inserted = 0;
    for (final category in categories) {
      final sourceId = _requiredString(category, 'id');
      final targetId = categoryMaps[sourceId];
      if (targetId == null) {
        throw StateError('No category mapping for "$sourceId".');
      }
      final existing = await _categoryExists(db, targetId);
      if (existing) continue;

      await db.into(db.categories).insert(
            local.CategoriesCompanion.insert(
              id: targetId,
              name: _requiredString(category, 'name'),
              icon: _requiredString(category, 'icon'),
              color: _requiredString(category, 'color'),
              isDefault: _boolValue(category['is_default']),
              createdAt: _requiredString(category, 'created_at'),
              updatedAt: _requiredString(category, 'updated_at'),
            ),
          );
      inserted++;
    }
    return inserted;
  }

  Future<int> _mergeExpenses(
    local.WalletMeltDatabase db,
    List<Map<String, Object?>> expenses,
    Map<String, String> categoryMaps,
    Map<String, String> expenseMaps,
    _RestoreMutationState state, {
    io.Directory? zipExtractDir,
    required WalletMeltJsonRestoreOptions options,
  }) async {
    var inserted = 0;
    for (final expense in expenses) {
      final sourceId = _requiredString(expense, 'id');
      final targetId = expenseMaps[sourceId];
      if (targetId == null) {
        throw StateError('No expense mapping for "$sourceId".');
      }

      final choice = options.expenseResolutions[sourceId];
      final exists = await _expenseExists(db, targetId);

      if (exists) {
        if (choice == ConflictResolution.keepExisting) {
          state.skippedItems++;
          continue;
        } else if (choice == ConflictResolution.useBackup) {
          await _updateExpenseInDb(db, targetId, expense, categoryMaps, state, zipExtractDir);
          continue;
        } else if (choice == ConflictResolution.mergeFields) {
          await _mergeExpenseInDb(db, targetId, expense, categoryMaps, state, zipExtractDir);
          continue;
        } else {
          throw StateError('Target expense "$targetId" already exists but no conflict resolution was provided.');
        }
      }

      final sourceCategoryId = _requiredString(expense, 'category_id');
      final targetCategoryId = categoryMaps[sourceCategoryId] ??
          (await _categoryExists(db, sourceCategoryId)
              ? sourceCategoryId
              : null);
      if (targetCategoryId == null) {
        throw StateError(
          'Expense "$sourceId" references unresolved category '
          '"$sourceCategoryId".',
        );
      }

      var receiptUri = _nullableString(expense['receipt_image_uri']);
      if (receiptUri != null && zipExtractDir != null) {
        final fileName = p.basename(Uri.parse(receiptUri).path);
        final srcFile = io.File(p.join(zipExtractDir.path, 'receipts', fileName));
        if (srcFile.existsSync()) {
          try {
            final docDir = await getApplicationDocumentsDirectory();
            final localReceiptsDir = io.Directory(p.join(docDir.path, 'receipts'));
            if (!localReceiptsDir.existsSync()) {
              localReceiptsDir.createSync(recursive: true);
            }
            final newFileName = '${const Uuid().v4()}${p.extension(fileName)}';
            final destFile = io.File(p.join(localReceiptsDir.path, newFileName));
            srcFile.copySync(destFile.path);
            receiptUri = destFile.uri.toString();
          } catch (e) {
            state.warnings.add('Failed to copy physical receipt file: $e');
          }
        } else {
          state.warnings.add('Physical receipt file not found in backup: $fileName');
        }
      } else if (receiptUri != null) {
        state.warnings.add(
          'Receipt path for expense "$sourceId" was restored as text only.',
        );
      }

      await db.into(db.expenses).insert(
            local.ExpensesCompanion.insert(
              id: targetId,
              amount: _requiredDouble(expense, 'amount'),
              currency: _requiredString(expense, 'currency'),
              categoryId: targetCategoryId,
              title: _requiredString(expense, 'title'),
              vendor: Value(_nullableString(expense['vendor'])),
              date: _requiredString(expense, 'date'),
              notes: Value(_nullableString(expense['notes'])),
              receiptImageUri: Value(receiptUri),
              isRecurring: Value(_boolValue(expense['is_recurring'])),
              recurrenceFrequency:
                  Value(_nullableString(expense['recurrence_frequency'])),
              createdAt: _requiredString(expense, 'created_at'),
              updatedAt: _requiredString(expense, 'updated_at'),
              deletedAt: Value(_nullableString(expense['deleted_at'])),
            ),
          );
      state.insertedExpenseIds.add(targetId);
      if (receiptUri != null) {
        await db.into(db.receipts).insert(
              local.ReceiptsCompanion.insert(
                id: 'legacy_receipt_$targetId',
                expenseId: targetId,
                uri: receiptUri,
                mimeType: const Value('image/jpeg'),
                createdAt: _requiredString(expense, 'created_at'),
                deletedAt: Value(_nullableString(expense['deleted_at'])),
              ),
            );
      }
      inserted++;
    }
    return inserted;
  }

  Future<void> _updateExpenseInDb(
    local.WalletMeltDatabase db,
    String targetId,
    Map<String, Object?> expense,
    Map<String, String> categoryMaps,
    _RestoreMutationState state,
    io.Directory? zipExtractDir,
  ) async {
    final sourceCategoryId = _requiredString(expense, 'category_id');
    final targetCategoryId = categoryMaps[sourceCategoryId] ?? sourceCategoryId;

    var receiptUri = _nullableString(expense['receipt_image_uri']);
    if (receiptUri != null && zipExtractDir != null) {
      final fileName = p.basename(Uri.parse(receiptUri).path);
      final srcFile = io.File(p.join(zipExtractDir.path, 'receipts', fileName));
      if (srcFile.existsSync()) {
        try {
          final docDir = await getApplicationDocumentsDirectory();
          final localReceiptsDir = io.Directory(p.join(docDir.path, 'receipts'));
          if (!localReceiptsDir.existsSync()) {
            localReceiptsDir.createSync(recursive: true);
          }
          final newFileName = '${const Uuid().v4()}${p.extension(fileName)}';
          final destFile = io.File(p.join(localReceiptsDir.path, newFileName));
          srcFile.copySync(destFile.path);
          receiptUri = destFile.uri.toString();
        } catch (_) {}
      }
    }

    await (db.update(db.expenses)..where((row) => row.id.equals(targetId)))
        .write(
      local.ExpensesCompanion(
        amount: Value(_requiredDouble(expense, 'amount')),
        currency: Value(_requiredString(expense, 'currency')),
        categoryId: Value(targetCategoryId),
        title: Value(_requiredString(expense, 'title')),
        vendor: Value(_nullableString(expense['vendor'])),
        date: Value(_requiredString(expense, 'date')),
        notes: Value(_nullableString(expense['notes'])),
        receiptImageUri: Value(receiptUri),
        isRecurring: Value(_boolValue(expense['is_recurring'])),
        recurrenceFrequency: Value(_nullableString(expense['recurrence_frequency'])),
        updatedAt: Value(DateTime.now().toIso8601String()),
        deletedAt: Value(_nullableString(expense['deleted_at'])),
      ),
    );

    if (receiptUri != null) {
      await db.into(db.receipts).insertOnConflictUpdate(
            local.ReceiptsCompanion.insert(
              id: 'legacy_receipt_$targetId',
              expenseId: targetId,
              uri: receiptUri,
              mimeType: const Value('image/jpeg'),
              createdAt: _requiredString(expense, 'created_at'),
              deletedAt: Value(_nullableString(expense['deleted_at'])),
            ),
          );
    }
  }

  Future<void> _mergeExpenseInDb(
    local.WalletMeltDatabase db,
    String targetId,
    Map<String, Object?> expense,
    Map<String, String> categoryMaps,
    _RestoreMutationState state,
    io.Directory? zipExtractDir,
  ) async {
    final existing = await (db.select(db.expenses)
          ..where((row) => row.id.equals(targetId)))
        .getSingleOrNull();
    if (existing == null) return;

    final sourceCategoryId = _requiredString(expense, 'category_id');
    final targetCategoryId = categoryMaps[sourceCategoryId] ?? sourceCategoryId;

    var receiptUri = _nullableString(expense['receipt_image_uri']) ?? existing.receiptImageUri;
    if (receiptUri != existing.receiptImageUri && zipExtractDir != null && receiptUri != null) {
      final fileName = p.basename(Uri.parse(receiptUri).path);
      final srcFile = io.File(p.join(zipExtractDir.path, 'receipts', fileName));
      if (srcFile.existsSync()) {
        try {
          final docDir = await getApplicationDocumentsDirectory();
          final localReceiptsDir = io.Directory(p.join(docDir.path, 'receipts'));
          if (!localReceiptsDir.existsSync()) {
            localReceiptsDir.createSync(recursive: true);
          }
          final newFileName = '${const Uuid().v4()}${p.extension(fileName)}';
          final destFile = io.File(p.join(localReceiptsDir.path, newFileName));
          srcFile.copySync(destFile.path);
          receiptUri = destFile.uri.toString();
        } catch (_) {}
      }
    }

    await (db.update(db.expenses)..where((row) => row.id.equals(targetId)))
        .write(
      local.ExpensesCompanion(
        amount: Value(_requiredDouble(expense, 'amount')),
        currency: Value(_requiredString(expense, 'currency')),
        categoryId: Value(targetCategoryId),
        title: Value(_requiredString(expense, 'title')),
        vendor: Value(_nullableString(expense['vendor']) ?? existing.vendor),
        date: Value(_requiredString(expense, 'date')),
        notes: Value(_nullableString(expense['notes']) ?? existing.notes),
        receiptImageUri: Value(receiptUri),
        isRecurring: Value(_boolValue(expense['is_recurring'])),
        recurrenceFrequency: Value(_nullableString(expense['recurrence_frequency']) ?? existing.recurrenceFrequency),
        updatedAt: Value(DateTime.now().toIso8601String()),
        deletedAt: Value(_nullableString(expense['deleted_at']) ?? existing.deletedAt),
      ),
    );

    if (receiptUri != null) {
      await db.into(db.receipts).insertOnConflictUpdate(
            local.ReceiptsCompanion.insert(
              id: 'legacy_receipt_$targetId',
              expenseId: targetId,
              uri: receiptUri,
              mimeType: const Value('image/jpeg'),
              createdAt: _requiredString(expense, 'created_at'),
              deletedAt: Value(_nullableString(expense['deleted_at'])),
            ),
          );
    }
  }

  Future<int> _mergeGroceryItems(
    local.WalletMeltDatabase db,
    List<Map<String, Object?>> groceryItems,
    Map<String, String> expenseMaps,
    Map<String, String> groceryItemMaps,
    _RestoreMutationState state,
  ) async {
    var inserted = 0;
    for (final item in groceryItems) {
      final sourceId = _requiredString(item, 'id');
      final targetId = groceryItemMaps[sourceId];
      if (targetId == null) {
        throw StateError('No grocery item mapping for "$sourceId".');
      }
      if (await _groceryItemExists(db, targetId)) {
        throw StateError('Target grocery item "$targetId" already exists.');
      }

      final sourceExpenseId = _requiredString(item, 'expense_id');
      final targetExpenseId = expenseMaps[sourceExpenseId] ??
          (await _expenseExists(db, sourceExpenseId) ? sourceExpenseId : null);
      if (targetExpenseId == null) {
        throw StateError(
          'Grocery item "$sourceId" references unresolved expense '
          '"$sourceExpenseId".',
        );
      }

      final parent = await (db.select(db.expenses)
            ..where((row) => row.id.equals(targetExpenseId)))
          .getSingleOrNull();
      if (parent == null) {
        throw StateError(
          'Grocery item "$sourceId" parent expense "$targetExpenseId" '
          'does not exist.',
        );
      }

      final name = _requiredString(item, 'name');
      final amount = _requiredDouble(item, 'amount');
      final createdAt = _requiredString(item, 'created_at');

      await db.into(db.groceryItems).insert(
            local.GroceryItemsCompanion.insert(
              id: targetId,
              expenseId: targetExpenseId,
              name: name,
              amount: amount,
              createdAt: createdAt,
            ),
          );
      state.insertedGroceryItemIds.add(targetId);
      await db.into(db.expenseItems).insert(
            local.ExpenseItemsCompanion.insert(
              id: targetId,
              expenseId: targetExpenseId,
              itemId: const Value(null),
              nameSnapshot: name,
              totalPrice: amount,
              currency: parent.currency,
              categoryId: Value(parent.categoryId),
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
      inserted++;
    }
    return inserted;
  }

  Future<_BudgetMergeResult> _mergeBudgets(
    local.WalletMeltDatabase db,
    List<Map<String, Object?>> budgets,
    Map<String, String> categoryMaps,
    Map<String, String> budgetMaps, {
    required _RestoreMutationState state,
    required bool skipConflicts,
  }) async {
    var inserted = 0;
    var skipped = 0;
    final warnings = <String>[];

    for (final budget in budgets) {
      final sourceId = _requiredString(budget, 'id');
      final targetId = budgetMaps[sourceId];
      if (targetId == null) {
        throw StateError('No budget mapping for "$sourceId".');
      }
      if (await _budgetExists(db, targetId)) {
        throw StateError('Target budget "$targetId" already exists.');
      }

      final sourceCategoryId = _requiredString(budget, 'category_id');
      final targetCategoryId = categoryMaps[sourceCategoryId] ??
          (await _categoryExists(db, sourceCategoryId)
              ? sourceCategoryId
              : null);
      if (targetCategoryId == null) {
        throw StateError(
          'Budget "$sourceId" references unresolved category '
          '"$sourceCategoryId".',
        );
      }

      final month = _requiredString(budget, 'month');
      if (await _budgetPairExists(db, month, targetCategoryId)) {
        if (skipConflicts) {
          skipped++;
          warnings.add(
            'Skipped budget "$sourceId" because a local budget already exists '
            'for $month and $targetCategoryId.',
          );
          continue;
        }
        throw StateError(
          'Budget "$sourceId" collides with existing month + category.',
        );
      }

      await db.into(db.categoryBudgets).insert(
            local.CategoryBudgetsCompanion.insert(
              id: targetId,
              categoryId: targetCategoryId,
              amount: _requiredDouble(budget, 'amount'),
              currency: _requiredString(budget, 'currency'),
              month: month,
              createdAt: _requiredString(budget, 'created_at'),
              updatedAt: _requiredString(budget, 'updated_at'),
            ),
          );
      state.insertedBudgetIds.add(targetId);
      inserted++;
    }
    return _BudgetMergeResult(
      inserted: inserted,
      skipped: skipped,
      warnings: warnings,
    );
  }

  Future<bool> _importSettings(Object? settingsJson) async {
    if (settingsJson is! Map) return false;
    final settings = _settingsFromJson(settingsJson.cast<String, Object?>());
    final settingsService = _settingsService ?? SettingsService();
    await settingsService.save(settings);
    return true;
  }

  WalletMeltSettings _settingsFromJson(Map<String, Object?> json) {
    final themeName = _nullableString(json['theme_preference']);
    final theme = ThemePreference.values.firstWhere(
      (value) => value.name == themeName,
      orElse: () => ThemePreference.system,
    );
    final monthlyBudgetVal = json['monthly_budget_amount'];
    double? monthlyBudget;
    if (monthlyBudgetVal is num) {
      monthlyBudget = monthlyBudgetVal.toDouble();
    }
    return WalletMeltSettings(
      currency: _nullableString(json['currency']) ??
          WalletMeltSettings.defaults.currency,
      themePreference: theme,
      hasCompletedOnboarding: json['has_completed_onboarding'] == true ||
          json['has_completed_onboarding'] == 1,
      lastExportedAt: _nullableString(json['last_exported_at']),
      monthlyBudgetAmount: monthlyBudget,
      budgetPeriodStartDay: json['budget_period_start_day'] is num
          ? (json['budget_period_start_day'] as num).toInt().clamp(1, 28)
          : 1,
    );
  }

  void _verifyCounts(
    RestoreDryRunPlan dryRunPlan,
    _RestoreMutationState state,
  ) {
    if (state.insertedCategories != dryRunPlan.plannedCounts.categories) {
      throw StateError('Inserted category count does not match dry-run plan.');
    }
    if (state.insertedExpenses != dryRunPlan.plannedCounts.expenses) {
      throw StateError('Inserted expense count does not match dry-run plan.');
    }
    if (state.insertedGroceryItems != dryRunPlan.plannedCounts.groceryItems) {
      throw StateError(
        'Inserted grocery item count does not match dry-run plan.',
      );
    }
    if (state.insertedBudgets + state.skippedItems !=
        dryRunPlan.plannedCounts.budgets) {
      throw StateError('Budget count does not match dry-run plan.');
    }
  }

  Future<void> _verifyInsertedRelationships(
    local.WalletMeltDatabase db,
    _RestoreMutationState state,
  ) async {
    for (final expenseId in state.insertedExpenseIds) {
      final expense = await (db.select(db.expenses)
            ..where((row) => row.id.equals(expenseId)))
          .getSingleOrNull();
      if (expense == null || !await _categoryExists(db, expense.categoryId)) {
        throw StateError(
          'Restored expense "$expenseId" has an unresolved category.',
        );
      }
    }

    for (final itemId in state.insertedGroceryItemIds) {
      final item = await (db.select(db.groceryItems)
            ..where((row) => row.id.equals(itemId)))
          .getSingleOrNull();
      if (item == null || !await _expenseExists(db, item.expenseId)) {
        throw StateError(
          'Restored grocery item "$itemId" has an unresolved expense.',
        );
      }
    }

    for (final budgetId in state.insertedBudgetIds) {
      final budget = await (db.select(db.categoryBudgets)
            ..where((row) => row.id.equals(budgetId)))
          .getSingleOrNull();
      if (budget == null || !await _categoryExists(db, budget.categoryId)) {
        throw StateError(
          'Restored budget "$budgetId" has an unresolved category.',
        );
      }
    }
  }

  Map<String, String> _mappingsFor(
    RestoreDryRunPlan plan,
    RestoreDryRunEntity entity,
  ) {
    return {
      for (final mapping in plan.idMappings)
        if (mapping.entity == entity) mapping.sourceId: mapping.targetId,
    };
  }

  bool _dryRunGateSatisfied(
    RestoreDryRunPlan plan,
    RestoreDryRunSafetyGate gate,
  ) {
    for (final status in plan.safetyGates) {
      if (status.gate == gate) return status.satisfied;
    }
    return false;
  }

  List<String> _backupPreflightIssues(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      return const ['Backup root is not a JSON object.'];
    }
    final backup = decoded.cast<String, Object?>();
    return [
      ..._duplicateIdIssues('category', _asMaps(backup['categories'])),
      ..._duplicateIdIssues('expense', _asMaps(backup['expenses'])),
      ..._duplicateIdIssues('grocery item', _asMaps(backup['grocery_items'])),
      ..._duplicateIdIssues('budget', _asMaps(backup['budgets'])),
      ..._duplicateCategoryNameIssues(_asMaps(backup['categories'])),
      ..._duplicateBudgetPairIssues(_asMaps(backup['budgets'])),
    ];
  }

  List<String> _duplicateIdIssues(
    String entity,
    List<Map<String, Object?>> rows,
  ) {
    final seen = <String>{};
    final reported = <String>{};
    final issues = <String>[];
    for (final row in rows) {
      final id = _nullableString(row['id']);
      if (id == null) continue;
      if (!seen.add(id) && reported.add(id)) {
        issues.add('Duplicate $entity ID "$id".');
      }
    }
    return issues;
  }

  List<String> _duplicateCategoryNameIssues(
    List<Map<String, Object?>> categories,
  ) {
    final seen = <String>{};
    final reported = <String>{};
    final issues = <String>[];
    for (final category in categories) {
      final name = _nullableString(category['name']);
      if (name == null) continue;
      final normalized = name.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized) && reported.add(normalized)) {
        issues.add('Duplicate category name "$name".');
      }
    }
    return issues;
  }

  List<String> _duplicateBudgetPairIssues(
    List<Map<String, Object?>> budgets,
  ) {
    final seen = <String>{};
    final reported = <String>{};
    final issues = <String>[];
    for (final budget in budgets) {
      final month = _nullableString(budget['month']);
      final categoryId = _nullableString(budget['category_id']);
      if (month == null || categoryId == null) continue;
      final key = '$month|$categoryId';
      if (!seen.add(key) && reported.add(key)) {
        issues.add(
          'Duplicate budget month/category pair "$month" / "$categoryId".',
        );
      }
    }
    return issues;
  }

  Future<bool> _categoryExists(local.WalletMeltDatabase db, String id) async {
    final row = await (db.select(db.categories)
          ..where((category) => category.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<bool> _expenseExists(local.WalletMeltDatabase db, String id) async {
    final row = await (db.select(db.expenses)
          ..where((expense) => expense.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<bool> _groceryItemExists(
    local.WalletMeltDatabase db,
    String id,
  ) async {
    final row = await (db.select(db.groceryItems)
          ..where((item) => item.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<bool> _budgetExists(local.WalletMeltDatabase db, String id) async {
    final row = await (db.select(db.categoryBudgets)
          ..where((budget) => budget.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<bool> _budgetPairExists(
    local.WalletMeltDatabase db,
    String month,
    String categoryId,
  ) async {
    final row = await (db.select(db.categoryBudgets)
          ..where((budget) =>
              budget.month.equals(month) &
              budget.categoryId.equals(categoryId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> _onStep(RestoreExecutionStep step) async {
    final hook = debugOnStep;
    if (hook != null) {
      await hook(step);
    }
  }

  /// Deletes every restorable table, children before parents.
  Future<void> _deleteAllUserData(local.WalletMeltDatabase db) async {
    for (final table in const [
      'expense_items',
      'receipts',
      'fuel_components',
      'fuel_transactions',
      'grocery_items',
      'account_movements',
      'incomes',
      'income_schedules',
      'expenses',
      'fuel_template_components',
      'essential_expense_templates',
      'subscriptions',
      'debt_repayments',
      'debt_records',
      'accounts',
      'payees',
      'grocery_templates',
      'category_budgets',
      'monthly_budgets',
      'sync_metadata',
      'item_aliases',
      'items',
      'stores',
      'categories',
      'units',
    ]) {
      await db.customStatement('DELETE FROM $table;');
    }
  }

  Future<int> _foreignKeyViolationCount(local.WalletMeltDatabase db) async {
    final rows = await db.customSelect('PRAGMA foreign_key_check;').get();
    return rows.length;
  }

  Future<void> _requireNoForeignKeyViolations(
    local.WalletMeltDatabase db, {
    required int baseline,
  }) async {
    final count = await _foreignKeyViolationCount(db);
    if (count > baseline) {
      throw StateError(
        'Restore would leave $count foreign key violation(s); rolled back.',
      );
    }
  }

  Future<int> _mergeMonthlyBudgets(
    local.WalletMeltDatabase db,
    List<Map<String, Object?>> rows,
  ) async {
    var inserted = 0;
    for (final row in rows) {
      final month = _requiredString(row, 'month');
      final existing = await db.customSelect(
        'SELECT 1 AS x FROM monthly_budgets WHERE month = ? LIMIT 1;',
        variables: [Variable(month)],
      ).get();
      if (existing.isNotEmpty) continue;
      await db.into(db.monthlyBudgets).insert(
            local.MonthlyBudgetsCompanion.insert(
              id: _requiredString(row, 'id'),
              month: month,
              amount: _requiredDouble(row, 'amount'),
              currency: _requiredString(row, 'currency'),
              createdAt: _requiredString(row, 'created_at'),
              updatedAt: _requiredString(row, 'updated_at'),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      inserted++;
    }
    return inserted;
  }

  List<Map<String, Object?>> _asMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => entry.cast<String, Object?>())
        .toList();
  }

  String _requiredString(Map<String, Object?> map, String key) {
    final value = _nullableString(map[key]);
    if (value == null) {
      throw StateError('Missing required string "$key".');
    }
    return value;
  }

  String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  double _requiredDouble(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is num) return value.toDouble();
    throw StateError('Missing required number "$key".');
  }

  bool _boolValue(Object? value) => value == true || value == 1;
}

class _RestoreMutationState {
  Map<String, int> extendedCounts = const {};
  _RestoreMutationState({required this.safetyBackupPath});

  final String safetyBackupPath;
  int insertedCategories = 0;
  int insertedExpenses = 0;
  int insertedGroceryItems = 0;
  int insertedBudgets = 0;
  int skippedItems = 0;
  bool settingsImported = false;
  final List<String> insertedExpenseIds = [];
  final List<String> insertedGroceryItemIds = [];
  final List<String> insertedBudgetIds = [];
  final List<String> warnings = [];
}

class _BudgetMergeResult {
  const _BudgetMergeResult({
    required this.inserted,
    required this.skipped,
    required this.warnings,
  });

  final int inserted;
  final int skipped;
  final List<String> warnings;
}
