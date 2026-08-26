import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_debt_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_essential_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_fuel_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_grocery_template_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_payee_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_store_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_subscription_repository.dart';
import 'package:wallet_melt/src/security/pin_lock_controller.dart';
import 'package:wallet_melt/src/services/receipt_storage/receipt_storage_service.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/debt.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/fuel.dart' as wm_fuel;
import 'package:wallet_melt/src/types/grocery_template.dart' as wm_template;
import 'package:wallet_melt/src/types/merchant.dart';
import 'package:wallet_melt/src/types/payee.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/types/subscription.dart';

class DemoDataBundle {
  final AppState darkAppState;
  final AppState lightAppState;
  final PinLockController pinLockController;
  final String sampleReceiptPath;
  final List<Expense> expenses;
  final List<wm.Category> categories;
  final List<CategoryBudget> budgets;
  final List<DebtRecord> debts;
  final List<Subscription> subscriptions;
  final List<EssentialExpenseTemplate> essentials;
  final List<Payee> payees;
  final List<Merchant> merchants;

  DemoDataBundle({
    required this.darkAppState,
    required this.lightAppState,
    required this.pinLockController,
    required this.sampleReceiptPath,
    required this.expenses,
    required this.categories,
    required this.budgets,
    required this.debts,
    required this.subscriptions,
    required this.essentials,
    required this.payees,
    required this.merchants,
  });
}

DemoDataBundle createDemoDataBundle({String? receiptPath}) {
  final now = DateTime(2026, 8, 26);
  final currentMonth = '2026-08';
  final sampleReceiptPath = receiptPath ?? 'sample_receipt.png';

  // 1. Categories
  final defaultCats = wm.Category(
    id: 'grocery',
    name: 'Grocery',
    icon: 'shopping_basket',
    color: '#8FD6B5',
    isDefault: true,
    createdAt: now.toIso8601String(),
    updatedAt: now.toIso8601String(),
  );

  final categories = <wm.Category>[
    defaultCats,
    wm.Category(
      id: 'fuel',
      name: 'Fuel & Commute',
      icon: 'local_gas_station',
      color: '#E85D75',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    wm.Category(
      id: 'electricity',
      name: 'Electricity',
      icon: 'bolt',
      color: '#F4B740',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    wm.Category(
      id: 'rent',
      name: 'Housing & Rent',
      icon: 'home',
      color: '#A88CC2',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    wm.Category(
      id: 'internet',
      name: 'Internet & Tech',
      icon: 'wifi',
      color: '#7EA6C8',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    wm.Category(
      id: 'gas',
      name: 'Gas',
      icon: 'local_fire_department',
      color: '#E8805D',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    wm.Category(
      id: 'water',
      name: 'Water',
      icon: 'water_drop',
      color: '#77C8D4',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    wm.Category(
      id: 'maintenance',
      name: 'Maintenance',
      icon: 'build',
      color: '#C09366',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    wm.Category(
      id: 'other',
      name: 'Dining & Leisure',
      icon: 'more_horiz',
      color: '#9A958B',
      isDefault: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
  ];

  // 2. Budgets
  final budgets = <CategoryBudget>[
    CategoryBudget(
      id: 'b-grocery',
      categoryId: 'grocery',
      amount: 35000.0,
      currency: 'PKR',
      month: currentMonth,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    CategoryBudget(
      id: 'b-other',
      categoryId: 'other',
      amount: 20000.0,
      currency: 'PKR',
      month: currentMonth,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    CategoryBudget(
      id: 'b-fuel',
      categoryId: 'fuel',
      amount: 15000.0,
      currency: 'PKR',
      month: currentMonth,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    CategoryBudget(
      id: 'b-internet',
      categoryId: 'internet',
      amount: 10000.0,
      currency: 'PKR',
      month: currentMonth,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    CategoryBudget(
      id: 'b-electricity',
      categoryId: 'electricity',
      amount: 25000.0,
      currency: 'PKR',
      month: currentMonth,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    CategoryBudget(
      id: 'b-rent',
      categoryId: 'rent',
      amount: 45000.0,
      currency: 'PKR',
      month: currentMonth,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
  ];

  // 3. Expenses
  final expenses = <Expense>[
    Expense(
      id: 'exp-1',
      amount: 14250.0,
      currency: 'PKR',
      categoryId: 'grocery',
      title: 'Weekly Grocery Stock',
      vendor: 'Imtiaz Super Market',
      date: '2026-08-24T14:30:00.000Z',
      notes: 'Monthly staples, dairy & fresh organic produce',
      receiptImageUri: Uri.file(sampleReceiptPath).toString(),
      isRecurring: false,
      createdAt: '2026-08-24T14:30:00.000Z',
      updatedAt: '2026-08-24T14:30:00.000Z',
    ),
    const Expense(
      id: 'exp-2',
      amount: 6800.0,
      currency: 'PKR',
      categoryId: 'fuel',
      title: 'Fuel Fill-Up (Hi-Octane)',
      vendor: 'Shell Fuel Station',
      date: '2026-08-23T09:15:00.000Z',
      notes: 'Full tank commute refill',
      isRecurring: false,
      createdAt: '2026-08-23T09:15:00.000Z',
      updatedAt: '2026-08-23T09:15:00.000Z',
    ),
    const Expense(
      id: 'exp-3',
      amount: 5400.0,
      currency: 'PKR',
      categoryId: 'other',
      title: 'Team Dinner & Dessert',
      vendor: 'Monal Restaurant',
      date: '2026-08-22T21:00:00.000Z',
      notes: 'Dinner with product engineering team',
      isRecurring: false,
      createdAt: '2026-08-22T21:00:00.000Z',
      updatedAt: '2026-08-22T21:00:00.000Z',
    ),
    const Expense(
      id: 'exp-4',
      amount: 45000.0,
      currency: 'PKR',
      categoryId: 'rent',
      title: 'Monthly Apartment Rent',
      vendor: 'Gulberg Heights',
      date: '2026-08-01T10:00:00.000Z',
      notes: 'August residential rent payment',
      isRecurring: true,
      createdAt: '2026-08-01T10:00:00.000Z',
      updatedAt: '2026-08-01T10:00:00.000Z',
    ),
    const Expense(
      id: 'exp-5',
      amount: 18200.0,
      currency: 'PKR',
      categoryId: 'electricity',
      title: 'Electricity Utility Bill',
      vendor: 'K-Electric',
      date: '2026-08-12T16:00:00.000Z',
      notes: 'Peak summer electricity units',
      isRecurring: true,
      createdAt: '2026-08-12T16:00:00.000Z',
      updatedAt: '2026-08-12T16:00:00.000Z',
    ),
    const Expense(
      id: 'exp-6',
      amount: 10250.0,
      currency: 'PKR',
      categoryId: 'grocery',
      title: 'Pantry Restock & Olive Oil',
      vendor: 'Al-Fatah Market',
      date: '2026-08-15T18:20:00.000Z',
      notes: 'Olive oil, cheeses, herbs',
      isRecurring: false,
      createdAt: '2026-08-15T18:20:00.000Z',
      updatedAt: '2026-08-15T18:20:00.000Z',
    ),
    const Expense(
      id: 'exp-7',
      amount: 10000.0,
      currency: 'PKR',
      categoryId: 'fuel',
      title: 'Mid-Month Fuel Refill',
      vendor: 'Total Parco',
      date: '2026-08-10T08:45:00.000Z',
      isRecurring: false,
      createdAt: '2026-08-10T08:45:00.000Z',
      updatedAt: '2026-08-10T08:45:00.000Z',
    ),
    const Expense(
      id: 'exp-8',
      amount: 3999.0,
      currency: 'PKR',
      categoryId: 'internet',
      title: 'Fiber 100Mbps Broadband',
      vendor: 'StormFiber',
      date: '2026-08-08T11:00:00.000Z',
      notes: 'High-speed fiber optic connection',
      isRecurring: true,
      createdAt: '2026-08-08T11:00:00.000Z',
      updatedAt: '2026-08-08T11:00:00.000Z',
    ),
    const Expense(
      id: 'exp-9',
      amount: 6800.0,
      currency: 'PKR',
      categoryId: 'other',
      title: 'Weekend Cafe Meetup',
      vendor: 'Roast Coffee House',
      date: '2026-08-18T17:30:00.000Z',
      notes: 'Specialty coffee & bakery',
      isRecurring: false,
      createdAt: '2026-08-18T17:30:00.000Z',
      updatedAt: '2026-08-18T17:30:00.000Z',
    ),
    const Expense(
      id: 'exp-10',
      amount: 5000.0,
      currency: 'PKR',
      categoryId: 'other',
      title: 'Family Dinner Gathering',
      vendor: 'Bundu Khan',
      date: '2026-08-05T20:45:00.000Z',
      isRecurring: false,
      createdAt: '2026-08-05T20:45:00.000Z',
      updatedAt: '2026-08-05T20:45:00.000Z',
    ),
    const Expense(
      id: 'exp-11',
      amount: 2500.0,
      currency: 'PKR',
      categoryId: 'internet',
      title: 'Cloud Backup Storage',
      vendor: 'Google One',
      date: '2026-08-03T12:00:00.000Z',
      isRecurring: true,
      createdAt: '2026-08-03T12:00:00.000Z',
      updatedAt: '2026-08-03T12:00:00.000Z',
    ),
    // Previous month (July 2026) for MoM analytics & insights
    const Expense(
      id: 'exp-p1',
      amount: 32000.0,
      currency: 'PKR',
      categoryId: 'grocery',
      title: 'July Grocery Stock',
      vendor: 'Imtiaz Super Market',
      date: '2026-07-20T12:00:00.000Z',
      isRecurring: false,
      createdAt: '2026-07-20T12:00:00.000Z',
      updatedAt: '2026-07-20T12:00:00.000Z',
    ),
    const Expense(
      id: 'exp-p2',
      amount: 45000.0,
      currency: 'PKR',
      categoryId: 'rent',
      title: 'July Rent',
      vendor: 'Gulberg Heights',
      date: '2026-07-01T10:00:00.000Z',
      isRecurring: true,
      createdAt: '2026-07-01T10:00:00.000Z',
      updatedAt: '2026-07-01T10:00:00.000Z',
    ),
    const Expense(
      id: 'exp-p3',
      amount: 14500.0,
      currency: 'PKR',
      categoryId: 'fuel',
      title: 'July Fuel',
      vendor: 'Shell Fuel Station',
      date: '2026-07-15T09:00:00.000Z',
      isRecurring: false,
      createdAt: '2026-07-15T09:00:00.000Z',
      updatedAt: '2026-07-15T09:00:00.000Z',
    ),
  ];

  // 4. Debts
  final debts = <DebtRecord>[
    DebtRecord(
      id: 'debt-1',
      personName: 'Hamza Tariq',
      principalAmount: 15000.0,
      remainingAmount: 12500.0,
      currency: 'PKR',
      type: DebtType.owedToMe,
      status: DebtStatus.partiallyPaid,
      dueDate: '2026-09-15',
      description: 'Personal Loan for Laptop Repair',
      notes: 'Agreed 2-stage repayment',
      createdAt: '2026-08-10T10:00:00.000Z',
    ),
    const DebtRecord(
      id: 'debt-2',
      personName: 'Bilal Ahmed',
      principalAmount: 8500.0,
      remainingAmount: 8500.0,
      currency: 'PKR',
      type: DebtType.owedToMe,
      status: DebtStatus.active,
      dueDate: '2026-08-30',
      description: 'Dinner Bill Split',
      notes: 'Group dinner payment share',
      createdAt: '2026-08-22T22:00:00.000Z',
    ),
    const DebtRecord(
      id: 'debt-3',
      personName: 'Zaid Khan',
      principalAmount: 5000.0,
      remainingAmount: 5000.0,
      currency: 'PKR',
      type: DebtType.iOwe,
      status: DebtStatus.active,
      dueDate: '2026-09-05',
      description: 'Tech Conference Pass Advance',
      notes: 'Online ticket booking advance',
      createdAt: '2026-08-18T14:00:00.000Z',
    ),
    const DebtRecord(
      id: 'debt-4',
      personName: 'Malik Sahib',
      principalAmount: 20000.0,
      remainingAmount: 0.0,
      currency: 'PKR',
      type: DebtType.loanGiven,
      status: DebtStatus.settled,
      dueDate: '2026-07-30',
      settledAt: '2026-07-30T10:00:00.000Z',
      description: 'Apartment Maintenance Advance',
      notes: 'Fully settled & adjusted',
      createdAt: '2026-07-01T10:00:00.000Z',
    ),
  ];

  // 5. Subscriptions
  final subscriptions = <Subscription>[
    const Subscription(
      id: 'sub-1',
      name: 'Netflix Premium 4K',
      amount: 1500.0,
      currency: 'PKR',
      categoryId: 'other',
      billingCycle: 'monthly',
      startDate: '2026-01-01T00:00:00.000Z',
      nextOccurrenceDate: '2026-09-01T00:00:00.000Z',
      status: SubscriptionStatus.active,
      description: 'Family Ultra HD 4-Screen Plan',
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-08-01T00:00:00.000Z',
    ),
    const Subscription(
      id: 'sub-2',
      name: 'StormFiber 100Mbps',
      amount: 3999.0,
      currency: 'PKR',
      categoryId: 'internet',
      billingCycle: 'monthly',
      startDate: '2026-01-08T00:00:00.000Z',
      nextOccurrenceDate: '2026-09-08T00:00:00.000Z',
      status: SubscriptionStatus.active,
      description: 'Dedicated home office internet',
      createdAt: '2026-01-08T00:00:00.000Z',
      updatedAt: '2026-08-08T00:00:00.000Z',
    ),
    const Subscription(
      id: 'sub-3',
      name: 'FitPulse Gym Membership',
      amount: 5000.0,
      currency: 'PKR',
      categoryId: 'other',
      billingCycle: 'monthly',
      startDate: '2026-02-15T00:00:00.000Z',
      nextOccurrenceDate: '2026-09-15T00:00:00.000Z',
      status: SubscriptionStatus.active,
      description: 'Cardio & weightlifting access',
      createdAt: '2026-02-15T00:00:00.000Z',
      updatedAt: '2026-08-15T00:00:00.000Z',
    ),
    const Subscription(
      id: 'sub-4',
      name: 'Spotify Family Music',
      amount: 479.0,
      currency: 'PKR',
      categoryId: 'other',
      billingCycle: 'monthly',
      startDate: '2026-03-22T00:00:00.000Z',
      nextOccurrenceDate: '2026-09-22T00:00:00.000Z',
      status: SubscriptionStatus.active,
      description: 'Lossless audio family plan',
      createdAt: '2026-03-22T00:00:00.000Z',
      updatedAt: '2026-08-22T00:00:00.000Z',
    ),
    const Subscription(
      id: 'sub-5',
      name: 'Google One 2TB Cloud',
      amount: 1050.0,
      currency: 'PKR',
      categoryId: 'internet',
      billingCycle: 'monthly',
      startDate: '2026-04-28T00:00:00.000Z',
      nextOccurrenceDate: '2026-09-28T00:00:00.000Z',
      status: SubscriptionStatus.active,
      description: 'Encrypted device backup',
      createdAt: '2026-04-28T00:00:00.000Z',
      updatedAt: '2026-08-28T00:00:00.000Z',
    ),
  ];

  // 6. Essentials
  final essentials = <EssentialExpenseTemplate>[
    EssentialExpenseTemplate(
      id: 'ess-1',
      name: 'Apartment Rent',
      expectedAmount: 45000.0,
      categoryId: 'rent',
      frequency: 'monthly',
      isActive: true,
      isFuel: false,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    EssentialExpenseTemplate(
      id: 'ess-2',
      name: 'Monthly Grocery Staples',
      expectedAmount: 25000.0,
      categoryId: 'grocery',
      frequency: 'monthly',
      isActive: true,
      isFuel: false,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    EssentialExpenseTemplate(
      id: 'ess-3',
      name: 'Electricity & Utilities',
      expectedAmount: 18000.0,
      categoryId: 'electricity',
      frequency: 'monthly',
      isActive: true,
      isFuel: false,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    EssentialExpenseTemplate(
      id: 'ess-4',
      name: 'Commute Fuel & Transport',
      expectedAmount: 12000.0,
      categoryId: 'fuel',
      frequency: 'monthly',
      isActive: true,
      isFuel: false,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    EssentialExpenseTemplate(
      id: 'ess-5',
      name: 'Broadband Fiber Internet',
      expectedAmount: 4000.0,
      categoryId: 'internet',
      frequency: 'monthly',
      isActive: true,
      isFuel: false,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
  ];

  // 7. Payees (Sanitized fictional numbers)
  final payees = <Payee>[
    Payee(
      id: 'payee-1',
      name: 'Hamza Tariq',
      phone: '+92 300 000 0001',
      notes: 'Colleague & Friend',
      isActive: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Payee(
      id: 'payee-2',
      name: 'Bilal Ahmed',
      phone: '+92 300 000 0002',
      notes: 'College Friend',
      isActive: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Payee(
      id: 'payee-3',
      name: 'Zaid Khan',
      phone: '+92 300 000 0003',
      notes: 'Tech Lead',
      isActive: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Payee(
      id: 'payee-4',
      name: 'Malik Sahib',
      phone: '+92 300 000 0004',
      notes: 'Property Manager',
      isActive: true,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
  ];

  // 8. Saved Merchants
  final merchants = <Merchant>[
    Merchant(
      id: 'merch-1',
      name: 'Imtiaz Super Market',
      normalizedName: 'imtiaz super market',
      defaultCategoryId: 'grocery',
      isSaved: true,
      isFavorite: true,
      notes: 'Primary supermarket',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Merchant(
      id: 'merch-2',
      name: 'Shell Fuel Station',
      normalizedName: 'shell fuel station',
      defaultCategoryId: 'fuel',
      isSaved: true,
      isFavorite: true,
      notes: 'Hi-Octane fuel station',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Merchant(
      id: 'merch-3',
      name: 'Monal Restaurant',
      normalizedName: 'monal restaurant',
      defaultCategoryId: 'other',
      isSaved: true,
      isFavorite: true,
      notes: 'Fine dining',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Merchant(
      id: 'merch-4',
      name: 'StormFiber',
      normalizedName: 'stormfiber',
      defaultCategoryId: 'internet',
      isSaved: true,
      isFavorite: false,
      notes: 'Internet service provider',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Merchant(
      id: 'merch-5',
      name: 'Al-Fatah Market',
      normalizedName: 'al-fatah market',
      defaultCategoryId: 'grocery',
      isSaved: true,
      isFavorite: false,
      notes: 'Pantry imports',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
    Merchant(
      id: 'merch-6',
      name: 'Bundu Khan',
      normalizedName: 'bundu khan',
      defaultCategoryId: 'other',
      isSaved: true,
      isFavorite: false,
      notes: 'Traditional BBQ',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    ),
  ];

  final darkSettings = WalletMeltSettings.defaults.copyWith(
    currency: 'PKR',
    monthlyBudgetAmount: 150000.0,
    themePreference: ThemePreference.dark,
    hasCompletedOnboarding: true,
    hasAcceptedPrivacyPolicy: true,
  );

  final lightSettings = WalletMeltSettings.defaults.copyWith(
    currency: 'PKR',
    monthlyBudgetAmount: 150000.0,
    themePreference: ThemePreference.light,
    hasCompletedOnboarding: true,
    hasAcceptedPrivacyPolicy: true,
  );

  final darkState = AppState.test(
    driftCategoryRepository: _FakeCategoryRepository(categories),
    driftExpenseRepository: _FakeExpenseRepository(expenses),
    driftBudgetRepository: _FakeBudgetRepository(budgets),
    driftDebtRepository: _FakeDebtRepository(debts),
    driftGroceryTemplateRepository: _FakeGroceryTemplateRepository(),
    driftSubscriptionRepository: _FakeSubscriptionRepository(subscriptions),
    driftPayeeRepository: _FakePayeeRepository(payees),
    driftEssentialExpenseRepository: _FakeEssentialRepository(essentials),
    driftFuelRepository: _FakeFuelRepository(),
    driftStoreRepository: _FakeStoreRepository(merchants),
    settingsService: _FakeSettingsService(darkSettings),
    receiptStorageService: _FakeReceiptStorageService(),
    settings: darkSettings,
  );
  darkState.categories = categories;
  darkState.expenses = expenses;
  darkState.currentBudgets = budgets;
  darkState.debts = debts;
  darkState.subscriptions = subscriptions;
  darkState.essentialTemplates = essentials;
  darkState.payees = payees;
  darkState.savedMerchants = merchants;
  darkState.selectedMonth = DateTime(2026, 8);
  darkState.isLoading = false;

  final lightState = AppState.test(
    driftCategoryRepository: _FakeCategoryRepository(categories),
    driftExpenseRepository: _FakeExpenseRepository(expenses),
    driftBudgetRepository: _FakeBudgetRepository(budgets),
    driftDebtRepository: _FakeDebtRepository(debts),
    driftGroceryTemplateRepository: _FakeGroceryTemplateRepository(),
    driftSubscriptionRepository: _FakeSubscriptionRepository(subscriptions),
    driftPayeeRepository: _FakePayeeRepository(payees),
    driftEssentialExpenseRepository: _FakeEssentialRepository(essentials),
    driftFuelRepository: _FakeFuelRepository(),
    driftStoreRepository: _FakeStoreRepository(merchants),
    settingsService: _FakeSettingsService(lightSettings),
    receiptStorageService: _FakeReceiptStorageService(),
    settings: lightSettings,
  );
  lightState.categories = categories;
  lightState.expenses = expenses;
  lightState.currentBudgets = budgets;
  lightState.debts = debts;
  lightState.subscriptions = subscriptions;
  lightState.essentialTemplates = essentials;
  lightState.payees = payees;
  lightState.savedMerchants = merchants;
  lightState.selectedMonth = DateTime(2026, 8);
  lightState.isLoading = false;

  final pinLockController = _FakePinLockController();

  return DemoDataBundle(
    darkAppState: darkState,
    lightAppState: lightState,
    pinLockController: pinLockController,
    sampleReceiptPath: sampleReceiptPath,
    expenses: expenses,
    categories: categories,
    budgets: budgets,
    debts: debts,
    subscriptions: subscriptions,
    essentials: essentials,
    payees: payees,
    merchants: merchants,
  );
}

Future<File> createSyntheticReceiptFile() async {
  final tempDir = Directory.systemTemp.createTempSync('wm_receipt_');
  final file = File('${tempDir.path}/sample_receipt.png');

  // Copy crisp launcher asset if available or write standalone clean graphic
  final source = File('assets/brand/generated/walletmelt_app_icon_launcher.png');
  if (source.existsSync()) {
    await file.writeAsBytes(await source.readAsBytes());
  } else {
    // Valid PNG bytes fallback
    await file.writeAsBytes(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAUAAAAH0CAYAAADd8n7uAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAFFJREFUeJztwTEBAAAAwqD1T20ND6AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAcDQ10wABwG2GkAAAAABJRU5ErkJggg==',
    ));
  }
  return file;
}

// ─────────────────────────────────────────────────────────────────────────────
// FAKE IN-MEMORY REPOSITORIES & SERVICES
// ─────────────────────────────────────────────────────────────────────────────

class _FakeCategoryRepository extends Fake implements DriftCategoryRepository {
  final List<wm.Category> list;
  _FakeCategoryRepository(this.list);
  @override
  Future<List<wm.Category>> listCategories() async => list;
}

class _FakeExpenseRepository extends Fake implements DriftExpenseRepository {
  final List<Expense> list;
  _FakeExpenseRepository(this.list);
  @override
  Future<List<Expense>> listActive() async => list;
  @override
  Future<List<Expense>> listDeleted() async => const [];
}

class _FakeBudgetRepository extends Fake implements DriftBudgetRepository {
  final List<CategoryBudget> list;
  _FakeBudgetRepository(this.list);
  @override
  Future<List<CategoryBudget>> listForMonth(String month) async {
    return list.where((b) => b.month == month).toList();
  }
  @override
  Future<List<CategoryBudget>> listAll() async => list;
}

class _FakeDebtRepository extends Fake implements DriftDebtRepository {
  final List<DebtRecord> list;
  _FakeDebtRepository(this.list);
  @override
  Future<List<DebtRecord>> listAll() async => list;
}

class _FakeGroceryTemplateRepository extends Fake implements DriftGroceryTemplateRepository {
  @override
  Future<List<wm_template.GroceryTemplate>> listAll() async => const [];
}

class _FakeSubscriptionRepository extends Fake implements DriftSubscriptionRepository {
  final List<Subscription> list;
  _FakeSubscriptionRepository(this.list);
  @override
  Future<List<Subscription>> listAll() async => list;
}

class _FakePayeeRepository extends Fake implements DriftPayeeRepository {
  final List<Payee> list;
  _FakePayeeRepository(this.list);
  @override
  Future<List<Payee>> listAll() async => list;
}

class _FakeEssentialRepository extends Fake implements DriftEssentialExpenseRepository {
  final List<EssentialExpenseTemplate> list;
  _FakeEssentialRepository(this.list);
  @override
  Future<List<EssentialExpenseTemplate>> listAll({bool includeInactive = false, bool includeDeleted = false}) async => list;
}

class _FakeFuelRepository extends Fake implements DriftFuelRepository {
  @override
  Future<wm_fuel.FuelTransaction?> getByExpenseId(String expenseId) async => null;
  @override
  Future<List<wm_fuel.FuelTransaction>> listAll() async => const [];
}

class _FakeStoreRepository extends Fake implements DriftStoreRepository {
  final List<Merchant> list;
  _FakeStoreRepository(this.list);
  @override
  Future<List<Merchant>> listSavedMerchants() async => list;
  @override
  Future<List<Merchant>> getSuggestions({String? query, int limit = 8}) async => list;
}

class _FakePinLockController extends PinLockController {
  _FakePinLockController() : super();

  @override
  bool get isLocked => false;

  @override
  bool get isPinEnabled => true;

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

class _FakeSettingsService extends SettingsService {
  WalletMeltSettings saved;
  _FakeSettingsService(this.saved);
  @override
  Future<WalletMeltSettings> load() async => saved;
  @override
  Future<void> save(WalletMeltSettings s) async {
    saved = s;
  }
}

class _FakeReceiptStorageService implements ReceiptStorageService {
  @override
  Future<String?> pickFromGallery() async => null;
  @override
  Future<String?> captureWithCamera() async => null;
  @override
  Future<bool> exists(String uri) async => true;
  @override
  Future<void> delete(String uri) async {}
}
