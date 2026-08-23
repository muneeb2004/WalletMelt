import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/screens/add_expense/add_expense_screen.dart';
import 'package:wallet_melt/src/screens/budget/budget_screen.dart';
import 'package:wallet_melt/src/screens/dashboard/dashboard_screen.dart';
import 'package:wallet_melt/src/screens/history/history_screen.dart';
import 'package:wallet_melt/src/screens/insights/insights_screen.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/widgets/state_views.dart';

void main() {
  group('Screen Error & Offline State Wiring Tests', () {
    testWidgets('DashboardScreen renders AppErrorState and AppOfflineState', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: WalletMeltTheme.dark(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsNothing);
      expect(find.byType(AppOfflineState), findsNothing);

      // Trigger error
      appState.errorMessage = 'Failed to load dashboard metrics';
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Failed to load dashboard metrics'), findsOneWidget);

      // Clear error and trigger offline
      appState.errorMessage = null;
      appState.isOffline = true;
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppOfflineState), findsOneWidget);
    });

    testWidgets('HistoryScreen renders AppErrorState and AppOfflineState', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: WalletMeltTheme.dark(),
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger error
      appState.errorMessage = 'Database query failed';
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Database query failed'), findsOneWidget);

      // Trigger offline
      appState.errorMessage = null;
      appState.isOffline = true;
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppOfflineState), findsOneWidget);
    });

    testWidgets('BudgetScreen renders AppErrorState and AppOfflineState', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: WalletMeltTheme.dark(),
            home: const BudgetScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger error
      appState.errorMessage = 'Budget calculation error';
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Budget calculation error'), findsOneWidget);

      // Trigger offline
      appState.errorMessage = null;
      appState.isOffline = true;
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppOfflineState), findsOneWidget);
    });

    testWidgets('InsightsScreen renders AppErrorState and AppOfflineState', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: WalletMeltTheme.dark(),
            home: const InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger error
      appState.errorMessage = 'Analytics engine failure';
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Analytics engine failure'), findsOneWidget);

      // Trigger offline
      appState.errorMessage = null;
      appState.isOffline = true;
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppOfflineState), findsOneWidget);
    });

    testWidgets('AddExpenseScreen renders AppErrorState and AppOfflineState', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: WalletMeltTheme.dark(),
            home: const AddExpenseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger error
      appState.errorMessage = 'Category repository unavailable';
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Category repository unavailable'), findsOneWidget);

      // Trigger offline
      appState.errorMessage = null;
      appState.isOffline = true;
      appState.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppOfflineState), findsOneWidget);
    });
  });
}
