import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/screens/history/history_screen.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  testWidgets('History screen defaults to current month and expands with Show All', (tester) async {
    final appState = AppState.test();
    appState.settings = WalletMeltSettings.defaults.copyWith(
      hasCompletedOnboarding: true,
      hasAcceptedPrivacyPolicy: true,
    );
    appState.categories = [
      const Category(
        id: 'cat_1',
        name: 'Groceries',
        icon: 'shopping_cart',
        color: '#FF0000',
        isDefault: true,
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      ),
    ];

    final now = DateTime.now();
    final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-02';
    // An expense from 3 months ago
    final olderDate = DateTime(now.year, now.month - 3, 15);
    final olderMonthStr = '${olderDate.year}-${olderDate.month.toString().padLeft(2, '0')}-15';

    appState.expenses = [
      Expense(
        id: '00000000-0000-0000-0000-000000000001',
        amount: 30.0,
        currency: 'USD',
        categoryId: 'cat_1',
        title: 'Current Month Grocery',
        date: currentMonthStr,
        isRecurring: false,
        createdAt: '${currentMonthStr}T12:00:00Z',
        updatedAt: '${currentMonthStr}T12:00:00Z',
      ),
      Expense(
        id: '00000000-0000-0000-0000-000000000002',
        amount: 50.0,
        currency: 'USD',
        categoryId: 'cat_1',
        title: 'Older Secret Expense',
        date: olderMonthStr,
        isRecurring: false,
        createdAt: '${olderMonthStr}T12:00:00Z',
        updatedAt: '${olderMonthStr}T12:00:00Z',
      ),
    ];
    appState.isLoading = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(body: HistoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Current month expense should be visible
    expect(find.text('Current Month Grocery'), findsOneWidget);

    // Older expense should be hidden
    expect(find.text('Older Secret Expense'), findsNothing);

    // Show All button should be visible with 1 older expense hidden
    expect(find.text('Show All'), findsOneWidget);
    expect(find.text('1 older expense hidden'), findsOneWidget);

    // Tap Show All
    await tester.tap(find.text('Show All'));
    await tester.pumpAndSettle();

    // Now both should be visible
    expect(find.text('Current Month Grocery'), findsOneWidget);
    expect(find.text('Older Secret Expense'), findsOneWidget);
    expect(find.text('Show Current Month Only'), findsOneWidget);

    // Tap Show Current Month Only
    await tester.tap(find.text('Show Current Month Only'));
    await tester.pumpAndSettle();

    // Older expense should be hidden again
    expect(find.text('Older Secret Expense'), findsNothing);

    // Search for older expense: should search across all history
    await tester.enterText(find.byType(TextField).first, 'Secret');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Older Secret Expense'), findsOneWidget);
  });
}
