import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_encoder.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_validator.dart';
import 'package:wallet_melt/src/data/repositories/category_repository.dart';
import 'package:wallet_melt/src/data/repositories/expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/budget_repository.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_dry_run_planner.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_conflict_service.dart';
import 'package:wallet_melt/src/services/export/export_file_writer.dart';

void main() {
  group('Monthly Budget Config & AppState Logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to null monthly budget', () {
      final settings = WalletMeltSettings.defaults;
      expect(settings.monthlyBudgetAmount, isNull);
    });

    test('copyWith updates and clears monthly budget', () {
      var settings = WalletMeltSettings.defaults;
      settings = settings.copyWith(monthlyBudgetAmount: 50000.0);
      expect(settings.monthlyBudgetAmount, 50000.0);

      settings = settings.copyWith(clearMonthlyBudget: true);
      expect(settings.monthlyBudgetAmount, isNull);
    });

    test('SettingsService loads and saves monthlyBudgetAmount', () async {
      final service = SettingsService();
      var settings = await service.load();
      expect(settings.monthlyBudgetAmount, isNull);

      settings = settings.copyWith(monthlyBudgetAmount: 75000.0);
      await service.save(settings);

      final loaded = await service.load();
      expect(loaded.monthlyBudgetAmount, 75000.0);
    });

    test('AppState monthly budget getter, setter and clearers work', () async {
      final appState = AppState();
      expect(appState.getMonthlyBudgetAmount(), isNull);

      await appState.setMonthlyBudgetAmount(100000.0);
      expect(appState.getMonthlyBudgetAmount(), 100000.0);

      await appState.clearMonthlyBudgetAmount();
      expect(appState.getMonthlyBudgetAmount(), isNull);
    });

    test('AppState spent and remaining math filters current month correctly',
        () {
      final appState = AppState.test(
        categoryRepository: FakeCategoryRepo(),
        expenseRepository: FakeExpenseRepo(),
        budgetRepository: FakeBudgetRepo(),
      );

      appState.selectedMonth = DateTime(2026, 6);
      appState.expenses = [
        const Expense(
          id: '1',
          amount: 2000.0,
          currency: 'PKR',
          categoryId: 'grocery',
          title: 'Grocery 1',
          date: '2026-06-15T00:00:00.000',
          isRecurring: false,
          createdAt: '',
          updatedAt: '',
        ),
        const Expense(
          id: '2',
          amount: 1500.0,
          currency: 'PKR',
          categoryId: 'utilities',
          title: 'Electric Bill',
          date: '2026-06-20T00:00:00.000',
          isRecurring: false,
          createdAt: '',
          updatedAt: '',
        ),
        // Other month
        const Expense(
          id: '3',
          amount: 5000.0,
          currency: 'PKR',
          categoryId: 'grocery',
          title: 'Grocery Other Month',
          date: '2026-05-10T00:00:00.000',
          isRecurring: false,
          createdAt: '',
          updatedAt: '',
        ),
        // Deleted
        const Expense(
          id: '4',
          amount: 8000.0,
          currency: 'PKR',
          categoryId: 'grocery',
          title: 'Deleted expense',
          date: '2026-06-05T00:00:00.000',
          isRecurring: false,
          createdAt: '',
          updatedAt: '',
          deletedAt: '2026-06-19T00:00:00.000',
        ),
      ];

      expect(appState.getCurrentMonthTotalSpent(), 3500.0);

      // Remaining checks
      expect(appState.getCurrentMonthBudgetRemaining(), isNull);

      appState.settings =
          appState.settings.copyWith(monthlyBudgetAmount: 5000.0);
      expect(appState.getCurrentMonthBudgetRemaining(), 1500.0);
    });

    test(
        'Backup format compatible extension persists and restores monthlyBudgetAmount',
        () async {
      const encoder = WalletMeltJsonBackupEncoder();
      final settings =
          WalletMeltSettings.defaults.copyWith(monthlyBudgetAmount: 60000.0);

      final json = encoder.encode(
        expenses: [],
        groceryItems: [],
        categories: [],
        budgets: [],
        settings: settings,
        exportedAt: DateTime(2026, 6, 19),
      );

      expect(json, contains('"monthly_budget_amount": 60000.0'));

      final validator = const WalletMeltJsonBackupValidator();
      final validation = validator.validate(json);
      expect(validation.isValid, isTrue);

      final db = local.WalletMeltDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final settingsService = SettingsService();
      final service = WalletMeltJsonRestoreService(
        database: db,
        settingsService: settingsService,
        validator: validator,
      );

      final planner = WalletMeltJsonRestoreDryRunPlanner(validator: validator);
      final dryRunPlan = planner.plan(
        jsonText: json,
        localSnapshot: const LocalAppSnapshot(
          expenses: [],
          deletedExpenses: [],
          categories: [],
          budgets: [],
          groceryItems: [],
          settings: null,
        ),
        conflictSummary: const BackupConflictSummary(),
        previewGenerated: true,
        settingsImportSelected: true,
      );

      final tempDir =
          await Directory.systemTemp.createTemp('walletmelt_test_restore_');
      addTearDown(() => tempDir.delete(recursive: true));
      final safetyFile = File('${tempDir.path}/safety_backup.json');
      await safetyFile.writeAsString('{}');

      final restoredResult = await service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: dryRunPlan,
        options: const WalletMeltJsonRestoreOptions(
          confirmed: true,
          importSettings: true,
        ),
        safetyBackup: ExportFileResult(
          path: safetyFile.path,
          fileName: 'safety_backup.json',
          mimeType: 'application/json',
          byteCount: 2,
          createdAt: DateTime(2026, 6, 19),
        ),
      );

      expect(restoredResult.success, isTrue,
          reason: restoredResult.errorMessage);
      final loadedSettings = await settingsService.load();
      expect(loadedSettings.monthlyBudgetAmount, 60000.0);
    });
  });
}

// Minimal fakes to instantiate AppState.test
class FakeCategoryRepo extends Fake implements CategoryRepository {}

class FakeExpenseRepo extends Fake implements ExpenseRepository {}

class FakeBudgetRepo extends Fake implements BudgetRepository {}
