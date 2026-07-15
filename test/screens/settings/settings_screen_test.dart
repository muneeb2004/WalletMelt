import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/screens/settings/settings_screen.dart';
import 'package:wallet_melt/src/services/export/expense_csv_export_service.dart';
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/services/export/export_share_service.dart';
import 'package:wallet_melt/src/services/export/file_picker_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_validator.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_conflict_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_import_validation_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_preview_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_dry_run_planner.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_plan.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_service.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/security/pin_lock_controller.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('SettingsScreen CSV export', () {
    testWidgets('shows export action', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
        ),
      );

      expect(find.text('Data export'), findsOneWidget);
      expect(find.text('Export expenses CSV'), findsOneWidget);
    });

    testWidgets('exports current active expenses and shares generated file',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final appState = _appState()
        ..categories = [_category(id: 'grocery', name: 'Groceries')]
        ..expenses = [_expense(id: 'active', title: 'Weekly grocery')];
      final exportService = FakeExpenseCsvExportService();
      final shareService = FakeExportShareService();

      await tester.pumpWidget(
        _settingsHarness(
          appState: appState,
          exportService: exportService,
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: shareService,
        ),
      );

      await tester.ensureVisible(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();

      expect(exportService.exportCalled, isTrue);
      expect(
          exportService.lastExpenses.map((expense) => expense.id), ['active']);
      expect(exportService.lastCategories.map((category) => category.name),
          ['Groceries']);
      expect(shareService.shareCalled, isTrue);
      expect(shareService.lastFile?.fileName,
          'walletmelt-expenses-20260614-090807.csv');
      expect(appState.settings.lastExportedAt, '2026-06-14T09:08:07.000');
      expect(find.text('CSV export shared.'), findsOneWidget);
    });

    testWidgets('include-deleted option passes active and deleted expenses',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final appState = _appState()
        ..categories = [_category(id: 'grocery', name: 'Groceries')]
        ..expenses = [_expense(id: 'active', title: 'Weekly grocery')]
        ..deletedExpenses = [
          _expense(
            id: 'deleted',
            title: 'Deleted grocery',
            deletedAt: '2026-06-15T00:00:00.000',
          ),
        ];
      final exportService = FakeExpenseCsvExportService();
      final shareService = FakeExportShareService();

      await tester.pumpWidget(
        _settingsHarness(
          appState: appState,
          exportService: exportService,
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: shareService,
        ),
      );

      await tester.ensureVisible(find.text('Include deleted expenses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Include deleted expenses'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();

      expect(exportService.lastIncludeDeleted, isTrue);
      expect(exportService.lastExpenses.map((expense) => expense.id),
          ['active', 'deleted']);
      expect(find.textContaining('1 active, 1 deleted'), findsOneWidget);
    });

    testWidgets('handles empty expense list gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final exportService = FakeExpenseCsvExportService();
      final shareService = FakeExportShareService();

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: exportService,
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: shareService,
        ),
      );

      await tester.ensureVisible(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();

      expect(exportService.exportCalled, isTrue);
      expect(exportService.lastExpenses, isEmpty);
      expect(shareService.shareCalled, isTrue);
    });

    testWidgets('creates JSON backup with active and deleted expenses',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final expenseRepository = FakeExpenseRepository()
        ..groceryItems = [_groceryItem(id: 'milk_item')];
      final budgetRepository = FakeBudgetRepository()
        ..budgets = [_budget(id: 'june_budget')];
      final appState = _appState(
        expenseRepository: expenseRepository,
        budgetRepository: budgetRepository,
      )
        ..categories = [_category(id: 'grocery', name: 'Groceries')]
        ..expenses = [_expense(id: 'active', title: 'Weekly grocery')]
        ..deletedExpenses = [
          _expense(
            id: 'deleted',
            title: 'Deleted grocery',
            deletedAt: '2026-06-15T00:00:00.000',
          ),
        ];
      final jsonBackupService = FakeWalletMeltJsonBackupService();
      final shareService = FakeExportShareService();

      await tester.pumpWidget(
        _settingsHarness(
          appState: appState,
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: jsonBackupService,
          shareService: shareService,
        ),
      );

      await tester.ensureVisible(find.text('Back up JSON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back up JSON'));
      await tester.pumpAndSettle();

      expect(jsonBackupService.backupCalled, isTrue);
      expect(jsonBackupService.lastExpenses.map((expense) => expense.id),
          ['active', 'deleted']);
      expect(jsonBackupService.lastGroceryItems.map((item) => item.id),
          ['milk_item']);
      expect(jsonBackupService.lastCategories.map((category) => category.name),
          ['Groceries']);
      expect(jsonBackupService.lastBudgets.map((budget) => budget.id),
          ['june_budget']);
      expect(
          jsonBackupService.lastSettings.currency, appState.settings.currency);
      expect(shareService.shareCalled, isTrue);
      expect(shareService.lastFile?.fileName,
          'walletmelt-backup-20260614-090807.json');
      expect(shareService.lastSubject, 'WalletMelt JSON backup');
      expect(shareService.lastTitle, 'Back up WalletMelt data');
      expect(appState.settings.lastExportedAt, '2026-06-14T09:08:07.000');
      expect(find.text('JSON backup shared.'), findsOneWidget);
    });
  });

  group('SettingsScreen import validation', () {
    testWidgets('displays the validation button and description',
        (tester) async {
      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Data import'),
        100.0,
      );
      await tester.pumpAndSettle();

      expect(find.text('Data import'), findsOneWidget);
      expect(find.text('Validate backup file'), findsOneWidget);
      expect(find.textContaining('Select a backup JSON file to verify'),
          findsOneWidget);
    });

    testWidgets(
        'shows success message and counts when a valid backup is selected',
        (tester) async {
      final filePicker = FakeFilePickerService()
        ..resultText = '{"valid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: true,
                  expensesCount: 5,
                  groceryItemsCount: 3,
                  categoriesCount: 2,
                  budgetsCount: 1,
                );

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      expect(filePicker.pickCalled, isTrue);
      expect(find.textContaining('Backup file is valid'), findsOneWidget);
      expect(
          find.textContaining(
              'Preview found 5 expenses, 3 items, 2 categories, and 1 budgets'),
          findsOneWidget);
      expect(find.textContaining('No data has been imported'), findsOneWidget);
    });

    testWidgets(
        'shows read-only preview dialog with metadata and counts when a valid backup is selected',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final filePicker = FakeFilePickerService()
        ..resultText = '{"valid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: true,
                  expensesCount: 5,
                  groceryItemsCount: 3,
                  categoriesCount: 2,
                  budgetsCount: 1,
                );
      final previewService = FakeWalletMeltJsonBackupPreviewService()
        ..onPreview = (content) => const WalletMeltBackupPreview(
              isValid: true,
              format: 'walletmelt.local_json_backup',
              formatVersion: 1,
              appVersion: '0.1.1',
              exportedAt: '2026-06-14T09:08:07.000',
              expensesCount: 5,
              deletedExpensesCount: 1,
              groceryItemsCount: 3,
              categoriesCount: 2,
              budgetsCount: 1,
              hasSettings: true,
              receiptImageCount: 1,
              warnings: ['Receipt warning example'],
            );

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
          previewService: previewService,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Backup Preview'), findsOneWidget);
      expect(find.text('Format Version'), findsOneWidget);
      expect(find.text('0.1.1'), findsOneWidget);
      expect(find.text('5 (1 deleted)'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('2 categories'), findsOneWidget);
      expect(find.text('1 budgets'), findsOneWidget);
      expect(find.text('Receipt warning example'), findsOneWidget);

      // Close preview
      await tester.ensureVisible(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Backup Preview'), findsNothing);
    });

    testWidgets(
        'does not show preview dialog when an invalid backup is selected',
        (tester) async {
      final filePicker = FakeFilePickerService()
        ..resultText = '{"invalid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: false,
                  error: 'Schema error',
                );
      final previewService = FakeWalletMeltJsonBackupPreviewService()
        ..onPreview = (content) => const WalletMeltBackupPreview(
              isValid: false,
              error: 'Schema error',
            );

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
          previewService: previewService,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      expect(find.text('Backup Preview'), findsNothing);
      expect(find.textContaining('Schema error'), findsOneWidget);
    });

    testWidgets('shows failure message when an invalid backup is selected',
        (tester) async {
      final filePicker = FakeFilePickerService()
        ..resultText = '{"invalid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: false,
                  error: 'Invalid schema version',
                );

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      expect(filePicker.pickCalled, isTrue);
      expect(find.textContaining('Invalid backup file: Invalid schema version'),
          findsOneWidget);
    });

    testWidgets('handles cancelled picker response gracefully without crashing',
        (tester) async {
      final filePicker = FakeFilePickerService()..resultText = null;

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      expect(filePicker.pickCalled, isTrue);
    });
  });

  group('SettingsScreen conflict detection UI', () {
    testWidgets('preview dialog shows conflict section with duplicate warnings',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final filePicker = FakeFilePickerService()
        ..resultText = '{"valid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: true,
                  expensesCount: 2,
                  groceryItemsCount: 0,
                  categoriesCount: 1,
                  budgetsCount: 0,
                );
      final previewService = FakeWalletMeltJsonBackupPreviewService()
        ..onPreview = (content) => const WalletMeltBackupPreview(
              isValid: true,
              format: 'walletmelt.local_json_backup',
              formatVersion: 1,
              appVersion: '0.1.1',
              exportedAt: '2026-06-14T09:08:07.000',
              expensesCount: 2,
              deletedExpensesCount: 0,
              groceryItemsCount: 0,
              categoriesCount: 1,
              budgetsCount: 0,
              hasSettings: true,
            );
      final conflictService = FakeWalletMeltJsonBackupConflictService()
        ..onDetect = (_, __) => const BackupConflictSummary(
              duplicateExpenseIdCount: 2,
              hasAnyConflict: true,
            );

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
          previewService: previewService,
          conflictService: conflictService,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      expect(find.text('Backup Preview'), findsOneWidget);
      expect(find.text('Conflict check'), findsOneWidget);
      expect(
        find.textContaining('2 expense ID(s) already exist'),
        findsOneWidget,
      );
      // Restore must still be disabled.
      expect(find.text('Restore (N/A)'), findsOneWidget);
      final restoreButton =
          find.widgetWithText(ElevatedButton, 'Restore (N/A)');
      expect(
        tester.widget<ElevatedButton>(restoreButton).onPressed,
        isNull,
      );
    });

    testWidgets(
        'preview dialog shows no-conflict message when clean backup selected',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final filePicker = FakeFilePickerService()
        ..resultText = '{"valid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: true,
                  expensesCount: 1,
                  groceryItemsCount: 0,
                  categoriesCount: 1,
                  budgetsCount: 0,
                );
      final previewService = FakeWalletMeltJsonBackupPreviewService()
        ..onPreview = (content) => const WalletMeltBackupPreview(
              isValid: true,
              format: 'walletmelt.local_json_backup',
              formatVersion: 1,
              appVersion: '0.1.1',
              exportedAt: '2026-06-14T09:08:07.000',
              expensesCount: 1,
              deletedExpensesCount: 0,
              groceryItemsCount: 0,
              categoriesCount: 1,
              budgetsCount: 0,
              hasSettings: true,
            );
      final conflictService = FakeWalletMeltJsonBackupConflictService()
        ..onDetect =
            (_, __) => const BackupConflictSummary(hasAnyConflict: false);
      final dryRunPlanner = FakeWalletMeltJsonRestoreDryRunPlanner()
        ..onPlan = (_, __) => _dryRunPlan();

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
          previewService: previewService,
          conflictService: conflictService,
          dryRunPlanner: dryRunPlanner,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      expect(find.text('Backup Preview'), findsOneWidget);
      expect(find.text('Conflict check'), findsOneWidget);
      expect(
        find.text('No conflicts detected with current local data.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Restore is unavailable until validation'),
        findsOneWidget,
      );
      expect(find.text('Dry-run restore plan'), findsOneWidget);
      expect(find.text('Planned categories'), findsOneWidget);
      expect(find.text('Planned expenses'), findsOneWidget);
      expect(find.text('Blockers / warnings'), findsOneWidget);
      expect(find.textContaining('Dry-run only'), findsOneWidget);
    });

    testWidgets('preview opens without crash when conflict detection throws',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final filePicker = FakeFilePickerService()
        ..resultText = '{"valid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: true,
                  expensesCount: 0,
                  groceryItemsCount: 0,
                  categoriesCount: 0,
                  budgetsCount: 0,
                );
      final previewService = FakeWalletMeltJsonBackupPreviewService()
        ..onPreview = (content) => const WalletMeltBackupPreview(
              isValid: true,
              format: 'walletmelt.local_json_backup',
              formatVersion: 1,
              appVersion: '0.1.1',
              exportedAt: '2026-06-14T09:08:07.000',
              expensesCount: 0,
              deletedExpensesCount: 0,
              groceryItemsCount: 0,
              categoriesCount: 0,
              budgetsCount: 0,
              hasSettings: false,
            );
      // Fake that throws to simulate a detection failure.
      final conflictService = FakeWalletMeltJsonBackupConflictService()
        ..onDetect = (_, __) => throw Exception('Simulated detection failure');

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
          previewService: previewService,
          conflictService: conflictService,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      // Dialog opens without crash; conflict section absent.
      expect(find.text('Backup Preview'), findsOneWidget);
      expect(find.text('Conflict check'), findsNothing);
      expect(find.text('Dry-run restore plan'), findsNothing);
    });

    testWidgets('Restore (N/A) button is always disabled in preview dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final filePicker = FakeFilePickerService()
        ..resultText = '{"valid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: true,
                  expensesCount: 0,
                  groceryItemsCount: 0,
                  categoriesCount: 0,
                  budgetsCount: 0,
                );
      final previewService = FakeWalletMeltJsonBackupPreviewService()
        ..onPreview = (content) => const WalletMeltBackupPreview(
              isValid: true,
              format: 'walletmelt.local_json_backup',
              formatVersion: 1,
              appVersion: '0.1.1',
              exportedAt: '2026-06-14T09:08:07.000',
              expensesCount: 0,
              deletedExpensesCount: 0,
              groceryItemsCount: 0,
              categoriesCount: 0,
              budgetsCount: 0,
              hasSettings: false,
            );
      final conflictService = FakeWalletMeltJsonBackupConflictService()
        ..onDetect =
            (_, __) => const BackupConflictSummary(hasAnyConflict: false);

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
          previewService: previewService,
          conflictService: conflictService,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      final restoreButton =
          find.widgetWithText(ElevatedButton, 'Restore (N/A)');
      expect(restoreButton, findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(restoreButton).onPressed,
        isNull,
        reason: 'Restore button must remain disabled — no mutation allowed.',
      );
    });

    testWidgets('preview dialog shows dry-run blockers and warnings',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final filePicker = FakeFilePickerService()
        ..resultText = '{"valid": "json"}';
      final validationService =
          FakeWalletMeltJsonBackupImportValidationService()
            ..onValidate = (content) => const BackupValidationResult(
                  isValid: true,
                  expensesCount: 1,
                  groceryItemsCount: 1,
                  categoriesCount: 1,
                  budgetsCount: 1,
                );
      final previewService = FakeWalletMeltJsonBackupPreviewService();
      final conflictService = FakeWalletMeltJsonBackupConflictService();
      final dryRunPlanner = FakeWalletMeltJsonRestoreDryRunPlanner()
        ..onPlan = (_, __) => _dryRunPlan(blockers: 1, warnings: 2);

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: filePicker,
          importValidationService: validationService,
          previewService: previewService,
          conflictService: conflictService,
          dryRunPlanner: dryRunPlanner,
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Validate backup file'),
        100.0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      expect(find.text('Dry-run restore plan'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Restore (N/A)'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Restore (N/A)'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('Restore disabled when dry-run has blockers', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dryRunPlanner = FakeWalletMeltJsonRestoreDryRunPlanner()
        ..onPlan = (_, __) => _dryRunPlan(blockers: 1);

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: dryRunPlanner,
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      final restoreButton =
          find.widgetWithText(ElevatedButton, 'Restore (N/A)');
      expect(restoreButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(restoreButton).onPressed, isNull);
      expect(find.textContaining('blockers must be resolved first'),
          findsOneWidget);
      expect(find.textContaining('will not resolve conflicts automatically'),
          findsOneWidget);
    });

    testWidgets('Restore enabled only for valid no-blocker plan',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();

      final restoreButton = find.widgetWithText(ElevatedButton, 'Safe merge');
      expect(restoreButton, findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(restoreButton).onPressed,
        isNotNull,
      );
    });

    testWidgets('confirmation dialog appears before restore', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Safe merge'));
      await tester.tap(find.text('Safe merge'));
      await tester.pumpAndSettle();

      expect(find.text('Safe merge backup?'), findsOneWidget);
      expect(find.textContaining('Safe merge adds'), findsOneWidget);
      expect(find.textContaining('local data'), findsWidgets);
      expect(find.textContaining('safety backup'), findsWidgets);
      expect(find.textContaining('restore stops before any import'),
          findsOneWidget);
      expect(find.textContaining('Receipt image files are not recovered'),
          findsOneWidget);
    });

    testWidgets('cancelling confirmation causes no mutation', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final restoreService = FakeWalletMeltJsonRestoreService();

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
          restoreService: restoreService,
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Safe merge'));
      await tester.tap(find.text('Safe merge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(restoreService.restoreCalled, isFalse);
    });

    testWidgets('confirmed restore calls restore service and shows success',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final restoreService = FakeWalletMeltJsonRestoreService()
        ..result = const WalletMeltJsonRestoreResult(
          success: true,
          insertedExpenses: 1,
          insertedGroceryItems: 1,
          insertedCategories: 1,
          insertedBudgets: 1,
          safetyBackupPath: 'D:/tmp/walletmelt-backup-20260614-090807.json',
        );

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
          restoreService: restoreService,
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Safe merge'));
      await tester.tap(find.text('Safe merge'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create safety backup and merge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create safety backup and merge'));
      await tester.pump();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(restoreService.restoreCalled, isTrue);
      expect(restoreService.lastOptions?.confirmed, isTrue);
      expect(restoreService.restoreCalled, isTrue);
      expect(restoreService.lastOptions?.confirmed, isTrue);
      expect(find.textContaining('Safe merge complete'), findsOneWidget);
      expect(find.textContaining('Safe merge complete: 1 expenses'),
          findsOneWidget);
      expect(find.textContaining('1 items, 1 categories, and 1 budgets'),
          findsOneWidget);
      expect(find.textContaining('Local data was preserved'), findsOneWidget);
      expect(find.textContaining('walletmelt-backup-20260614-090807.json'),
          findsOneWidget);
      expect(find.textContaining('Receipt paths remain text references only'),
          findsOneWidget);
    });

    testWidgets('restore failure message is user-safe without stack traces',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final restoreService = FakeWalletMeltJsonRestoreService()
        ..result = WalletMeltJsonRestoreResult.failure(
          'StateError: simulated failure\n#0 SettingsScreen.fake',
          safetyBackupPath: 'D:/tmp/walletmelt-safety.json',
        );

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
          restoreService: restoreService,
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Safe merge'));
      await tester.tap(find.text('Safe merge'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create safety backup and merge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create safety backup and merge'));
      await tester.pump();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(restoreService.restoreCalled, isTrue);
      expect(find.textContaining('Restore failed safely'), findsOneWidget);
      expect(find.textContaining('rolls back the transaction'), findsOneWidget);
      expect(find.textContaining('walletmelt-safety.json'), findsOneWidget);
      expect(find.textContaining('simulated failure'), findsOneWidget);
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.textContaining('#0'), findsNothing);
    });

    testWidgets('confirmed restore shows failure message', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final restoreService = FakeWalletMeltJsonRestoreService()
        ..result =
            WalletMeltJsonRestoreResult.failure('Restore failed safely.');

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
          restoreService: restoreService,
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Safe merge'));
      await tester.tap(find.text('Safe merge'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create safety backup and merge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create safety backup and merge'));
      await tester.pump();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(restoreService.restoreCalled, isTrue);
      expect(find.textContaining('Restore failed safely'), findsOneWidget);
      expect(find.textContaining('Restore failed safely.'), findsOneWidget);
    });

    testWidgets('safety backup creation failure is clear and non-technical',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FailingWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Safe merge'));
      await tester.tap(find.text('Safe merge'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create safety backup and merge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create safety backup and merge'));
      await tester.pump();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('Restore did not start'), findsOneWidget);
      expect(find.textContaining('No data was changed'), findsOneWidget);
      expect(find.textContaining('safety backup'), findsOneWidget);
      expect(find.textContaining('disk full'), findsOneWidget);
      expect(find.textContaining('Exception:'), findsNothing);
      expect(find.textContaining('#0'), findsNothing);
    });

    testWidgets('restore-in-progress disables validation action',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final restoreCompleter = Completer<WalletMeltJsonRestoreResult>();
      final restoreService = FakeWalletMeltJsonRestoreService()
        ..pendingResult = restoreCompleter.future;

      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
          jsonBackupService: FakeWalletMeltJsonBackupService(),
          shareService: FakeExportShareService(),
          filePickerService: FakeFilePickerService()
            ..resultText = '{"valid": "json"}',
          importValidationService:
              FakeWalletMeltJsonBackupImportValidationService()
                ..onValidate = (_) => const BackupValidationResult(
                      isValid: true,
                      expensesCount: 1,
                      groceryItemsCount: 1,
                      categoriesCount: 1,
                      budgetsCount: 1,
                    ),
          previewService: FakeWalletMeltJsonBackupPreviewService(),
          conflictService: FakeWalletMeltJsonBackupConflictService(),
          dryRunPlanner: FakeWalletMeltJsonRestoreDryRunPlanner()
            ..onPlan = (_, __) => _dryRunPlan(restorable: true),
          restoreService: restoreService,
        ),
      );

      await tester.scrollUntilVisible(find.text('Validate backup file'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validate backup file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Safe merge'));
      await tester.tap(find.text('Safe merge'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create safety backup and merge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create safety backup and merge'));
      await tester.pump();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final validateButton =
          find.widgetWithText(OutlinedButton, 'Validate backup file');
      expect(validateButton, findsOneWidget);
      expect(tester.widget<OutlinedButton>(validateButton).onPressed, isNull);

      restoreCompleter.complete(
        const WalletMeltJsonRestoreResult(success: true),
      );
      await tester.pumpAndSettle();
    });
  });
}

Widget _settingsHarness({
  required AppState appState,
  required ExpenseCsvExportService exportService,
  required WalletMeltJsonBackupService jsonBackupService,
  required ExportShareService shareService,
  FilePickerService filePickerService = const FilePickerService(),
  WalletMeltJsonBackupImportValidationService importValidationService =
      const WalletMeltJsonBackupImportValidationService(),
  WalletMeltJsonBackupPreviewService previewService =
      const WalletMeltJsonBackupPreviewService(),
  WalletMeltJsonBackupConflictService conflictService =
      const WalletMeltJsonBackupConflictService(),
  WalletMeltJsonRestoreDryRunPlanner dryRunPlanner =
      const WalletMeltJsonRestoreDryRunPlanner(),
  WalletMeltJsonRestoreService restoreService =
      const WalletMeltJsonRestoreService(),
}) {
  final pinLockController = FakePinLockController();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: appState),
      ChangeNotifierProvider<PinLockController>.value(value: pinLockController),
    ],
    child: MaterialApp(
      home: SettingsScreen(
        expenseCsvExportService: exportService,
        jsonBackupService: jsonBackupService,
        exportShareService: shareService,
        filePickerService: filePickerService,
        importValidationService: importValidationService,
        previewService: previewService,
        conflictService: conflictService,
        restoreDryRunPlanner: dryRunPlanner,
        restoreService: restoreService,
        safetyBackupDirectory: Directory.systemTemp,
      ),
    ),
  );
}

AppState _appState({
  FakeExpenseRepository? expenseRepository,
  FakeBudgetRepository? budgetRepository,
}) {
  final state = AppState.test(
    driftCategoryRepository: FakeCategoryRepository(),
    driftExpenseRepository: expenseRepository ?? FakeExpenseRepository(),
    driftBudgetRepository: budgetRepository ?? FakeBudgetRepository(),
    settingsService: FakeSettingsService(),
  );
  state.settings = WalletMeltSettings.defaults.copyWith(
    hasCompletedOnboarding: true,
  );
  return state;
}

wm.Category _category({
  required String id,
  required String name,
}) {
  return wm.Category(
    id: id,
    name: name,
    icon: 'shopping_basket',
    color: '#000000',
    isDefault: true,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

Expense _expense({
  required String id,
  required String title,
  String? deletedAt,
}) {
  return Expense(
    id: id,
    amount: 1200,
    currency: 'PKR',
    categoryId: 'grocery',
    title: title,
    date: '2026-06-14T00:00:00.000',
    isRecurring: false,
    createdAt: '2026-06-14T10:00:00.000',
    updatedAt: '2026-06-14T10:00:00.000',
    deletedAt: deletedAt,
  );
}

GroceryItem _groceryItem({required String id}) {
  return GroceryItem(
    id: id,
    expenseId: 'active',
    name: 'Milk',
    amount: 520,
    createdAt: '2026-06-14T10:00:00.000',
  );
}

CategoryBudget _budget({required String id}) {
  return CategoryBudget(
    id: id,
    categoryId: 'grocery',
    amount: 30000,
    currency: 'PKR',
    month: '2026-06',
    createdAt: '2026-06-01T00:00:00.000',
    updatedAt: '2026-06-01T00:00:00.000',
  );
}

class FakeCategoryRepository extends Fake implements DriftCategoryRepository {
  List<wm.Category> categories = const [];

  @override
  Future<List<wm.Category>> listCategories() async => categories;
}

class FakeExpenseRepository extends Fake implements DriftExpenseRepository {
  List<Expense> activeExpenses = const [];
  List<Expense> deletedExpenses = const [];
  List<GroceryItem> groceryItems = const [];

  @override
  Future<List<Expense>> listActive() async => activeExpenses;

  @override
  Future<List<Expense>> listDeleted() async => deletedExpenses;

  @override
  Future<List<GroceryItem>> listAllGroceryItems() async => groceryItems;
}

class FakeBudgetRepository extends Fake implements DriftBudgetRepository {
  List<CategoryBudget> budgets = const [];

  @override
  Future<List<CategoryBudget>> listForMonth(String month) async => budgets;

  @override
  Future<List<CategoryBudget>> listAll() async => budgets;
}

class FakeSettingsService extends SettingsService {
  WalletMeltSettings saved = WalletMeltSettings.defaults;

  @override
  Future<WalletMeltSettings> load() async => saved;

  @override
  Future<void> save(WalletMeltSettings settings) async {
    saved = settings;
  }
}

class FakeExpenseCsvExportService extends ExpenseCsvExportService {
  bool exportCalled = false;
  List<Expense> lastExpenses = const [];
  List<wm.Category> lastCategories = const [];
  bool? lastIncludeDeleted;

  @override
  Future<ExportFileResult> exportActiveExpenses({
    required Iterable<Expense> expenses,
    required Iterable<wm.Category> categories,
    bool includeDeleted = false,
    DateTime? createdAt,
    Directory? directory,
  }) async {
    exportCalled = true;
    lastExpenses = expenses.toList();
    lastCategories = categories.toList();
    lastIncludeDeleted = includeDeleted;
    return ExportFileResult(
      path: 'D:/tmp/walletmelt-expenses-20260614-090807.csv',
      fileName: 'walletmelt-expenses-20260614-090807.csv',
      mimeType: ExportFileWriter.csvMimeType,
      byteCount: 42,
      createdAt: DateTime(2026, 6, 14, 9, 8, 7),
    );
  }
}

class FakeWalletMeltJsonBackupService extends WalletMeltJsonBackupService {
  bool backupCalled = false;
  List<Expense> lastExpenses = const [];
  List<GroceryItem> lastGroceryItems = const [];
  List<wm.Category> lastCategories = const [];
  List<CategoryBudget> lastBudgets = const [];
  WalletMeltSettings lastSettings = WalletMeltSettings.defaults;

  @override
  Future<ExportFileResult> createBackup({
    required Iterable<Expense> expenses,
    required Iterable<GroceryItem> groceryItems,
    required Iterable<wm.Category> categories,
    required Iterable<CategoryBudget> budgets,
    required WalletMeltSettings settings,
    DateTime? exportedAt,
    Directory? directory,
    bool packageReceipts = true,
  }) async {
    backupCalled = true;
    lastExpenses = expenses.toList();
    lastGroceryItems = groceryItems.toList();
    lastCategories = categories.toList();
    lastBudgets = budgets.toList();
    lastSettings = settings;
    return ExportFileResult(
      path: 'D:/tmp/walletmelt-backup-20260614-090807.json',
      fileName: 'walletmelt-backup-20260614-090807.json',
      mimeType: ExportFileWriter.jsonMimeType,
      byteCount: 84,
      createdAt: DateTime(2026, 6, 14, 9, 8, 7),
    );
  }
}

class FailingWalletMeltJsonBackupService
    extends FakeWalletMeltJsonBackupService {
  @override
  Future<ExportFileResult> createBackup({
    required Iterable<Expense> expenses,
    required Iterable<GroceryItem> groceryItems,
    required Iterable<wm.Category> categories,
    required Iterable<CategoryBudget> budgets,
    required WalletMeltSettings settings,
    DateTime? exportedAt,
    Directory? directory,
    bool packageReceipts = true,
  }) async {
    throw Exception('disk full\n#0 FakeStack');
  }
}

class FakeExportShareService implements ExportShareService {
  bool shareCalled = false;
  ExportFileResult? lastFile;
  String? lastSubject;
  String? lastTitle;

  @override
  Future<ExportShareResult> shareFile(
    ExportFileResult file, {
    Rect? sharePositionOrigin,
    String? subject,
    String? title,
  }) async {
    shareCalled = true;
    lastFile = file;
    lastSubject = subject;
    lastTitle = title;
    return const ExportShareResult(
      status: ExportShareStatus.success,
      raw: 'success',
    );
  }
}

class FakeFilePickerService extends Fake implements FilePickerService {
  String? resultText;
  bool pickCalled = false;
  bool isZip = false;
  List<int>? zipBytes;

  @override
  Future<String?> pickJsonFileContent() async {
    pickCalled = true;
    return resultText;
  }

  @override
  Future<WalletMeltBackupFile?> pickBackupFile() async {
    pickCalled = true;
    if (resultText == null) return null;
    return WalletMeltBackupFile(
      jsonText: resultText!,
      zipBytes: zipBytes,
      isZip: isZip,
    );
  }
}

class FakeWalletMeltJsonBackupImportValidationService extends Fake
    implements WalletMeltJsonBackupImportValidationService {
  BackupValidationResult Function(String)? onValidate;

  @override
  BackupValidationResult validateBackup(String jsonText) {
    if (onValidate != null) {
      return onValidate!(jsonText);
    }
    return const BackupValidationResult(
        isValid: true,
        expensesCount: 0,
        groceryItemsCount: 0,
        categoriesCount: 0,
        budgetsCount: 0);
  }
}

class FakeWalletMeltJsonBackupPreviewService extends Fake
    implements WalletMeltJsonBackupPreviewService {
  WalletMeltBackupPreview Function(String)? onPreview;

  @override
  WalletMeltBackupPreview generatePreview(String jsonText) {
    if (onPreview != null) {
      return onPreview!(jsonText);
    }
    return const WalletMeltBackupPreview(
      isValid: true,
      format: 'walletmelt.local_json_backup',
      formatVersion: 1,
      appVersion: '0.1.1',
      exportedAt: '2026-06-14T09:08:07.000',
      expensesCount: 5,
      deletedExpensesCount: 1,
      groceryItemsCount: 3,
      categoriesCount: 2,
      budgetsCount: 1,
      hasSettings: true,
      receiptImageCount: 1,
      warnings: ['Receipt warning example'],
    );
  }
}

class FakeWalletMeltJsonBackupConflictService extends Fake
    implements WalletMeltJsonBackupConflictService {
  BackupConflictSummary Function(
      String jsonText, LocalAppSnapshot localSnapshot)? onDetect;

  @override
  BackupConflictSummary detect({
    required String jsonText,
    required LocalAppSnapshot localSnapshot,
  }) {
    if (onDetect != null) {
      return onDetect!(jsonText, localSnapshot);
    }
    return const BackupConflictSummary(hasAnyConflict: false);
  }
}

class FakeWalletMeltJsonRestoreDryRunPlanner extends Fake
    implements WalletMeltJsonRestoreDryRunPlanner {
  RestoreDryRunPlan Function(String jsonText, LocalAppSnapshot localSnapshot)?
      onPlan;

  @override
  RestoreDryRunPlan plan({
    required String jsonText,
    required LocalAppSnapshot localSnapshot,
    BackupConflictSummary? conflictSummary,
    bool previewGenerated = true,
    bool settingsImportSelected = false,
    RestoreMode mode = RestoreMode.safeMerge,
  }) {
    if (onPlan != null) {
      return onPlan!(jsonText, localSnapshot);
    }
    return _dryRunPlan();
  }
}

class FakeWalletMeltJsonRestoreService extends WalletMeltJsonRestoreService {
  bool restoreCalled = false;
  WalletMeltJsonRestoreOptions? lastOptions;
  ExportFileResult? lastSafetyBackup;
  WalletMeltJsonRestoreResult result =
      const WalletMeltJsonRestoreResult(success: true);
  Future<WalletMeltJsonRestoreResult>? pendingResult;

  @override
  Future<WalletMeltJsonRestoreResult> restoreSafeMerge({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required WalletMeltJsonRestoreOptions options,
    required ExportFileResult safetyBackup,
    local.WalletMeltDatabase? database,
    Directory? zipExtractDir,
  }) async {
    restoreCalled = true;
    lastOptions = options;
    lastSafetyBackup = safetyBackup;
    final pending = pendingResult;
    if (pending != null) return pending;
    return result;
  }

  @override
  Future<WalletMeltJsonRestoreResult> restoreFullReplace({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required WalletMeltJsonRestoreOptions options,
    required ExportFileResult safetyBackup,
    local.WalletMeltDatabase? database,
    Directory? zipExtractDir,
  }) async {
    restoreCalled = true;
    lastOptions = options;
    lastSafetyBackup = safetyBackup;
    final pending = pendingResult;
    if (pending != null) return pending;
    return result;
  }
}


RestoreDryRunPlan _dryRunPlan({
  int blockers = 0,
  int warnings = 0,
  bool restorable = false,
}) {
  final issues = <RestoreDryRunIssue>[
    for (var index = 0; index < blockers; index++)
      RestoreDryRunIssue(
        severity: RestoreDryRunIssueSeverity.blocker,
        message: 'Blocker $index',
      ),
    for (var index = 0; index < warnings; index++)
      RestoreDryRunIssue(
        severity: RestoreDryRunIssueSeverity.warning,
        message: 'Warning $index',
      ),
  ];

  return RestoreDryRunPlan(
    isValid: true,
    backupCounts: const RestoreDryRunEntityCounts(
      categories: 1,
      expenses: 1,
      groceryItems: 1,
      budgets: 1,
      settings: 1,
    ),
    plannedCounts: const RestoreDryRunEntityCounts(
      categories: 1,
      expenses: 1,
      groceryItems: 1,
      budgets: 1,
    ),
    actions: const [],
    idMappings: const [],
    issues: issues,
    safetyGates: [
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.backupFormatSupported,
        label: 'Backup format supported',
        satisfied: true,
      ),
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.formatVersionSupported,
        label: 'Format version supported',
        satisfied: restorable,
      ),
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.previewGenerated,
        label: 'Preview generated',
        satisfied: restorable,
      ),
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.conflictSummaryReviewed,
        label: 'Conflict summary reviewed',
        satisfied: restorable,
      ),
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.noUnresolvedBlockers,
        label: 'No unresolved blockers',
        satisfied: restorable && blockers == 0,
      ),
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.explicitConfirmationRequiredLater,
        label: 'Explicit confirmation still required later',
        satisfied: restorable,
      ),
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.preRestoreBackupRequiredLater,
        label: 'Pre-restore backup still required later',
        satisfied: restorable,
      ),
      RestoreDryRunSafetyGateStatus(
        gate: RestoreDryRunSafetyGate.transactionRuntimeRequiredLater,
        label: 'Transaction runtime still required later',
        satisfied: restorable,
      ),
    ],
    futureExecutionSteps: RestorePlan.mutationPlanningSteps,
    restorePlan: RestorePlan.safeMerge(),
  );
}

class FakePinLockController extends PinLockController {
  FakePinLockController() : super();

  @override
  bool get isLocked => false;

  @override
  bool get isPinEnabled => false;

  @override
  bool get isInitialized => true;

  @override
  bool get isPinScreenOpen => false;

  @override
  set isPinScreenOpen(bool value) {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshPinStatus() async {}

  @override
  void unlock() {}

  @override
  void lock() {}

  @override
  Future<void> enablePin(String rawPin) async {}

  @override
  Future<void> disablePin() async {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}
}
