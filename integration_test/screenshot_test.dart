import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wallet_melt/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture WalletMelt Publication Screenshots', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // ── 01. DASHBOARD ──────────────────────────────────────────
    await binding.takeScreenshot('01_dashboard/01_dashboard_overview_dark');
    await tester.pump(const Duration(milliseconds: 300));

    // Scroll Recent Activity
    final dashboardScroll = find.byType(Scrollable);
    if (dashboardScroll.evaluate().isNotEmpty) {
      await tester.drag(dashboardScroll.first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('01_dashboard/04_dashboard_scrolled_activity');
      await tester.drag(dashboardScroll.first, const Offset(0, 400));
      await tester.pumpAndSettle();
    }

    // ── 02. EXPENSES HISTORY ───────────────────────────────────
    final historyTab = find.byIcon(Icons.receipt_long_rounded);
    if (historyTab.evaluate().isNotEmpty) {
      await tester.tap(historyTab);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02_expenses/02_expenses_history_all');

      // Filter
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'Grocery');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('02_expenses/03_expenses_history_filtered');
        await tester.enterText(searchField.first, '');
        await tester.pumpAndSettle();
      }

      // Tap first expense to see detail
      final expenseItem = find.text('Weekly Grocery Stockup');
      if (expenseItem.evaluate().isNotEmpty) {
        await tester.tap(expenseItem.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('02_expenses/04_expense_detail');

        final backButton = find.byIcon(Icons.arrow_back_rounded);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }
    }

    // ── 03. PLANNING / BUDGETS ─────────────────────────────────
    final planningTab = find.byIcon(Icons.account_balance_wallet_rounded);
    if (planningTab.evaluate().isNotEmpty) {
      await tester.tap(planningTab);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('03_budgets/01_budgets_overview');

      final planningScroll = find.byType(Scrollable);
      if (planningScroll.evaluate().isNotEmpty) {
        await tester.drag(planningScroll.first, const Offset(0, -350));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('03_budgets/02_budgets_category_breakdown');
      }
    }

    // ── 05. DEBTS ──────────────────────────────────────────────
    final debtsTab = find.byIcon(Icons.handshake_rounded);
    if (debtsTab.evaluate().isNotEmpty) {
      await tester.tap(debtsTab);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('05_debts/01_debts_overview');
    }

    // ── RETURN HOME FOR QUICK ACTIONS ──────────────────────────
    final homeTab = find.byIcon(Icons.home_filled);
    if (homeTab.evaluate().isNotEmpty) {
      await tester.tap(homeTab);
      await tester.pumpAndSettle();
    }

    // Add Expense Modal
    final addExpenseBtn = find.text('Add Expense');
    if (addExpenseBtn.evaluate().isNotEmpty) {
      await tester.tap(addExpenseBtn.first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02_expenses/01_add_expense_form');

      final closeBtn = find.byIcon(Icons.close_rounded);
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first);
        await tester.pumpAndSettle();
      }
    }

    // Fuel Quick Action
    final fuelBtn = find.text('Fuel Refill');
    if (fuelBtn.evaluate().isNotEmpty) {
      await tester.tap(fuelBtn.first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('04_fuel/01_fuel_overview');

      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await tester.pumpAndSettle();
      }
    }

    // Groceries Quick Action
    final groceriesBtn = find.text('Groceries');
    if (groceriesBtn.evaluate().isNotEmpty) {
      await tester.tap(groceriesBtn.first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('06_grocery/01_grocery_overview');

      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await tester.pumpAndSettle();
      }
    }

    // Insights Quick Action
    final insightsBtn = find.text('Insights');
    if (insightsBtn.evaluate().isNotEmpty) {
      await tester.tap(insightsBtn.first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('07_insights/01_insights_overview_charts');

      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await tester.pumpAndSettle();
      }
    }

    // ── 08. SETTINGS ───────────────────────────────────────────
    final settingsBtn = find.byIcon(Icons.settings_outlined);
    if (settingsBtn.evaluate().isNotEmpty) {
      await tester.tap(settingsBtn.first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('08_settings/01_settings_overview');
    }
  });
}
