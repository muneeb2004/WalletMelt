import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/data/repositories/drift/drift_subscription_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/category_repository.dart';
import 'package:wallet_melt/src/data/repositories/budget_repository.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/subscription.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/budget.dart';

void main() {
  group('Subscription Model Tests', () {
    test('calculateNextRenewalDate calculates monthly cycle correctly', () {
      final sub = Subscription(
        id: 'sub-1',
        name: 'Netflix',
        categoryId: 'ent',
        amount: 1000.0,
        currency: 'PKR',
        startDate: '2026-06-20',
        nextOccurrenceDate: '2026-06-20',
        billingCycle: 'monthly',
        status: SubscriptionStatus.active,
        createdAt: '2026-06-20T00:00:00.000',
        updatedAt: '2026-06-20T00:00:00.000',
      );

      final next = sub.calculateNextRenewalDate(DateTime(2026, 6, 20));
      expect(next, DateTime(2026, 7, 20));
    });

    test('calculateNextRenewalDate calculates custom interval days correctly', () {
      final sub = Subscription(
        id: 'sub-2',
        name: 'Custom',
        categoryId: 'utilities',
        amount: 500.0,
        currency: 'PKR',
        startDate: '2026-06-20',
        nextOccurrenceDate: '2026-06-20',
        billingCycle: 'custom_45',
        status: SubscriptionStatus.active,
        createdAt: '2026-06-20T00:00:00.000',
        updatedAt: '2026-06-20T00:00:00.000',
      );

      final next = sub.calculateNextRenewalDate(DateTime(2026, 6, 20));
      expect(next, DateTime(2026, 8, 4));
    });
  });

  group('Subscription Automatic Renewal Engine Tests', () {
    test('generates expenses and advances next renewal date', () async {
      final database = local.WalletMeltDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final subRepo = DriftSubscriptionRepository(database);
      final expRepo = DriftExpenseRepository(database);

      // The categories are seeded by default in onCreate.
      final sub = Subscription(
        id: 'netflix-sub',
        name: 'Netflix',
        categoryId: 'grocery', // seeded by default
        amount: 1100.0,
        taxAmount: 198.0,
        currency: 'PKR',
        startDate: '2026-06-20',
        nextOccurrenceDate: '2026-06-20', // past date
        billingCycle: 'monthly',
        status: SubscriptionStatus.active,
        createdAt: '2026-06-20T00:00:00.000',
        updatedAt: '2026-06-20T00:00:00.000',
      );

      await subRepo.create(sub);

      // Verify setup
      final allSubs = await subRepo.listAll();
      expect(allSubs, hasLength(1));

      // Construct AppState with injected database repositories
      final appState = AppState.test(
        categoryRepository: FakeCategoryRepository(),
        expenseRepository: FakeExpenseRepository(),
        budgetRepository: FakeBudgetRepository(),
        driftExpenseRepository: expRepo,
        driftSubscriptionRepository: subRepo,
      );

      // Run renewal engine
      await appState.processSubscriptionRenewals();

      // Check subscription record was updated with next renewal date
      final updatedSubs = await subRepo.listAll();
      expect(updatedSubs, hasLength(1));
      expect(updatedSubs.first.nextOccurrenceDate, '2026-07-20');

      // Check expense was auto-generated in database
      final generatedExpenses = await expRepo.listActive();
      expect(generatedExpenses, hasLength(1));
      expect(generatedExpenses.first.title, 'Netflix (Recurring Renewal)');
      expect(generatedExpenses.first.subtotalAmount, 1100.0);
      expect(generatedExpenses.first.taxAmount, 198.0);
      expect(generatedExpenses.first.amount, 1298.0); // Grand total
    });

    test('paused subscriptions do not generate renewals', () async {
      final database = local.WalletMeltDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final subRepo = DriftSubscriptionRepository(database);
      final expRepo = DriftExpenseRepository(database);

      final sub = Subscription(
        id: 'gym-sub',
        name: 'Gym Membership',
        categoryId: 'grocery',
        amount: 2000.0,
        currency: 'PKR',
        startDate: '2026-06-20',
        nextOccurrenceDate: '2026-06-20',
        billingCycle: 'monthly',
        status: SubscriptionStatus.paused, // PAUSED!
        createdAt: '2026-06-20T00:00:00.000',
        updatedAt: '2026-06-20T00:00:00.000',
      );

      await subRepo.create(sub);

      final appState = AppState.test(
        categoryRepository: FakeCategoryRepository(),
        expenseRepository: FakeExpenseRepository(),
        budgetRepository: FakeBudgetRepository(),
        driftExpenseRepository: expRepo,
        driftSubscriptionRepository: subRepo,
      );

      await appState.processSubscriptionRenewals();

      // Check subscription next renewal date remains unchanged
      final updatedSubs = await subRepo.listAll();
      expect(updatedSubs.first.nextOccurrenceDate, '2026-06-20');

      // Check no expenses were generated
      final generatedExpenses = await expRepo.listActive();
      expect(generatedExpenses, isEmpty);
    });
  });
}

// Minimal Fakes for test construction
class FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> listCategories() async => [];
  @override
  Future<Category> createCustom({required String name, required String icon, required String color}) async {
    return Category(id: 'c', name: name, icon: icon, color: color, isDefault: false, createdAt: '', updatedAt: '');
  }
}

class FakeExpenseRepository extends Fake implements ExpenseRepository {
  @override
  Future<List<Expense>> listActive() async => [];
  @override
  Future<List<Expense>> listDeleted() async => [];
  @override
  Future<List<GroceryItem>> groceryItemsForExpense(String expenseId) async => [];
  @override
  Future<List<GroceryItem>> listAllGroceryItemsForExport() async => [];
  @override
  Future<void> permanentlyDelete(String id) async {}
  @override
  Future<void> softDelete(String id) async {}
  @override
  Future<void> restore(String id) async {}
  @override
  Future<Expense> create(ExpenseDraft draft) async {
    return Expense(id: 'e', amount: draft.amount, currency: draft.currency, categoryId: draft.categoryId, title: draft.title, date: draft.date.toIso8601String(), isRecurring: false, createdAt: '', updatedAt: '');
  }
  @override
  Future<void> update(Expense expense, {List<GroceryItemDraft>? groceryItems}) async {}
}

class FakeBudgetRepository extends Fake implements BudgetRepository {
  @override
  Future<List<CategoryBudget>> listForMonth(String month) async => [];
  @override
  Future<void> upsert({required String categoryId, required double amount, required String currency, required String month}) async {}
  @override
  Future<void> delete(String categoryId, String month) async {}
}
