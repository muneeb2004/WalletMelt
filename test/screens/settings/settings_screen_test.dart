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
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('SettingsScreen CSV export', () {
    testWidgets('shows export action', (tester) async {
      await tester.pumpWidget(
        _settingsHarness(
          appState: _appState(),
          exportService: FakeExpenseCsvExportService(),
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
          shareService: shareService,
        ),
      );

      await tester.tap(find.text('Export expenses CSV'));
      await tester.pumpAndSettle();

      expect(exportService.exportCalled, isTrue);
      expect(exportService.lastExpenses, isEmpty);
      expect(shareService.shareCalled, isTrue);
    });
  });
}

Widget _settingsHarness({
  required AppState appState,
  required ExpenseCsvExportService exportService,
  required ExportShareService shareService,
}) {
  return ChangeNotifierProvider.value(
    value: appState,
    child: MaterialApp(
      home: SettingsScreen(
        expenseCsvExportService: exportService,
        exportShareService: shareService,
      ),
    ),
  );
}

AppState _appState() {
  final state = AppState.test(
    categoryRepository: FakeCategoryRepository(),
    expenseRepository: FakeExpenseRepository(),
    budgetRepository: FakeBudgetRepository(),
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

class FakeCategoryRepository extends Fake implements CategoryRepository {}

class FakeExpenseRepository extends Fake implements ExpenseRepository {}

class FakeBudgetRepository extends Fake implements BudgetRepository {}

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

class FakeExportShareService implements ExportShareService {
  bool shareCalled = false;
  ExportFileResult? lastFile;

  @override
  Future<ExportShareResult> shareFile(
    ExportFileResult file, {
    Rect? sharePositionOrigin,
  }) async {
    shareCalled = true;
    lastFile = file;
    return const ExportShareResult(
      status: ExportShareStatus.success,
      raw: 'success',
    );
  }
}
