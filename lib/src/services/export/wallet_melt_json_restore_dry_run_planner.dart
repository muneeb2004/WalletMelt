import 'dart:convert';

import '../../types/category.dart';
import '../../types/settings.dart';
import 'wallet_melt_json_backup_conflict_service.dart';
import 'wallet_melt_json_backup_encoder.dart';
import 'wallet_melt_json_backup_validator.dart';
import 'wallet_melt_json_restore_plan.dart';

enum RestoreDryRunEntity {
  category,
  expense,
  groceryItem,
  budget,
  settings,
  receiptReference,
}

enum RestoreDryRunActionType {
  insert,
  mapToExisting,
  insertWithNewId,
  skipRequiresChoice,
  warnOnly,
}

enum RestoreDryRunIssueSeverity {
  warning,
  blocker,
}

enum RestoreDryRunSafetyGate {
  backupFormatSupported,
  formatVersionSupported,
  previewGenerated,
  conflictSummaryReviewed,
  explicitConfirmationRequiredLater,
  preRestoreBackupRequiredLater,
  transactionRuntimeRequiredLater,
  noUnresolvedBlockers,
}

class RestoreDryRunEntityCounts {
  const RestoreDryRunEntityCounts({
    this.categories = 0,
    this.expenses = 0,
    this.groceryItems = 0,
    this.budgets = 0,
    this.settings = 0,
  });

  final int categories;
  final int expenses;
  final int groceryItems;
  final int budgets;
  final int settings;
}

class RestoreDryRunIdMapping {
  const RestoreDryRunIdMapping({
    required this.entity,
    required this.sourceId,
    required this.targetId,
    required this.reason,
    required this.preservesSourceId,
  });

  final RestoreDryRunEntity entity;
  final String sourceId;
  final String targetId;
  final String reason;
  final bool preservesSourceId;
}

class RestoreDryRunIssue {
  const RestoreDryRunIssue({
    required this.severity,
    required this.message,
    this.entity,
    this.sourceId,
  });

  final RestoreDryRunIssueSeverity severity;
  final String message;
  final RestoreDryRunEntity? entity;
  final String? sourceId;

  bool get isBlocker => severity == RestoreDryRunIssueSeverity.blocker;
}

class RestoreDryRunAction {
  const RestoreDryRunAction({
    required this.entity,
    required this.type,
    required this.description,
    this.sourceId,
    this.plannedId,
  });

  final RestoreDryRunEntity entity;
  final RestoreDryRunActionType type;
  final String description;
  final String? sourceId;
  final String? plannedId;
}

class RestoreDryRunSafetyGateStatus {
  const RestoreDryRunSafetyGateStatus({
    required this.gate,
    required this.label,
    required this.satisfied,
  });

  final RestoreDryRunSafetyGate gate;
  final String label;
  final bool satisfied;
}

class RestoreDryRunPlan {
  const RestoreDryRunPlan({
    required this.isValid,
    required this.backupCounts,
    required this.plannedCounts,
    required this.actions,
    required this.idMappings,
    required this.issues,
    required this.safetyGates,
    required this.futureExecutionSteps,
    required this.restorePlan,
    this.error,
  });

  factory RestoreDryRunPlan.invalid(String error) {
    return RestoreDryRunPlan(
      isValid: false,
      error: error,
      backupCounts: const RestoreDryRunEntityCounts(),
      plannedCounts: const RestoreDryRunEntityCounts(),
      actions: const [],
      idMappings: const [],
      issues: [
        RestoreDryRunIssue(
          severity: RestoreDryRunIssueSeverity.blocker,
          message: error,
        ),
      ],
      safetyGates: const [],
      futureExecutionSteps: RestorePlan.mutationPlanningSteps,
      restorePlan: RestorePlan.safeMerge(
        issues: [
          RestorePlanIssue(
            severity: RestorePlanIssueSeverity.blocker,
            message: error,
          ),
        ],
      ),
    );
  }

  final bool isValid;
  final String? error;
  final RestoreDryRunEntityCounts backupCounts;
  final RestoreDryRunEntityCounts plannedCounts;
  final List<RestoreDryRunAction> actions;
  final List<RestoreDryRunIdMapping> idMappings;
  final List<RestoreDryRunIssue> issues;
  final List<RestoreDryRunSafetyGateStatus> safetyGates;
  final List<RestoreExecutionStep> futureExecutionSteps;
  final RestorePlan restorePlan;

  int get blockerCount => issues.where((issue) => issue.isBlocker).length;

  int get warningCount => issues.where((issue) => !issue.isBlocker).length;

  bool get hasBlockers => blockerCount > 0;

  List<RestoreDryRunSafetyGateStatus> get unsatisfiedSafetyGates =>
      safetyGates.where((gate) => !gate.satisfied).toList();

  bool get canStartFutureMutation =>
      isValid &&
      !hasBlockers &&
      safetyGates.every((gate) => gate.satisfied) &&
      restorePlan.canStartMutation;
}

class WalletMeltJsonRestoreDryRunPlanner {
  const WalletMeltJsonRestoreDryRunPlanner({
    WalletMeltJsonBackupValidator validator =
        const WalletMeltJsonBackupValidator(),
  }) : _validator = validator;

  final WalletMeltJsonBackupValidator _validator;

  RestoreDryRunPlan plan({
    required String jsonText,
    required LocalAppSnapshot localSnapshot,
    BackupConflictSummary? conflictSummary,
    bool previewGenerated = true,
    bool settingsImportSelected = false,
  }) {
    final validation = _validator.validate(jsonText);
    if (!validation.isValid) {
      return RestoreDryRunPlan.invalid(
        validation.error ?? 'Backup validation failed.',
      );
    }

    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      return RestoreDryRunPlan.invalid('Backup root is not a JSON object.');
    }

    final backup = decoded.cast<String, Object?>();
    final metadata = (backup['metadata'] as Map).cast<String, Object?>();
    final categories = _asMaps(backup['categories']);
    final expenses = _asMaps(backup['expenses']);
    final groceryItems = _asMaps(backup['grocery_items']);
    final budgets = _asMaps(backup['budgets']);
    final settings = backup['settings'];

    final builder = _DryRunBuilder(
      localSnapshot: localSnapshot,
      settingsImportSelected: settingsImportSelected,
    );

    builder.detectBackupDuplicates(
      categories: categories,
      expenses: expenses,
      groceryItems: groceryItems,
      budgets: budgets,
    );
    builder.planCategories(categories);
    builder.planExpenses(expenses);
    builder.planGroceryItems(groceryItems);
    builder.planBudgets(budgets);
    builder.planSettings(settings);

    final formatSupported =
        metadata['format'] == WalletMeltJsonBackupEncoder.format;
    final versionSupported =
        metadata['format_version'] == WalletMeltJsonBackupEncoder.formatVersion;

    final issues = builder.issues;
    final completedSafetyChecks = <RestoreSafetyCheck>{
      RestoreSafetyCheck.formatValidated,
      if (previewGenerated) RestoreSafetyCheck.previewGenerated,
      if (conflictSummary != null)
        RestoreSafetyCheck.conflictDetectionCompleted,
    };
    final restorePlan = RestorePlan.safeMerge(
      entitySelection: RestoreEntitySelection.backupData.copyWith(
        settings: settingsImportSelected,
      ),
      completedSafetyChecks: completedSafetyChecks,
      issues: [
        for (final issue in issues)
          RestorePlanIssue(
            severity: issue.isBlocker
                ? RestorePlanIssueSeverity.blocker
                : RestorePlanIssueSeverity.warning,
            message: issue.message,
          ),
      ],
    );

    return RestoreDryRunPlan(
      isValid: true,
      backupCounts: RestoreDryRunEntityCounts(
        categories: categories.length,
        expenses: expenses.length,
        groceryItems: groceryItems.length,
        budgets: budgets.length,
        settings: settings is Map ? 1 : 0,
      ),
      plannedCounts: RestoreDryRunEntityCounts(
        categories: builder.plannedCategoryCount,
        expenses: builder.plannedExpenseCount,
        groceryItems: builder.plannedGroceryItemCount,
        budgets: builder.plannedBudgetCount,
        settings: builder.plannedSettingsCount,
      ),
      actions: builder.actions,
      idMappings: builder.idMappings,
      issues: issues,
      safetyGates: [
        RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.backupFormatSupported,
          label: 'Backup format supported',
          satisfied: formatSupported,
        ),
        RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.formatVersionSupported,
          label: 'Format version supported',
          satisfied: versionSupported,
        ),
        RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.previewGenerated,
          label: 'Preview generated',
          satisfied: previewGenerated,
        ),
        RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.conflictSummaryReviewed,
          label: 'Conflict summary reviewed',
          satisfied: conflictSummary != null,
        ),
        const RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.explicitConfirmationRequiredLater,
          label: 'Explicit confirmation still required later',
          satisfied: false,
        ),
        const RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.preRestoreBackupRequiredLater,
          label: 'Pre-restore backup still required later',
          satisfied: false,
        ),
        const RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.transactionRuntimeRequiredLater,
          label: 'Transaction runtime still required later',
          satisfied: false,
        ),
        RestoreDryRunSafetyGateStatus(
          gate: RestoreDryRunSafetyGate.noUnresolvedBlockers,
          label: 'No unresolved blockers',
          satisfied: issues.every((issue) => !issue.isBlocker),
        ),
      ],
      futureExecutionSteps: RestorePlan.mutationPlanningSteps,
      restorePlan: restorePlan,
    );
  }

  List<Map<String, Object?>> _asMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => entry.cast<String, Object?>())
        .toList();
  }
}

class _DryRunBuilder {
  _DryRunBuilder({
    required this.localSnapshot,
    required this.settingsImportSelected,
  });

  final LocalAppSnapshot localSnapshot;
  final bool settingsImportSelected;

  final List<RestoreDryRunAction> actions = [];
  final List<RestoreDryRunIdMapping> idMappings = [];
  final List<RestoreDryRunIssue> issues = [];

  final Map<String, String> _categoryIdMap = {};
  final Map<String, String> _expenseIdMap = {};

  int plannedCategoryCount = 0;
  int plannedExpenseCount = 0;
  int plannedGroceryItemCount = 0;
  int plannedBudgetCount = 0;
  int plannedSettingsCount = 0;

  void detectBackupDuplicates({
    required List<Map<String, Object?>> categories,
    required List<Map<String, Object?>> expenses,
    required List<Map<String, Object?>> groceryItems,
    required List<Map<String, Object?>> budgets,
  }) {
    _detectDuplicateIds(RestoreDryRunEntity.category, categories);
    _detectDuplicateIds(RestoreDryRunEntity.expense, expenses);
    _detectDuplicateIds(RestoreDryRunEntity.groceryItem, groceryItems);
    _detectDuplicateIds(RestoreDryRunEntity.budget, budgets);
    _detectDuplicateCategoryNames(categories);
    _detectDuplicateBudgetPairs(budgets);
  }

  void planCategories(List<Map<String, Object?>> categories) {
    final localById = {
      for (final category in localSnapshot.categories) category.id: category
    };
    final localByName = {
      for (final category in localSnapshot.categories)
        _normalize(category.name): category,
    };
    final usedIds = <String>{...localById.keys};

    for (final category in categories) {
      final id = _stringValue(category['id']);
      final name = _stringValue(category['name']);
      if (id == null || name == null) {
        _addBlocker(
          RestoreDryRunEntity.category,
          id,
          'Category is missing required id or name.',
        );
        continue;
      }

      final localWithSameId = localById[id];
      if (localWithSameId != null) {
        if (_categoryEquivalent(localWithSameId, category)) {
          _mapId(
            RestoreDryRunEntity.category,
            id,
            localWithSameId.id,
            'Matching local category exists.',
            true,
          );
          actions.add(RestoreDryRunAction(
            entity: RestoreDryRunEntity.category,
            type: RestoreDryRunActionType.mapToExisting,
            sourceId: id,
            plannedId: localWithSameId.id,
            description: 'Map category "$name" to existing local category.',
          ));
        } else {
          final newId = _proposedId('category', id, usedIds);
          usedIds.add(newId);
          _mapId(
            RestoreDryRunEntity.category,
            id,
            newId,
            'Category ID conflicts with different local category.',
            false,
          );
          _addWarning(
            RestoreDryRunEntity.category,
            id,
            'Category "$name" has an ID conflict and would need a new ID.',
          );
          actions.add(RestoreDryRunAction(
            entity: RestoreDryRunEntity.category,
            type: RestoreDryRunActionType.insertWithNewId,
            sourceId: id,
            plannedId: newId,
            description: 'Insert category "$name" with a proposed new ID.',
          ));
          plannedCategoryCount++;
        }
        continue;
      }

      final localWithSameName = localByName[_normalize(name)];
      if (localWithSameName != null) {
        final backupIsDefault = category['is_default'] == true;
        if (backupIsDefault && localWithSameName.isDefault) {
          _mapId(
            RestoreDryRunEntity.category,
            id,
            localWithSameName.id,
            'Default-like category name matches local category.',
            false,
          );
          _addWarning(
            RestoreDryRunEntity.category,
            id,
            'Default category "$name" would map to existing local category.',
          );
          actions.add(RestoreDryRunAction(
            entity: RestoreDryRunEntity.category,
            type: RestoreDryRunActionType.mapToExisting,
            sourceId: id,
            plannedId: localWithSameName.id,
            description: 'Map default-like category "$name" by name.',
          ));
        } else {
          _addBlocker(
            RestoreDryRunEntity.category,
            id,
            'Category "$name" matches a local name with a different ID and '
            'requires user choice before restore.',
          );
          actions.add(RestoreDryRunAction(
            entity: RestoreDryRunEntity.category,
            type: RestoreDryRunActionType.skipRequiresChoice,
            sourceId: id,
            description: 'Category "$name" requires conflict resolution.',
          ));
        }
        continue;
      }

      _mapId(
        RestoreDryRunEntity.category,
        id,
        id,
        'Category ID is available.',
        true,
      );
      usedIds.add(id);
      actions.add(RestoreDryRunAction(
        entity: RestoreDryRunEntity.category,
        type: RestoreDryRunActionType.insert,
        sourceId: id,
        plannedId: id,
        description: 'Insert category "$name".',
      ));
      plannedCategoryCount++;
    }
  }

  void planExpenses(List<Map<String, Object?>> expenses) {
    final localExpenseIds =
        localSnapshot.allExpenses.map((expense) => expense.id).toSet();
    final usedIds = <String>{...localExpenseIds};
    final localCategoryIds =
        localSnapshot.categories.map((category) => category.id).toSet();

    for (final expense in expenses) {
      final id = _stringValue(expense['id']);
      if (id == null) {
        _addBlocker(
          RestoreDryRunEntity.expense,
          null,
          'Expense is missing required id.',
        );
        continue;
      }

      final categoryId = _stringValue(expense['category_id']);
      final resolvedCategoryId = categoryId == null
          ? null
          : _categoryIdMap[categoryId] ??
              (localCategoryIds.contains(categoryId) ? categoryId : null);
      if (resolvedCategoryId == null) {
        _addBlocker(
          RestoreDryRunEntity.expense,
          id,
          'Expense "$id" references category "$categoryId" that cannot be resolved.',
        );
        continue;
      }

      final targetId = localExpenseIds.contains(id)
          ? _proposedId('expense', id, usedIds)
          : id;
      usedIds.add(targetId);
      _expenseIdMap[id] = targetId;
      _mapId(
        RestoreDryRunEntity.expense,
        id,
        targetId,
        targetId == id
            ? 'Expense ID is available.'
            : 'Expense ID conflicts with local expense.',
        targetId == id,
      );

      final hasReceipt = _stringValue(expense['receipt_image_uri']) != null;
      final isDeleted = expense['deleted_at'] != null;
      if (hasReceipt) {
        _addWarning(
          RestoreDryRunEntity.receiptReference,
          id,
          'Expense "$id" has a receipt URI/path reference only; the file is '
          'not packaged in JSON backup.',
        );
      }
      if (isDeleted) {
        _addWarning(
          RestoreDryRunEntity.expense,
          id,
          'Expense "$id" is soft-deleted and would remain soft-deleted in a '
          'future import.',
        );
      }

      actions.add(RestoreDryRunAction(
        entity: RestoreDryRunEntity.expense,
        type: targetId == id
            ? RestoreDryRunActionType.insert
            : RestoreDryRunActionType.insertWithNewId,
        sourceId: id,
        plannedId: targetId,
        description: targetId == id
            ? 'Insert expense "$id" with category "$resolvedCategoryId".'
            : 'Insert expense "$id" with proposed ID "$targetId".',
      ));
      plannedExpenseCount++;
    }
  }

  void planGroceryItems(List<Map<String, Object?>> groceryItems) {
    final localGroceryIds =
        localSnapshot.groceryItems.map((item) => item.id).toSet();
    final localExpenseIds =
        localSnapshot.allExpenses.map((expense) => expense.id).toSet();
    final usedIds = <String>{...localGroceryIds};

    for (final item in groceryItems) {
      final id = _stringValue(item['id']);
      final expenseId = _stringValue(item['expense_id']);
      if (id == null || expenseId == null) {
        _addBlocker(
          RestoreDryRunEntity.groceryItem,
          id,
          'Grocery item is missing required id or expense_id.',
        );
        continue;
      }

      final resolvedExpenseId = _expenseIdMap[expenseId] ??
          (localExpenseIds.contains(expenseId) ? expenseId : null);
      if (resolvedExpenseId == null) {
        _addBlocker(
          RestoreDryRunEntity.groceryItem,
          id,
          'Grocery item "$id" references expense "$expenseId" that cannot be resolved.',
        );
        continue;
      }

      final targetId = localGroceryIds.contains(id)
          ? _proposedId('grocery_item', id, usedIds)
          : id;
      usedIds.add(targetId);
      _mapId(
        RestoreDryRunEntity.groceryItem,
        id,
        targetId,
        targetId == id
            ? 'Grocery item ID is available.'
            : 'Grocery item ID conflicts with local item.',
        targetId == id,
      );
      actions.add(RestoreDryRunAction(
        entity: RestoreDryRunEntity.groceryItem,
        type: targetId == id
            ? RestoreDryRunActionType.insert
            : RestoreDryRunActionType.insertWithNewId,
        sourceId: id,
        plannedId: targetId,
        description:
            'Insert grocery item "$id" for resolved expense "$resolvedExpenseId".',
      ));
      plannedGroceryItemCount++;
    }
  }

  void planBudgets(List<Map<String, Object?>> budgets) {
    final localPairs = localSnapshot.budgets
        .map((budget) => _budgetPair(budget.month, budget.categoryId))
        .toSet();
    final localBudgetIds =
        localSnapshot.budgets.map((budget) => budget.id).toSet();
    final localCategoryIds =
        localSnapshot.categories.map((category) => category.id).toSet();
    final usedIds = <String>{...localBudgetIds};

    for (final budget in budgets) {
      final id = _stringValue(budget['id']);
      final month = _stringValue(budget['month']);
      final categoryId = _stringValue(budget['category_id']);
      if (id == null || month == null || categoryId == null) {
        _addBlocker(
          RestoreDryRunEntity.budget,
          id,
          'Budget is missing required id, month, or category_id.',
        );
        continue;
      }

      final resolvedCategoryId = _categoryIdMap[categoryId] ??
          (localCategoryIds.contains(categoryId) ? categoryId : null);
      if (resolvedCategoryId == null) {
        _addBlocker(
          RestoreDryRunEntity.budget,
          id,
          'Budget "$id" references category "$categoryId" that cannot be resolved.',
        );
        continue;
      }

      if (localPairs.contains(_budgetPair(month, resolvedCategoryId))) {
        _addBlocker(
          RestoreDryRunEntity.budget,
          id,
          'Budget "$id" collides with existing month + category '
          '("$month", "$resolvedCategoryId") and requires user choice.',
        );
        actions.add(RestoreDryRunAction(
          entity: RestoreDryRunEntity.budget,
          type: RestoreDryRunActionType.skipRequiresChoice,
          sourceId: id,
          description: 'Budget "$id" requires conflict resolution.',
        ));
        continue;
      }

      final targetId =
          localBudgetIds.contains(id) ? _proposedId('budget', id, usedIds) : id;
      usedIds.add(targetId);
      _mapId(
        RestoreDryRunEntity.budget,
        id,
        targetId,
        targetId == id ? 'Budget ID is available.' : 'Budget ID conflicts.',
        targetId == id,
      );
      actions.add(RestoreDryRunAction(
        entity: RestoreDryRunEntity.budget,
        type: targetId == id
            ? RestoreDryRunActionType.insert
            : RestoreDryRunActionType.insertWithNewId,
        sourceId: id,
        plannedId: targetId,
        description:
            'Insert budget "$id" for "$month" and category "$resolvedCategoryId".',
      ));
      plannedBudgetCount++;
    }
  }

  void planSettings(Object? settings) {
    if (settings is! Map) {
      return;
    }

    if (!settingsImportSelected) {
      _addWarning(
        RestoreDryRunEntity.settings,
        null,
        'Backup settings are present but settings import is not selected.',
      );
      actions.add(const RestoreDryRunAction(
        entity: RestoreDryRunEntity.settings,
        type: RestoreDryRunActionType.warnOnly,
        description: 'Leave local settings unchanged.',
      ));
      return;
    }

    plannedSettingsCount = 1;
    final current = localSnapshot.settings;
    if (current != null) {
      final differences = _settingsDifferences(settings, current);
      if (differences.isNotEmpty) {
        _addWarning(
          RestoreDryRunEntity.settings,
          null,
          'Settings import would change: ${differences.join(', ')}.',
        );
      }
    }
    actions.add(const RestoreDryRunAction(
      entity: RestoreDryRunEntity.settings,
      type: RestoreDryRunActionType.warnOnly,
      description: 'Settings import selected for a future restore.',
    ));
  }

  bool _categoryEquivalent(Category local, Map<String, Object?> backup) {
    return _normalize(local.name) == _normalize(_stringValue(backup['name'])) &&
        local.icon == _stringValue(backup['icon']) &&
        local.color == _stringValue(backup['color']) &&
        local.isDefault == (backup['is_default'] == true);
  }

  List<String> _settingsDifferences(
    Map<Object?, Object?> backup,
    WalletMeltSettings current,
  ) {
    final differences = <String>[];
    final currency = _stringValue(backup['currency']);
    final theme = _stringValue(backup['theme_preference']);
    final completedOnboarding = backup['has_completed_onboarding'];

    if (currency != null && currency != current.currency) {
      differences.add('currency');
    }
    if (theme != null && theme != current.themePreference.name) {
      differences.add('theme');
    }
    if (completedOnboarding is bool &&
        completedOnboarding != current.hasCompletedOnboarding) {
      differences.add('onboarding flag');
    }
    return differences;
  }

  void _mapId(
    RestoreDryRunEntity entity,
    String sourceId,
    String targetId,
    String reason,
    bool preservesSourceId,
  ) {
    if (entity == RestoreDryRunEntity.category) {
      _categoryIdMap[sourceId] = targetId;
    }
    idMappings.add(RestoreDryRunIdMapping(
      entity: entity,
      sourceId: sourceId,
      targetId: targetId,
      reason: reason,
      preservesSourceId: preservesSourceId,
    ));
  }

  void _addWarning(
    RestoreDryRunEntity? entity,
    String? sourceId,
    String message,
  ) {
    issues.add(RestoreDryRunIssue(
      severity: RestoreDryRunIssueSeverity.warning,
      entity: entity,
      sourceId: sourceId,
      message: message,
    ));
  }

  void _addBlocker(
    RestoreDryRunEntity? entity,
    String? sourceId,
    String message,
  ) {
    issues.add(RestoreDryRunIssue(
      severity: RestoreDryRunIssueSeverity.blocker,
      entity: entity,
      sourceId: sourceId,
      message: message,
    ));
  }

  void _detectDuplicateIds(
    RestoreDryRunEntity entity,
    List<Map<String, Object?>> rows,
  ) {
    final seen = <String>{};
    final reported = <String>{};
    for (final row in rows) {
      final id = _stringValue(row['id']);
      if (id == null) continue;
      if (!seen.add(id) && reported.add(id)) {
        _addBlocker(
          entity,
          id,
          '${_entityLabel(entity)} "$id" appears more than once in the backup.',
        );
      }
    }
  }

  void _detectDuplicateCategoryNames(List<Map<String, Object?>> categories) {
    final seen = <String>{};
    final reported = <String>{};
    for (final category in categories) {
      final name = _stringValue(category['name']);
      if (name == null) continue;
      final normalized = _normalize(name);
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized) && reported.add(normalized)) {
        _addBlocker(
          RestoreDryRunEntity.category,
          _stringValue(category['id']),
          'Category name "$name" appears more than once in the backup.',
        );
      }
    }
  }

  void _detectDuplicateBudgetPairs(List<Map<String, Object?>> budgets) {
    final seen = <String>{};
    final reported = <String>{};
    for (final budget in budgets) {
      final month = _stringValue(budget['month']);
      final categoryId = _stringValue(budget['category_id']);
      if (month == null || categoryId == null) continue;
      final pair = _budgetPair(month, categoryId);
      if (!seen.add(pair) && reported.add(pair)) {
        _addBlocker(
          RestoreDryRunEntity.budget,
          _stringValue(budget['id']),
          'Multiple backup budgets target month "$month" and category '
          '"$categoryId".',
        );
      }
    }
  }

  String _entityLabel(RestoreDryRunEntity entity) {
    return switch (entity) {
      RestoreDryRunEntity.category => 'Category',
      RestoreDryRunEntity.expense => 'Expense',
      RestoreDryRunEntity.groceryItem => 'Grocery item',
      RestoreDryRunEntity.budget => 'Budget',
      RestoreDryRunEntity.settings => 'Settings',
      RestoreDryRunEntity.receiptReference => 'Receipt reference',
    };
  }

  String _proposedId(String entity, String sourceId, Set<String> usedIds) {
    final normalized =
        sourceId.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').toLowerCase();
    var candidate = 'restore_${entity}_$normalized';
    var index = 2;
    while (usedIds.contains(candidate)) {
      candidate = 'restore_${entity}_${normalized}_$index';
      index++;
    }
    return candidate;
  }

  String _budgetPair(String month, String categoryId) => '$month|$categoryId';

  String _normalize(String? value) => (value ?? '').trim().toLowerCase();

  String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
