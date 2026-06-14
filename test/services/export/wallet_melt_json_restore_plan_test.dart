import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_plan.dart';

void main() {
  group('RestorePlan', () {
    test('defaults to preview-only with no mutation permission', () {
      final plan = RestorePlan.previewOnly();

      expect(plan.mode, RestoreMode.previewOnly);
      expect(plan.isMutationMode, isFalse);
      expect(plan.requiresExplicitConfirmation, isFalse);
      expect(plan.canStartMutation, isFalse);
      expect(plan.executionSteps, RestorePlan.previewOnlySteps);
    });

    test('safe merge requires confirmation and all mutation safety gates', () {
      final plan = RestorePlan.safeMerge();

      expect(plan.mode, RestoreMode.safeMerge);
      expect(plan.isMutationMode, isTrue);
      expect(plan.requiresExplicitConfirmation, isTrue);
      expect(plan.requiredSafetyChecks, RestorePlan.mutationSafetyChecks);
      expect(plan.canStartMutation, isFalse);
    });

    test('safe merge can start only after all safety checks pass', () {
      final plan = RestorePlan.safeMerge(
        completedSafetyChecks: RestorePlan.mutationSafetyChecks,
      );

      expect(plan.hasAllRequiredSafetyChecks, isTrue);
      expect(plan.canStartMutation, isTrue);
    });

    test('blocker issue prevents mutation even with safety checks', () {
      final plan = RestorePlan.safeMerge(
        completedSafetyChecks: RestorePlan.mutationSafetyChecks,
        issues: const [
          RestorePlanIssue(
            severity: RestorePlanIssueSeverity.blocker,
            message: 'Duplicate IDs were not resolved.',
          ),
        ],
      );

      expect(plan.hasBlockers, isTrue);
      expect(plan.canStartMutation, isFalse);
    });

    test('settings import is optional by default', () {
      final defaultPlan = RestorePlan.safeMerge();
      final settingsPlan = RestorePlan.safeMerge(
        entitySelection:
            RestoreEntitySelection.backupData.copyWith(settings: true),
      );

      expect(defaultPlan.importsSettings, isFalse);
      expect(settingsPlan.importsSettings, isTrue);
    });

    test('full replace is represented as unsupported blocker', () {
      final plan = RestorePlan.fullReplaceUnsupported(
        completedSafetyChecks: RestorePlan.mutationSafetyChecks,
      );

      expect(plan.mode, RestoreMode.fullReplace);
      expect(plan.hasBlockers, isTrue);
      expect(plan.canStartMutation, isFalse);
    });

    test('mutation planning steps are ordered for transaction design', () {
      expect(RestorePlan.mutationPlanningSteps, [
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
      ]);
    });
  });
}
