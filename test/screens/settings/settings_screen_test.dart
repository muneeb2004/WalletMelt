import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/data/repositories/budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/category_repository.dart';
import 'package:wallet_melt/src/data/repositories/expense_repository.dart';
import 'package:wallet_melt/src/screens/settings/settings_screen.dart';
import 'package:wallet_melt/src/services/export/expense_csv_export_service.dart';
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/services/export/export_share_service.dart';
import 'package:wallet_melt/src/services/export/file_picker_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_import_validation_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_preview_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_service.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('SettingsScreen CSV export', () {
    testWidgets('shows export action', (tester) async {
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

      await tester.tap(find.text('Include deleted expenses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();

      expect(exportService.lastIncludeDeleted, isTrue);
      expect(exportService.lastExpenses.map((expense) => expense.id),
          ['active', 'deleted']);
      expect(find.textContaining('1 active, 1 deleted'), findsOneWidget);
    });

    testWidgets('handles empty expense list gracefully', (tester) async {
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

      await tester.tap(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();

      expect(exportService.exportCalled, isTrue);
      expect(exportService.lastExpenses, isEmpty);
      expect(shareService.shareCalled, isTrue);
    });

    testWidgets('creates JSON backup with active and deleted expenses',
        (tester) async {
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
      expect(find.textContaining('Backup file is valid!'), findsOneWidget);
      expect(
          find.textContaining(
              'Found: 5 expenses, 3 items, 2 categories, 1 budgets.'),
          findsOneWidget);
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
      await tester.pumpAndSettle();

      expect(find.text('Backup Preview'), findsOneWidget);
      expect(find.text('Format Version'), findsOneWidget);
      expect(find.text('0.1.1'), findsOneWidget);
      expect(find.text('5 (1 deleted)'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('2 categories'), findsOneWidget);
      expect(find.text('1 budgets'), findsOneWidget);
      expect(find.text('Receipt warning example'), findsOneWidget);

      // Close preview
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Backup Preview'), findsNothing);
    });

    testWidgets('does not show preview dialog when an invalid backup is selected',
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
}) {
  return ChangeNotifierProvider.value(
    value: appState,
    child: MaterialApp(
      home: SettingsScreen(
        expenseCsvExportService: exportService,
        jsonBackupService: jsonBackupService,
        exportShareService: shareService,
        filePickerService: filePickerService,
        importValidationService: importValidationService,
        previewService: previewService,
      ),
    ),
  );
}

AppState _appState({
  FakeExpenseRepository? expenseRepository,
  FakeBudgetRepository? budgetRepository,
}) {
  final state = AppState.test(
    categoryRepository: FakeCategoryRepository(),
    expenseRepository: expenseRepository ?? FakeExpenseRepository(),
    budgetRepository: budgetRepository ?? FakeBudgetRepository(),
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

class FakeCategoryRepository extends Fake implements CategoryRepository {}

class FakeExpenseRepository extends Fake implements ExpenseRepository {
  List<GroceryItem> groceryItems = const [];

  @override
  Future<List<GroceryItem>> listAllGroceryItems() async => groceryItems;
}

class FakeBudgetRepository extends Fake implements BudgetRepository {
  List<CategoryBudget> budgets = const [];

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

  @override
  Future<String?> pickJsonFileContent() async {
    pickCalled = true;
    return resultText;
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
