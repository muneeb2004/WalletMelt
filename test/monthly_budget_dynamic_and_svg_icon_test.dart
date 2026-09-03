import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_melt/src/components/category/category_icon.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_monthly_budget_repository.dart';
import 'package:wallet_melt/src/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Monthly Budget in AppState', () {
    late WalletMeltDatabase db;
    late DriftMonthlyBudgetRepository monthlyBudgetRepo;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = WalletMeltDatabase.memory();
      monthlyBudgetRepo = DriftMonthlyBudgetRepository(db);
      appState = AppState.test(
        driftMonthlyBudgetRepository: monthlyBudgetRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Each month can have its own budget and adapts dynamically when switching months', () async {
      // Configure Month 1: 2026-06 with $5000 budget
      await appState.setSelectedMonth(DateTime(2026, 6));
      expect(appState.getMonthlyBudgetAmount(), isNull);

      await appState.setMonthlyBudgetAmount(5000.0);
      expect(appState.getMonthlyBudgetAmount(), 5000.0);

      // Configure Month 2: 2026-07 with $3500 budget
      await appState.setSelectedMonth(DateTime(2026, 7));
      expect(appState.getMonthlyBudgetAmount(), 5000.0); // Falls back to settings until explicitly set

      await appState.setMonthlyBudgetAmount(3500.0);
      expect(appState.getMonthlyBudgetAmount(), 3500.0);

      // Switch back to 2026-06: budget dynamically returns $5000
      await appState.setSelectedMonth(DateTime(2026, 6));
      expect(appState.getMonthlyBudgetAmount(), 5000.0);

      // Switch forward to 2026-07: budget dynamically returns $3500
      await appState.setSelectedMonth(DateTime(2026, 7));
      expect(appState.getMonthlyBudgetAmount(), 3500.0);

      // Switch to 2026-08 (no budget set yet)
      await appState.setSelectedMonth(DateTime(2026, 8));
      // Test 1-tap copy from previous month (2026-07 which had $3500)
      final copied = await appState.copyBudgetFromPreviousMonth();
      expect(copied, isTrue);
      expect(appState.getMonthlyBudgetAmount(), 3500.0);

      // Persisted in DB correctly
      final dbBudget = await monthlyBudgetRepo.getForMonth('2026-08');
      expect(dbBudget, isNotNull);
      expect(dbBudget!.amount, 3500.0);
    });
  });

  group('CategoryIcon Widget Rendering', () {
    testWidgets('renders standard category SVG for standard icon names', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: 'electricity',
              size: 24,
              color: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders preset SVG for custom preset category icon names', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: 'food_dining',
              size: 24,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders legacy IconData fallback gracefully when icon name is unknown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: 'unknown_icon_string',
              size: 24,
              color: Colors.blue,
              defaultIcon: Icons.category_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.category_rounded), findsOneWidget);
    });

    testWidgets('renders legacy IconData fallback for null icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: null,
              size: 24,
              color: Colors.blue,
              defaultIcon: Icons.help_outline,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });
}
