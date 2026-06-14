enum RestoreMode {
  previewOnly,
  safeMerge,
  fullReplace,
}

enum RestorePlanIssueSeverity {
  warning,
  blocker,
}

enum RestoreSafetyCheck {
  formatValidated,
  previewGenerated,
  conflictDetectionCompleted,
  explicitConfirmationReceived,
  preRestoreBackupCreated,
  transactionAvailable,
  testsPassing,
}

enum RestoreExecutionStep {
  validateFormat,
  parseBackup,
  buildPreview,
  runConflictDetection,
  requireExplicitConfirmation,
  createPreRestoreSafetyBackup,
  startTransaction,
  importOrRemapCategories,
  importOrRemapExpenses,
  importOrRemapGroceryItems,
  importOrRemapBudgets,
  importSettingsIfSelected,
  verifyCounts,
  commitOrRollback,
  refreshAppState,
}

class RestoreEntitySelection {
  const RestoreEntitySelection({
    this.expenses = true,
    this.groceryItems = true,
    this.categories = true,
    this.budgets = true,
    this.settings = false,
    this.receiptReferences = true,
  });

  final bool expenses;
  final bool groceryItems;
  final bool categories;
  final bool budgets;
  final bool settings;
  final bool receiptReferences;

  static const backupData = RestoreEntitySelection();

  RestoreEntitySelection copyWith({
    bool? expenses,
    bool? groceryItems,
    bool? categories,
    bool? budgets,
    bool? settings,
    bool? receiptReferences,
  }) {
    return RestoreEntitySelection(
      expenses: expenses ?? this.expenses,
      groceryItems: groceryItems ?? this.groceryItems,
      categories: categories ?? this.categories,
      budgets: budgets ?? this.budgets,
      settings: settings ?? this.settings,
      receiptReferences: receiptReferences ?? this.receiptReferences,
    );
  }
}

class RestorePlanIssue {
  const RestorePlanIssue({
    required this.severity,
    required this.message,
  });

  final RestorePlanIssueSeverity severity;
  final String message;

  bool get isBlocker => severity == RestorePlanIssueSeverity.blocker;
}

class RestorePlan {
  const RestorePlan({
    required this.mode,
    required this.entitySelection,
    required this.requiredSafetyChecks,
    required this.completedSafetyChecks,
    required this.executionSteps,
    this.issues = const [],
  });

  factory RestorePlan.previewOnly({
    RestoreEntitySelection entitySelection = RestoreEntitySelection.backupData,
    Set<RestoreSafetyCheck> completedSafetyChecks = const {},
    List<RestorePlanIssue> issues = const [],
  }) {
    return RestorePlan(
      mode: RestoreMode.previewOnly,
      entitySelection: entitySelection,
      requiredSafetyChecks: const {
        RestoreSafetyCheck.formatValidated,
        RestoreSafetyCheck.previewGenerated,
        RestoreSafetyCheck.conflictDetectionCompleted,
      },
      completedSafetyChecks: completedSafetyChecks,
      executionSteps: previewOnlySteps,
      issues: issues,
    );
  }

  factory RestorePlan.safeMerge({
    RestoreEntitySelection entitySelection = RestoreEntitySelection.backupData,
    Set<RestoreSafetyCheck> completedSafetyChecks = const {},
    List<RestorePlanIssue> issues = const [],
  }) {
    return RestorePlan(
      mode: RestoreMode.safeMerge,
      entitySelection: entitySelection,
      requiredSafetyChecks: mutationSafetyChecks,
      completedSafetyChecks: completedSafetyChecks,
      executionSteps: mutationPlanningSteps,
      issues: issues,
    );
  }

  factory RestorePlan.fullReplaceUnsupported({
    RestoreEntitySelection entitySelection = RestoreEntitySelection.backupData,
    Set<RestoreSafetyCheck> completedSafetyChecks = const {},
  }) {
    return RestorePlan(
      mode: RestoreMode.fullReplace,
      entitySelection: entitySelection,
      requiredSafetyChecks: mutationSafetyChecks,
      completedSafetyChecks: completedSafetyChecks,
      executionSteps: mutationPlanningSteps,
      issues: const [
        RestorePlanIssue(
          severity: RestorePlanIssueSeverity.blocker,
          message:
              'Full replace restore is not supported until explicit data loss '
              'controls and rollback verification exist.',
        ),
      ],
    );
  }

  final RestoreMode mode;
  final RestoreEntitySelection entitySelection;
  final Set<RestoreSafetyCheck> requiredSafetyChecks;
  final Set<RestoreSafetyCheck> completedSafetyChecks;
  final List<RestoreExecutionStep> executionSteps;
  final List<RestorePlanIssue> issues;

  static const previewOnlySteps = <RestoreExecutionStep>[
    RestoreExecutionStep.validateFormat,
    RestoreExecutionStep.parseBackup,
    RestoreExecutionStep.buildPreview,
    RestoreExecutionStep.runConflictDetection,
  ];

  static const mutationPlanningSteps = <RestoreExecutionStep>[
    RestoreExecutionStep.validateFormat,
    RestoreExecutionStep.parseBackup,
    RestoreExecutionStep.buildPreview,
    RestoreExecutionStep.runConflictDetection,
    RestoreExecutionStep.requireExplicitConfirmation,
    RestoreExecutionStep.createPreRestoreSafetyBackup,
    RestoreExecutionStep.startTransaction,
    RestoreExecutionStep.importOrRemapCategories,
    RestoreExecutionStep.importOrRemapExpenses,
    RestoreExecutionStep.importOrRemapGroceryItems,
    RestoreExecutionStep.importOrRemapBudgets,
    RestoreExecutionStep.importSettingsIfSelected,
    RestoreExecutionStep.verifyCounts,
    RestoreExecutionStep.commitOrRollback,
    RestoreExecutionStep.refreshAppState,
  ];

  static const mutationSafetyChecks = <RestoreSafetyCheck>{
    RestoreSafetyCheck.formatValidated,
    RestoreSafetyCheck.previewGenerated,
    RestoreSafetyCheck.conflictDetectionCompleted,
    RestoreSafetyCheck.explicitConfirmationReceived,
    RestoreSafetyCheck.preRestoreBackupCreated,
    RestoreSafetyCheck.transactionAvailable,
    RestoreSafetyCheck.testsPassing,
  };

  bool get isMutationMode => mode != RestoreMode.previewOnly;

  bool get requiresExplicitConfirmation => isMutationMode;

  bool get importsSettings => entitySelection.settings;

  bool get hasBlockers => issues.any((issue) => issue.isBlocker);

  bool get hasAllRequiredSafetyChecks =>
      completedSafetyChecks.containsAll(requiredSafetyChecks);

  bool get canStartMutation =>
      isMutationMode && hasAllRequiredSafetyChecks && !hasBlockers;
}
