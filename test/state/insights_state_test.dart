import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('AppState Insights & Analytics Cache Invalidation', () {
    test('AppState exposes spendingSnapshot, insightCards, and spendingSummaries matching single source of truth', () {
      final appState = AppState();
      appState.settings = WalletMeltSettings.defaults;
      appState.categories = [
        const wm.Category(
          id: 'cat_dining',
          name: 'Dining',
          icon: 'restaurant',
          color: '#FF5722',
          isDefault: true,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      ];
      appState.expenses = [
        Expense(
          id: 'exp_1',
          amount: 5000,
          currency: 'PKR',
          categoryId: 'cat_dining',
          title: 'Dinner',
          date: '2026-08-10',
          vendor: 'KFC',
          isRecurring: false,
          createdAt: '2026-08-01',
          updatedAt: '2026-08-01',
        ),
      ];
      appState.selectedMonth = DateTime(2026, 8);

      final snapshot = appState.spendingSnapshot;
      expect(snapshot.currentTotal, 5000.0);

      final summaries = appState.spendingSummaries;
      expect(summaries.topCategories.first.netAmount, 5000.0);
      expect(summaries.topMerchants.first.displayName, 'KFC');
      expect(summaries.largestExpenses.first.id, 'exp_1');

      final monthlyInsights = appState.monthlyInsights;
      expect(monthlyInsights.total, 5000.0);
      expect(monthlyInsights.categorySpend.first.total, 5000.0);
    });

    test('Selecting a new month invalidates cached snapshot, summaries, and monthlyInsights', () {
      final appState = AppState();
      appState.settings = WalletMeltSettings.defaults;
      appState.expenses = [
        Expense(
          id: 'exp_1',
          amount: 5000,
          currency: 'PKR',
          categoryId: 'cat_dining',
          title: 'Dinner',
          date: '2026-08-10',
          vendor: 'KFC',
          isRecurring: false,
          createdAt: '2026-08-01',
          updatedAt: '2026-08-01',
        ),
        Expense(
          id: 'exp_2',
          amount: 3000,
          currency: 'PKR',
          categoryId: 'cat_dining',
          title: 'Lunch',
          date: '2026-07-15',
          vendor: 'Subway',
          isRecurring: false,
          createdAt: '2026-07-01',
          updatedAt: '2026-07-01',
        ),
      ];

      appState.selectedMonth = DateTime(2026, 8);
      expect(appState.spendingSnapshot.currentTotal, 5000.0);
      expect(appState.monthlyInsights.total, 5000.0);

      appState.selectedMonth = DateTime(2026, 7);
      expect(appState.spendingSnapshot.currentTotal, 3000.0);
      expect(appState.monthlyInsights.total, 3000.0);
    });
  });
}
