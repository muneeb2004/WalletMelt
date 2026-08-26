import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_melt/src/screens/add_expense/add_expense_screen.dart';
import 'package:wallet_melt/src/screens/budget/budget_screen.dart';
import 'package:wallet_melt/src/screens/dashboard/dashboard_screen.dart';
import 'package:wallet_melt/src/screens/debt/debt_screen.dart';
import 'package:wallet_melt/src/screens/essentials/essential_expenses_screen.dart';
import 'package:wallet_melt/src/screens/history/expense_detail_screen.dart';
import 'package:wallet_melt/src/screens/history/history_screen.dart';
import 'package:wallet_melt/src/screens/history/receipt_viewer_screen.dart';
import 'package:wallet_melt/src/screens/insights/insights_screen.dart';
import 'package:wallet_melt/src/screens/merchant/merchants_screen.dart';
import 'package:wallet_melt/src/screens/onboarding/onboarding_screen.dart';
import 'package:wallet_melt/src/screens/payee/payees_screen.dart';
import 'package:wallet_melt/src/screens/planning/planning_screen.dart';
import 'package:wallet_melt/src/screens/privacy/privacy_policy_screen.dart';
import 'package:wallet_melt/src/screens/security/create_pin_screen.dart';
import 'package:wallet_melt/src/screens/security/pin_lock_screen.dart';
import 'package:wallet_melt/src/screens/settings/backup_restore_dialog.dart';
import 'package:wallet_melt/src/screens/settings/settings_screen.dart';
import 'package:wallet_melt/src/screens/subscription/subscription_screen.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_conflict_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_preview_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_validator.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_service.dart';

import 'screenshot_demo_data.dart';

class ScreenshotTarget {
  final String id;
  final String category;
  final String filename;
  final String relativePath;
  final String title;
  final bool isDark;
  final Widget Function(DemoDataBundle bundle) builder;
  final Future<void> Function(WidgetTester tester, DemoDataBundle bundle)? interaction;
  final bool settleGracefully;

  const ScreenshotTarget({
    required this.id,
    required this.category,
    required this.filename,
    required this.relativePath,
    required this.title,
    required this.isDark,
    required this.builder,
    this.interaction,
    this.settleGracefully = true,
  });
}

/// The complete list of publication screenshot targets across 10 categories.
/// The length of this list is the single source of truth for total screenshot count.
final List<ScreenshotTarget> screenshotTargets = [
  // ===========================================================================
  // 01. DASHBOARD
  // ===========================================================================
  ScreenshotTarget(
    id: '01_dashboard_overview_dark',
    category: '01_dashboard',
    filename: '01_dashboard_overview_dark.png',
    relativePath: '01_dashboard/01_dashboard_overview_dark.png',
    title: 'Dashboard Overview (Dark)',
    isDark: true,
    builder: (bundle) => const DashboardScreen(),
  ),
  ScreenshotTarget(
    id: '01_dashboard_overview_light',
    category: '01_dashboard',
    filename: '02_dashboard_overview_light.png',
    relativePath: '01_dashboard/02_dashboard_overview_light.png',
    title: 'Dashboard Overview (Light)',
    isDark: false,
    builder: (bundle) => const DashboardScreen(),
  ),
  ScreenshotTarget(
    id: '01_dashboard_budget_adjust_sheet',
    category: '01_dashboard',
    filename: '03_dashboard_budget_adjust_sheet.png',
    relativePath: '01_dashboard/03_dashboard_budget_adjust_sheet.png',
    title: 'Monthly Budget Adjustment Sheet',
    isDark: true,
    builder: (bundle) => const DashboardScreen(),
    interaction: (tester, bundle) async {
      final ctx = tester.element(find.byType(DashboardScreen));
      BudgetScreen.showSetBudgetSheet(
        ctx,
        bundle.darkAppState,
        bundle.darkAppState.settings.monthlyBudgetAmount,
        bundle.darkAppState.spendingSnapshot.currentTotal,
      );
    },
  ),
  ScreenshotTarget(
    id: '01_dashboard_scrolled_activity',
    category: '01_dashboard',
    filename: '04_dashboard_scrolled_activity.png',
    relativePath: '01_dashboard/04_dashboard_scrolled_activity.png',
    title: 'Dashboard Scrolled Recent Activity',
    isDark: true,
    builder: (bundle) => const DashboardScreen(),
    interaction: (tester, bundle) async {
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets, reason: 'Dashboard must contain a scrollable');
      await tester.drag(scrollable.first, const Offset(0, -450));
    },
  ),

  // ===========================================================================
  // 02. EXPENSES
  // ===========================================================================
  ScreenshotTarget(
    id: '02_expenses_add_keypad',
    category: '02_expenses',
    filename: '01_expenses_add_keypad.png',
    relativePath: '02_expenses/01_expenses_add_keypad.png',
    title: 'Add Expense Screen with Keypad',
    isDark: true,
    builder: (bundle) => const AddExpenseScreen(),
  ),
  ScreenshotTarget(
    id: '02_expenses_history_all',
    category: '02_expenses',
    filename: '02_expenses_history_all.png',
    relativePath: '02_expenses/02_expenses_history_all.png',
    title: 'All Expenses History',
    isDark: true,
    builder: (bundle) => const HistoryScreen(),
  ),
  ScreenshotTarget(
    id: '02_expenses_history_filtered',
    category: '02_expenses',
    filename: '03_expenses_history_filtered.png',
    relativePath: '02_expenses/03_expenses_history_filtered.png',
    title: 'Filtered & Searched Expenses',
    isDark: true,
    builder: (bundle) => const HistoryScreen(),
    interaction: (tester, bundle) async {
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets, reason: 'HistoryScreen must expose search input');
      await tester.enterText(textFields.first, 'Grocery');
    },
  ),
  ScreenshotTarget(
    id: '02_expenses_detail_view',
    category: '02_expenses',
    filename: '04_expenses_detail_view.png',
    relativePath: '02_expenses/04_expenses_detail_view.png',
    title: 'Expense Transaction Detail View',
    isDark: true,
    builder: (bundle) => const ExpenseDetailScreen(expenseId: 'exp-2'),
  ),
  ScreenshotTarget(
    id: '02_expenses_receipt_attached',
    category: '02_expenses',
    filename: '05_expenses_receipt_attached.png',
    relativePath: '02_expenses/05_expenses_receipt_attached.png',
    title: 'Expense Detail with Attached Receipt',
    isDark: true,
    builder: (bundle) => const ExpenseDetailScreen(expenseId: 'exp-1'),
  ),
  ScreenshotTarget(
    id: '02_expenses_receipt_viewer',
    category: '02_expenses',
    filename: '06_expenses_receipt_viewer.png',
    relativePath: '02_expenses/06_expenses_receipt_viewer.png',
    title: 'Fullscreen Receipt Viewer',
    isDark: true,
    settleGracefully: false,
    builder: (bundle) => const ReceiptViewerScreen(expenseId: 'exp-1'),
  ),

  // ===========================================================================
  // 03. BUDGETS
  // ===========================================================================
  ScreenshotTarget(
    id: '03_budgets_overview',
    category: '03_budgets',
    filename: '01_budgets_overview.png',
    relativePath: '03_budgets/01_budgets_overview.png',
    title: 'Monthly Budget & Categories Overview',
    isDark: true,
    builder: (bundle) => const PlanningScreen(),
  ),
  ScreenshotTarget(
    id: '03_budgets_category_breakdown',
    category: '03_budgets',
    filename: '02_budgets_category_breakdown.png',
    relativePath: '03_budgets/02_budgets_category_breakdown.png',
    title: 'Category Budget Breakdown',
    isDark: true,
    builder: (bundle) => const PlanningScreen(),
    interaction: (tester, bundle) async {
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets, reason: 'PlanningScreen must be scrollable');
      await tester.drag(scrollable.first, const Offset(0, -350));
    },
  ),
  ScreenshotTarget(
    id: '03_budgets_edit_sheet',
    category: '03_budgets',
    filename: '03_budgets_edit_sheet.png',
    relativePath: '03_budgets/03_budgets_edit_sheet.png',
    title: 'Set Category Budget Sheet',
    isDark: true,
    builder: (bundle) => const PlanningScreen(),
    interaction: (tester, bundle) async {
      final ctx = tester.element(find.byType(PlanningScreen));
      BudgetScreen.showSetBudgetSheet(
        ctx,
        bundle.darkAppState,
        null,
        bundle.darkAppState.spendingSnapshot.currentTotal,
      );
    },
  ),

  // ===========================================================================
  // 04. ESSENTIALS
  // ===========================================================================
  ScreenshotTarget(
    id: '04_essentials_list',
    category: '04_essentials',
    filename: '01_essentials_list.png',
    relativePath: '04_essentials/01_essentials_list.png',
    title: 'Essential Expense Templates List',
    isDark: true,
    builder: (bundle) => const EssentialExpensesScreen(),
  ),
  ScreenshotTarget(
    id: '04_essentials_add_sheet',
    category: '04_essentials',
    filename: '02_essentials_add_sheet.png',
    relativePath: '04_essentials/02_essentials_add_sheet.png',
    title: 'Add Essential Template Sheet',
    isDark: true,
    builder: (bundle) => const EssentialExpensesScreen(),
    interaction: (tester, bundle) async {
      final ctx = tester.element(find.byType(EssentialExpensesScreen));
      EssentialExpensesScreen.showAddEssentialSheet(ctx);
    },
  ),

  // ===========================================================================
  // 05. DEBTS
  // ===========================================================================
  ScreenshotTarget(
    id: '05_debts_overview',
    category: '05_debts',
    filename: '01_debts_overview.png',
    relativePath: '05_debts/01_debts_overview.png',
    title: 'Debt & Loan Ledger Overview',
    isDark: true,
    builder: (bundle) => const DebtScreen(),
  ),
  ScreenshotTarget(
    id: '05_debts_detail_sheet',
    category: '05_debts',
    filename: '02_debts_detail_sheet.png',
    relativePath: '05_debts/02_debts_detail_sheet.png',
    title: 'Debt Record Detail & Repayment History',
    isDark: true,
    builder: (bundle) => const DebtScreen(),
    interaction: (tester, bundle) async {
      final debt = bundle.darkAppState.debts.first;
      final ctx = tester.element(find.byType(DebtScreen));
      DebtScreen.showDebtDetailSheet(ctx, debt);
    },
  ),
  ScreenshotTarget(
    id: '05_debts_add_sheet',
    category: '05_debts',
    filename: '03_debts_add_sheet.png',
    relativePath: '05_debts/03_debts_add_sheet.png',
    title: 'Create New Debt or Loan Sheet',
    isDark: true,
    builder: (bundle) => const DebtScreen(),
    interaction: (tester, bundle) async {
      final ctx = tester.element(find.byType(DebtScreen));
      DebtScreen.showAddDebtSheet(ctx);
    },
  ),

  // ===========================================================================
  // 06. OBLIGATIONS / SUBSCRIPTIONS
  // ===========================================================================
  ScreenshotTarget(
    id: '06_obligations_list',
    category: '06_obligations',
    filename: '01_subscriptions_list.png',
    relativePath: '06_obligations/01_subscriptions_list.png',
    title: 'Active Subscriptions & Recurring Bills',
    isDark: true,
    builder: (bundle) => const SubscriptionScreen(),
  ),
  ScreenshotTarget(
    id: '06_obligations_add_sheet',
    category: '06_obligations',
    filename: '02_subscriptions_add_sheet.png',
    relativePath: '06_obligations/02_subscriptions_add_sheet.png',
    title: 'Add Subscription Sheet',
    isDark: true,
    builder: (bundle) => const SubscriptionScreen(),
    interaction: (tester, bundle) async {
      final ctx = tester.element(find.byType(SubscriptionScreen));
      SubscriptionScreen.showAddSubscriptionSheet(ctx);
    },
  ),

  // ===========================================================================
  // 07. INSIGHTS
  // ===========================================================================
  ScreenshotTarget(
    id: '07_insights_overview_charts',
    category: '07_insights',
    filename: '01_insights_overview_charts.png',
    relativePath: '07_insights/01_insights_overview_charts.png',
    title: 'Spending Insights & Trends Overview',
    isDark: true,
    builder: (bundle) => const InsightsScreen(),
  ),
  ScreenshotTarget(
    id: '07_insights_merchants_velocity',
    category: '07_insights',
    filename: '02_insights_merchants_velocity.png',
    relativePath: '07_insights/02_insights_merchants_velocity.png',
    title: 'Top Merchants & Velocity',
    isDark: true,
    builder: (bundle) => const InsightsScreen(),
    interaction: (tester, bundle) async {
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets, reason: 'InsightsScreen must be scrollable');
      await tester.drag(scrollable.first, const Offset(0, -320));
    },
  ),
  ScreenshotTarget(
    id: '07_insights_cards_ranked',
    category: '07_insights',
    filename: '03_insights_cards_ranked.png',
    relativePath: '07_insights/03_insights_cards_ranked.png',
    title: 'Ranked Spending Categories',
    isDark: true,
    builder: (bundle) => const InsightsScreen(),
    interaction: (tester, bundle) async {
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets, reason: 'InsightsScreen must be scrollable');
      await tester.drag(scrollable.first, const Offset(0, -560));
    },
  ),

  // ===========================================================================
  // 08. SETTINGS
  // ===========================================================================
  ScreenshotTarget(
    id: '08_settings_overview',
    category: '08_settings',
    filename: '01_settings_overview.png',
    relativePath: '08_settings/01_settings_overview.png',
    title: 'Settings Overview',
    isDark: true,
    builder: (bundle) => const SettingsScreen(),
  ),
  ScreenshotTarget(
    id: '08_settings_backup_export_dialog',
    category: '08_settings',
    filename: '02_settings_backup_export_dialog.png',
    relativePath: '08_settings/02_settings_backup_export_dialog.png',
    title: 'Backup & Restore Validation Dialog',
    isDark: true,
    builder: (bundle) => Builder(
      builder: (context) {
        return BackupRestoreDialog(
          backupFile: const WalletMeltBackupFile(
            jsonText: '{"version": 1, "exportedAt": "2026-08-26T10:00:00.000Z"}',
          ),
          preview: const WalletMeltBackupPreview(
            isValid: true,
            format: 'walletmelt.local_json_backup',
            formatVersion: 1,
            appVersion: '1.0.0',
            exportedAt: '2026-08-26T10:00:00.000Z',
            expensesCount: 42,
            categoriesCount: 9,
            budgetsCount: 6,
            groceryItemsCount: 18,
            deletedExpensesCount: 2,
            receiptImageCount: 5,
            hasSettings: true,
          ),
          localSnapshot: LocalAppSnapshot(
            expenses: bundle.darkAppState.expenses,
            deletedExpenses: const [],
            categories: bundle.darkAppState.categories,
            budgets: bundle.darkAppState.currentBudgets,
            groceryItems: const [],
          ),
          jsonBackupService: _FakeManifestJsonBackupService(),
          restoreService: _FakeManifestJsonRestoreService(),
          onSuccess: (result, duration, mode, version) {},
        );
      },
    ),
  ),
  ScreenshotTarget(
    id: '08_settings_merchants_management',
    category: '08_settings',
    filename: '03_settings_merchants_management.png',
    relativePath: '08_settings/03_settings_merchants_management.png',
    title: 'Saved Merchants Management',
    isDark: true,
    builder: (bundle) => const MerchantsScreen(),
  ),
  ScreenshotTarget(
    id: '08_settings_payees_management',
    category: '08_settings',
    filename: '04_settings_payees_management.png',
    relativePath: '08_settings/04_settings_payees_management.png',
    title: 'Saved Payees Management',
    isDark: true,
    builder: (bundle) => const PayeesScreen(),
  ),

  // ===========================================================================
  // 09. SECURITY
  // ===========================================================================
  ScreenshotTarget(
    id: '09_security_pin_lock_screen',
    category: '09_security',
    filename: '01_security_pin_lock_screen.png',
    relativePath: '09_security/01_security_pin_lock_screen.png',
    title: 'PIN Security Lock Screen',
    isDark: true,
    settleGracefully: false,
    builder: (bundle) => const PinLockScreen(),
  ),
  ScreenshotTarget(
    id: '09_security_pin_setup',
    category: '09_security',
    filename: '02_security_pin_setup.png',
    relativePath: '09_security/02_security_pin_setup.png',
    title: 'PIN Setup Screen',
    isDark: true,
    builder: (bundle) => const CreatePinScreen(),
  ),
  ScreenshotTarget(
    id: '09_security_settings_enabled',
    category: '09_security',
    filename: '03_security_settings_enabled.png',
    relativePath: '09_security/03_security_settings_enabled.png',
    title: 'Security Settings with PIN Enabled',
    isDark: true,
    builder: (bundle) => const SettingsScreen(),
    interaction: (tester, bundle) async {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -250));
      }
    },
  ),

  // ===========================================================================
  // 10. OTHER
  // ===========================================================================
  ScreenshotTarget(
    id: '10_other_onboarding_welcome',
    category: '10_other',
    filename: '01_onboarding_welcome.png',
    relativePath: '10_other/01_onboarding_welcome.png',
    title: 'Welcome Onboarding Screen',
    isDark: true,
    builder: (bundle) => const OnboardingScreen(),
  ),
  ScreenshotTarget(
    id: '10_other_privacy_policy_screen',
    category: '10_other',
    filename: '02_privacy_policy_screen.png',
    relativePath: '10_other/02_privacy_policy_screen.png',
    title: 'Privacy Policy & Data Transparency',
    isDark: true,
    builder: (bundle) => const PrivacyPolicyScreen(),
  ),
];

/// Generates and validates the publication manifest JSON file.
Future<File> writeManifestJson(List<ScreenshotTarget> targets) async {
  final baseDir = Directory('walletmelt_screenshots');
  baseDir.createSync(recursive: true);

  final List<Map<String, dynamic>> manifestEntries = [];

  for (final target in targets) {
    final file = File('${baseDir.path}/${target.relativePath}');
    if (!file.existsSync()) {
      throw StateError('Missing screenshot file: ${file.path}');
    }

    final bytes = await file.readAsBytes();
    final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];

    manifestEntries.add({
      'id': target.id,
      'category': target.category,
      'title': target.title,
      'filename': target.filename,
      'relativePath': target.relativePath,
      'width': width,
      'height': height,
      'fileSizeBytes': bytes.length,
      'status': 'verified',
    });
  }

  final manifestData = {
    'generatedAt': DateTime.now().toIso8601String(),
    'totalScreenshots': targets.length,
    'resolution': '1080x2400',
    'outputDirectory': 'walletmelt_screenshots',
    'screenshots': manifestEntries,
  };

  final manifestFile = File('${baseDir.path}/manifest.json');
  await manifestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifestData),
    flush: true,
  );
  return manifestFile;
}

class _FakeManifestJsonBackupService extends Fake implements WalletMeltJsonBackupService {}

class _FakeManifestJsonRestoreService extends Fake implements WalletMeltJsonRestoreService {}

