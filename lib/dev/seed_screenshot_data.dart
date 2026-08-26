import 'package:drift/drift.dart';
import '../src/data/local/wallet_melt_database.dart';
import '../src/types/settings.dart';
import '../src/services/settings/settings_service.dart';

/// Fixed, deterministic mock data seed for WalletMelt publication screenshots.
/// Inserts fixed rows into Drift and settings when SCREENSHOT_MODE is active.
Future<void> seedScreenshotData(WalletMeltDatabase db, SettingsService settingsService) async {
  final dateStr = '2026-08-26';
  final currentMonth = '2026-08';

  // 1. Settings
  await settingsService.save(const WalletMeltSettings(
    currency: 'PKR',
    monthlyBudgetAmount: 150000.0,
    hasCompletedOnboarding: true,
    hasAcceptedPrivacyPolicy: true,
    themePreference: ThemePreference.dark,
  ));

  // 2. Categories
  final fixedCategories = [
    CategoriesCompanion.insert(
      id: 'grocery',
      name: 'Grocery',
      icon: 'shopping_basket',
      color: '#8FD6B5',
      isDefault: true,
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoriesCompanion.insert(
      id: 'fuel',
      name: 'Fuel & Commute',
      icon: 'local_gas_station',
      color: '#E85D75',
      isDefault: true,
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoriesCompanion.insert(
      id: 'electricity',
      name: 'Electricity',
      icon: 'bolt',
      color: '#F4D35E',
      isDefault: true,
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoriesCompanion.insert(
      id: 'housing',
      name: 'Housing & Rent',
      icon: 'home',
      color: '#6C63FF',
      isDefault: true,
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoriesCompanion.insert(
      id: 'internet',
      name: 'Internet & Tech',
      icon: 'wifi',
      color: '#4D96FF',
      isDefault: true,
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoriesCompanion.insert(
      id: 'dining',
      name: 'Dining & Leisure',
      icon: 'restaurant',
      color: '#FF9F45',
      isDefault: true,
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoriesCompanion.insert(
      id: 'health',
      name: 'Health & Medical',
      icon: 'medical_services',
      color: '#FF6B6B',
      isDefault: true,
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
  ];

  for (final cat in fixedCategories) {
    await db.into(db.categories).insertOnConflictUpdate(cat);
  }

  // 3. Category Budgets
  final fixedBudgets = [
    CategoryBudgetsCompanion.insert(
      id: 'bg-1',
      categoryId: 'grocery',
      month: currentMonth,
      amount: 45000.0,
      currency: 'PKR',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoryBudgetsCompanion.insert(
      id: 'bg-2',
      categoryId: 'fuel',
      month: currentMonth,
      amount: 25000.0,
      currency: 'PKR',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoryBudgetsCompanion.insert(
      id: 'bg-3',
      categoryId: 'electricity',
      month: currentMonth,
      amount: 20000.0,
      currency: 'PKR',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoryBudgetsCompanion.insert(
      id: 'bg-4',
      categoryId: 'housing',
      month: currentMonth,
      amount: 35000.0,
      currency: 'PKR',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoryBudgetsCompanion.insert(
      id: 'bg-5',
      categoryId: 'internet',
      month: currentMonth,
      amount: 10000.0,
      currency: 'PKR',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    CategoryBudgetsCompanion.insert(
      id: 'bg-6',
      categoryId: 'dining',
      month: currentMonth,
      amount: 15000.0,
      currency: 'PKR',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
  ];

  for (final b in fixedBudgets) {
    await db.into(db.categoryBudgets).insertOnConflictUpdate(b);
  }

  // 4. Expenses
  final fixedExpenses = [
    ExpensesCompanion.insert(
      id: 'exp-1',
      title: 'Weekly Grocery Stockup',
      amount: 14250.0,
      currency: 'PKR',
      categoryId: 'grocery',
      vendor: const Value('Imtiaz Super Market'),
      date: '2026-08-25T14:30:00.000Z',
      notes: const Value('Weekly fruits, vegetables, dairy, and household essentials.'),
      receiptImageUri: const Value('sample_receipt.png'),
      createdAt: '2026-08-25T14:30:00.000Z',
      updatedAt: '2026-08-25T14:30:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-2',
      title: 'Fuel Fill-Up (Hi-Octane)',
      amount: 6800.0,
      currency: 'PKR',
      categoryId: 'fuel',
      vendor: const Value('Shell Fuel Station'),
      date: '2026-08-24T09:15:00.000Z',
      notes: const Value('Full tank fill up - 24.5 Litres'),
      createdAt: '2026-08-24T09:15:00.000Z',
      updatedAt: '2026-08-24T09:15:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-3',
      title: 'Team Dinner & Dessert',
      amount: 5400.0,
      currency: 'PKR',
      categoryId: 'dining',
      vendor: const Value('Monal Restaurant'),
      date: '2026-08-22T20:45:00.000Z',
      notes: const Value('Celebration dinner with engineering leads.'),
      createdAt: '2026-08-22T20:45:00.000Z',
      updatedAt: '2026-08-22T20:45:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-4',
      title: 'Weekend Cafe Meeting',
      amount: 6800.0,
      currency: 'PKR',
      categoryId: 'dining',
      vendor: const Value('Roast Coffee House'),
      date: '2026-08-20T16:00:00.000Z',
      notes: const Value('Specialty coffee & bakery brunch.'),
      createdAt: '2026-08-20T16:00:00.000Z',
      updatedAt: '2026-08-20T16:00:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-5',
      title: 'Pantry Restock & Organic Honey',
      amount: 10250.0,
      currency: 'PKR',
      categoryId: 'grocery',
      vendor: const Value('Al-Fatah Market'),
      date: '2026-08-18T18:20:00.000Z',
      notes: const Value('Dry groceries and olive oil.'),
      createdAt: '2026-08-18T18:20:00.000Z',
      updatedAt: '2026-08-18T18:20:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-6',
      title: 'Electricity Utility Bill',
      amount: 18200.0,
      currency: 'PKR',
      categoryId: 'electricity',
      vendor: const Value('K-Electric'),
      date: '2026-08-15T11:00:00.000Z',
      notes: const Value('Paid via online banking portal.'),
      createdAt: '2026-08-15T11:00:00.000Z',
      updatedAt: '2026-08-15T11:00:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-7',
      title: 'Mid-Month Fuel Refill',
      amount: 10000.0,
      currency: 'PKR',
      categoryId: 'fuel',
      vendor: const Value('Total Parco'),
      date: '2026-08-12T08:30:00.000Z',
      createdAt: '2026-08-12T08:30:00.000Z',
      updatedAt: '2026-08-12T08:30:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-8',
      title: 'Fiber 100Mbps Broadband',
      amount: 4500.0,
      currency: 'PKR',
      categoryId: 'internet',
      vendor: const Value('StormFiber'),
      date: '2026-08-10T12:00:00.000Z',
      createdAt: '2026-08-10T12:00:00.000Z',
      updatedAt: '2026-08-10T12:00:00.000Z',
    ),
    ExpensesCompanion.insert(
      id: 'exp-9',
      title: 'Pharmacy & Vitamin Supplements',
      amount: 3200.0,
      currency: 'PKR',
      categoryId: 'health',
      vendor: const Value('Servaid Pharmacy'),
      date: '2026-08-08T15:45:00.000Z',
      createdAt: '2026-08-08T15:45:00.000Z',
      updatedAt: '2026-08-08T15:45:00.000Z',
    ),
  ];

  for (final e in fixedExpenses) {
    await db.into(db.expenses).insertOnConflictUpdate(e);
  }

  // 5. Debts
  final fixedDebts = [
    DebtRecordsCompanion.insert(
      id: 'debt-1',
      personName: 'Ahmed Khan',
      type: 'owedToMe',
      principalAmount: 75000.0,
      remainingAmount: 75000.0,
      currency: 'PKR',
      dueDate: const Value('2026-09-15'),
      notes: const Value('Final milestone payout upon app deployment.'),
      status: 'active',
      createdAt: dateStr,
    ),
    DebtRecordsCompanion.insert(
      id: 'debt-2',
      personName: 'Usman Tariq',
      type: 'iOwe',
      principalAmount: 30000.0,
      remainingAmount: 15000.0,
      currency: 'PKR',
      dueDate: const Value('2026-09-01'),
      notes: const Value('Half payment completed on Aug 15.'),
      status: 'active',
      createdAt: dateStr,
    ),
  ];

  for (final d in fixedDebts) {
    await db.into(db.debtRecords).insertOnConflictUpdate(d);
  }

  // 6. Subscriptions
  final fixedSubscriptions = [
    SubscriptionsCompanion.insert(
      id: 'sub-1',
      name: 'Netflix 4K Ultra HD',
      amount: 1100.0,
      currency: 'PKR',
      billingCycle: 'monthly',
      categoryId: 'internet',
      startDate: '2026-01-01',
      nextOccurrenceDate: '2026-09-01',
      status: 'active',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    SubscriptionsCompanion.insert(
      id: 'sub-2',
      name: 'Spotify Family Plan',
      amount: 479.0,
      currency: 'PKR',
      billingCycle: 'monthly',
      categoryId: 'internet',
      startDate: '2026-01-01',
      nextOccurrenceDate: '2026-09-05',
      status: 'active',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
    SubscriptionsCompanion.insert(
      id: 'sub-3',
      name: 'GitHub Copilot Business',
      amount: 2800.0,
      currency: 'PKR',
      billingCycle: 'monthly',
      categoryId: 'internet',
      startDate: '2026-01-01',
      nextOccurrenceDate: '2026-09-12',
      status: 'active',
      createdAt: dateStr,
      updatedAt: dateStr,
    ),
  ];

  for (final s in fixedSubscriptions) {
    await db.into(db.subscriptions).insertOnConflictUpdate(s);
  }
}