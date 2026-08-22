import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/screens/dashboard/dashboard_screen.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';

void main() {
  group('Dashboard Budget Summary Card Widget Tests', () {
    Widget buildDashboardHarness({required AppState appState}) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/planning',
            builder: (context, state) =>
                const Scaffold(body: Text('Planning Screen Mock')),
          ),
        ],
      );
      return ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    AppState createAppState(
        {double? monthlyBudget, List<Expense> expenses = const []}) {
      final state = AppState.test(
        driftCategoryRepository: FakeCategoryRepository(),
        driftExpenseRepository: FakeExpenseRepository()..activeExpenses = expenses,
        driftBudgetRepository: FakeBudgetRepository(),
        settingsService: FakeSettingsService(),
      );
      state.settings = WalletMeltSettings.defaults.copyWith(
        hasCompletedOnboarding: true,
        monthlyBudgetAmount: monthlyBudget,
        currency: 'PKR',
      );
      state.isLoading = false;
      state.expenses = expenses;
      state.selectedMonth = DateTime(2026, 6);
      return state;
    }

    testWidgets(
        'Dashboard shows no budget progress bar when monthlyBudgetAmount is null',
        (tester) async {
      final appState = createAppState(monthlyBudget: null);
      await tester.pumpWidget(buildDashboardHarness(appState: appState));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('No budget set for this month'), findsOneWidget);
    });

    testWidgets(
        'Dashboard shows budget card with correct spent and remaining values when monthlyBudgetAmount is set',
        (tester) async {
      final appState = createAppState(
        monthlyBudget: 5000.0,
        expenses: [
          const Expense(
            id: '1',
            amount: 2000.0,
            currency: 'PKR',
            categoryId: 'grocery',
            title: 'Weekly grocery',
            date: '2026-06-14T00:00:00.000',
            isRecurring: false,
            createdAt: '2026-06-14T10:00:00.000',
            updatedAt: '2026-06-14T10:00:00.000',
          ),
        ],
      );
      await tester.pumpWidget(buildDashboardHarness(appState: appState));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('2,000'), findsWidgets);
      expect(find.textContaining('3,000 remaining'), findsOneWidget);
    });

    testWidgets(
        'Dashboard budget card color reflects correct threshold (Green)',
        (tester) async {
      final appState = createAppState(
        monthlyBudget: 1000.0,
        expenses: [
          const Expense(
            id: '1',
            amount: 500.0, // 50% < 70% (Green)
            currency: 'PKR',
            categoryId: 'grocery',
            title: 'Grocery run',
            date: '2026-06-14T00:00:00.000',
            isRecurring: false,
            createdAt: '2026-06-14T10:00:00.000',
            updatedAt: '2026-06-14T10:00:00.000',
          ),
        ],
      );
      await tester.pumpWidget(buildDashboardHarness(appState: appState));
      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final valueColorAnimation =
          progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(valueColorAnimation.value, WalletMeltColors.positive);
    });

    testWidgets(
        'Dashboard budget card color reflects correct threshold (Amber)',
        (tester) async {
      final appState = createAppState(
        monthlyBudget: 1000.0,
        expenses: [
          const Expense(
            id: '1',
            amount: 800.0, // 80% (Amber/Brand)
            currency: 'PKR',
            categoryId: 'grocery',
            title: 'Grocery run',
            date: '2026-06-14T00:00:00.000',
            isRecurring: false,
            createdAt: '2026-06-14T10:00:00.000',
            updatedAt: '2026-06-14T10:00:00.000',
          ),
        ],
      );
      await tester.pumpWidget(buildDashboardHarness(appState: appState));
      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final valueColorAnimation =
          progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(valueColorAnimation.value, WalletMeltColors.brand);
    });

    testWidgets('Tapping the hero card opens the budget adjustment sheet',
        (tester) async {
      final appState = createAppState(
        monthlyBudget: 5000.0,
      );
      await tester.pumpWidget(buildDashboardHarness(appState: appState));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(WMDarkHeroCard));
      await tester.pumpAndSettle();

      expect(find.text('Edit Monthly Budget'), findsOneWidget);
    });
  });
}

class FakeCategoryRepository extends Fake implements DriftCategoryRepository {
  @override
  Future<List<wm.Category>> listCategories() async => const [];
}

class FakeExpenseRepository extends Fake implements DriftExpenseRepository {
  List<Expense> activeExpenses = const [];
  @override
  Future<List<Expense>> listActive() async => activeExpenses;
  @override
  Future<List<Expense>> listDeleted() async => const [];
  @override
  Future<List<GroceryItem>> listAllGroceryItems() async => const [];
}

class FakeBudgetRepository extends Fake implements DriftBudgetRepository {
  @override
  Future<List<CategoryBudget>> listForMonth(String month) async => const [];
  @override
  Future<List<CategoryBudget>> listAll() async => const [];
}

class FakeSettingsService extends Fake implements SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}
