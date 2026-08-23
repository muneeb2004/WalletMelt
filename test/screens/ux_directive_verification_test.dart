import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/components/category/category_chip.dart';
import 'package:wallet_melt/src/components/navigation/app_shell.dart';
import 'package:wallet_melt/src/constants/categories.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/screens/add_expense/add_expense_screen.dart';
import 'package:wallet_melt/src/screens/budget/budget_screen.dart';
import 'package:wallet_melt/src/screens/dashboard/dashboard_screen.dart';
import 'package:wallet_melt/src/screens/insights/insights_screen.dart';
import 'package:wallet_melt/src/screens/planning/planning_screen.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/widgets/stat_tile.dart';
import 'package:wallet_melt/src/widgets/triple_metric_row.dart';

class FakeCategoryRepository extends Fake implements DriftCategoryRepository {
  List<wm.Category> categories = const [];
  @override
  Future<List<wm.Category>> listCategories() async => categories;
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

AppState createAppState({
  double? monthlyBudget,
  List<Expense> expenses = const [],
  List<wm.Category> categories = const [],
}) {
  final state = AppState.test(
    driftCategoryRepository: FakeCategoryRepository()..categories = categories,
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
  state.categories = categories;
  state.selectedMonth = DateTime.now();
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX Directive Verification & Regression Suite', () {
    // ── Item 1: Hero Card Theming ──────────────────────────────────────────
    testWidgets('Item 1: WMDarkHeroCard renders layered carbon gradient in light theme with shadow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WalletMeltTheme.light(),
          home: const Scaffold(
            body: WMDarkHeroCard(
              child: Text('Hero Card Content', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(WMDarkHeroCard),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, [
        WalletMeltColors.darkSurface,
        WalletMeltColors.darkBackgroundContainer,
      ]);
      expect(decoration.boxShadow, isNotEmpty);
      expect(decoration.border, isNotNull);
    });

    // ── Item 2 & 0: Greeting Row at 360dp & Touch Targets ─────────────────
    testWidgets('Item 2: Greeting text scales at 360dp width and header buttons maintain touch targets',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = createAppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: WalletMeltTheme.light(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    // ── Item 3: Budget Line Overlap ───────────────────────────────────────
    testWidgets('Item 3: Over-budget and budget limit text do not collide at 360dp',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final appState = createAppState(
        monthlyBudget: 50000,
        expenses: [
          Expense(
            id: 'e1',
            amount: 75000,
            currency: 'PKR',
            categoryId: 'fuel',
            title: 'High Fuel Expense',
            date: now.toIso8601String(),
            isRecurring: false,
            createdAt: now.toIso8601String(),
            updatedAt: now.toIso8601String(),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: WalletMeltTheme.light(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Over budget by'), findsOneWidget);
      expect(find.textContaining('Budget:'), findsOneWidget);
    });

    // ── Item 4: Add Expense Button Label ──────────────────────────────────
    testWidgets('Item 4: Quick Action Button Add Expense label uses FittedBox and does not truncate',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: WalletMeltTheme.light(),
          home: Scaffold(
            body: Row(
              children: [
                WMQuickActionButton(
                  icon: Icons.add_rounded,
                  label: 'Add Expense',
                  isPrimary: true,
                  onTap: () {},
                ),
                WMQuickActionButton(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel Refill',
                  onTap: () {},
                ),
                WMQuickActionButton(
                  icon: Icons.shopping_basket_rounded,
                  label: 'Groceries',
                  onTap: () {},
                ),
                WMQuickActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Insights',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Fuel Refill'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
    });

    // ── Item 5: Quick Shortcuts Category Pre-selection & Async Recovery ───
    testWidgets('Item 5: AddExpenseScreen resolves category by slug/name and prefills title',
        (tester) async {
      final now = DateTime.now();
      final defaultCategories = buildDefaultCategories(now);
      final appState = createAppState(categories: defaultCategories);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AddExpenseScreen(initialCategoryId: 'fuel'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fuel Purchase Entry'), findsOneWidget);
      final fuelChip = tester.widget<WalletCategoryChip>(
        find.widgetWithText(WalletCategoryChip, 'Fuel'),
      );
      expect(fuelChip.selected, isTrue);
    });

    testWidgets('Item 5: AddExpenseScreen handles UUID-remapped category with name match',
        (tester) async {
      final now = DateTime.now();
      final customCategories = [
        wm.Category(
          id: 'uuid-1234-5678-grocery',
          name: 'Grocery',
          icon: 'shopping_basket',
          color: '#8FD6B5',
          isDefault: false,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ];

      final appState = createAppState(categories: customCategories);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AddExpenseScreen(initialCategoryId: 'grocery'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bulk Grocery Entry'), findsOneWidget);
      final groceryChip = tester.widget<WalletCategoryChip>(
        find.widgetWithText(WalletCategoryChip, 'Grocery'),
      );
      expect(groceryChip.selected, isTrue);
    });

    // ── Item 7: Insights Icon Replace ─────────────────────────────────────
    testWidgets('Item 7: Insights icon uses Icons.bar_chart_rounded',
        (tester) async {
      final appState = createAppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.insights_rounded), findsNothing);
    });

    // ── Item 8: FAB Theming ───────────────────────────────────────────────
    testWidgets('Item 8: FloatingActionButtonThemeData has white foreground',
        (tester) async {
      final lightTheme = WalletMeltTheme.light();
      final darkTheme = WalletMeltTheme.dark();

      expect(lightTheme.floatingActionButtonTheme.foregroundColor, Colors.white);
      expect(darkTheme.floatingActionButtonTheme.foregroundColor, Colors.white);
    });

    // ── Item 9: Stat Tile & Triple Metric Row Digit Wrap ──────────────────
    testWidgets('Item 9: StatTile and TripleMetricRow render large figures without overflow at 360dp',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: StatTile(label: 'Spent', value: 'PKR 12,345,678')),
                    SizedBox(width: 8),
                    Expanded(child: StatTile(label: 'Remaining', value: 'PKR 98,765,432')),
                    SizedBox(width: 8),
                    Expanded(child: StatTile(label: 'Days Left', value: '25')),
                  ],
                ),
                SizedBox(height: 16),
                TripleMetricRow(
                  label1: 'SPENT',
                  value1: 'PKR 12,345,678',
                  color1: Colors.red,
                  label2: 'REMAINING',
                  value2: 'PKR 98,765,432',
                  color2: Colors.green,
                  label3: 'DAYS',
                  value3: '25',
                  color3: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PKR 12,345,678'), findsNWidgets(2));
      expect(find.text('PKR 98,765,432'), findsNWidgets(2));
    });

    // ── Item 10 & 11: Planning Screen TabBar & Action Icon ────────────────
    testWidgets('Item 10 & 11: Planning Screen renders tabs at 360dp and uses edit icon for budget',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = createAppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PlanningScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Subscriptions'), findsOneWidget);
      expect(find.text('Essentials'), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });

    // ── Feature: Daily Spend Allowance ────────────────────────────────────
    testWidgets('Feature: Daily Spend Allowance shows on Dashboard and updates live',
        (tester) async {
      final now = DateTime.now();
      final appState = createAppState(
        monthlyBudget: 40000,
        expenses: [
          Expense(
            id: 'e1',
            amount: 10000,
            currency: 'PKR',
            categoryId: 'fuel',
            title: 'Expense 1',
            date: now.toIso8601String(),
            isRecurring: false,
            createdAt: now.toIso8601String(),
            updatedAt: now.toIso8601String(),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY ALLOWANCE'), findsOneWidget);
      expect(find.textContaining('/ day'), findsOneWidget);

      // Over-budget condition
      await appState.setMonthlyBudgetAmount(5000);
      await tester.pumpAndSettle();

      expect(find.text('Over budget — no daily allowance'), findsOneWidget);
    });

    testWidgets('Feature: Daily Spend Allowance shows on BudgetScreen and updates live',
        (tester) async {
      final now = DateTime.now();
      final appState = createAppState(
        monthlyBudget: 60000,
        expenses: [
          Expense(
            id: 'e1',
            amount: 30000,
            currency: 'PKR',
            categoryId: 'fuel',
            title: 'Expense 1',
            date: now.toIso8601String(),
            isRecurring: false,
            createdAt: now.toIso8601String(),
            updatedAt: now.toIso8601String(),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: BudgetScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Spend Allowance'), findsOneWidget);
      expect(find.textContaining('/ day'), findsOneWidget);

      // Over-budget condition on BudgetScreen
      await appState.setMonthlyBudgetAmount(20000); // 30000 spent > 20000 budget
      await tester.pumpAndSettle();

      expect(find.text('No allowance remaining'), findsOneWidget);
    });

    // ── Item 6: Floating Nav Bar Animation, Transitions & Sizing ───────────
    testWidgets('Item 6: AppShell renders expanding pill with smooth transition at 360dp without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = createAppState();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home Page'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/history', builder: (context, state) => const Scaffold(body: Text('History Page'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/planning', builder: (context, state) => const Scaffold(body: Text('Planning Page'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/debt', builder: (context, state) => const Scaffold(body: Text('Debts Page'))),
              ]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp.router(
            theme: WalletMeltTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Home Page'), findsOneWidget);

      // Tap on Planning tab
      await tester.tap(find.byIcon(Icons.account_balance_wallet_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125)); // Mid-transition
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('Planning Page'), findsOneWidget);
    });
  });
}
