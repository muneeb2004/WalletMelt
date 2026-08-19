import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/fuel.dart';

void main() {
  group('Essential Expenses Logic & Template Tests', () {
    test('Essential template calculates expected amount for standard and multi-fuel templates', () {
      // Standard template (e.g. Rent PKR 50,000)
      const rentTemplate = EssentialExpenseTemplate(
        id: 'rent-tmpl',
        name: 'Apartment Rent',
        categoryId: 'rent',
        frequency: 'monthly',
        expectedAmount: 50000.0,
        expectedDay: 1,
        isActive: true,
        isFuel: false,
        createdAt: '2026-08-01T00:00:00.000',
        updatedAt: '2026-08-01T00:00:00.000',
      );
      expect(rentTemplate.computedExpectedAmount, 50000.0);
      expect(rentTemplate.totalExpectedLitres, 0.0);

      // Multi-fuel template (e.g. 60 L Regular @ 265 + 20 L Premium @ 290 = 15,900 + 5,800 = 21,700)
      const fuelTemplate = EssentialExpenseTemplate(
        id: 'fuel-tmpl',
        name: 'Monthly Fuel',
        categoryId: 'fuel',
        frequency: 'monthly',
        expectedAmount: 0.0,
        expectedDay: 15,
        isActive: true,
        isFuel: true,
        createdAt: '2026-08-01T00:00:00.000',
        updatedAt: '2026-08-01T00:00:00.000',
        fuelComponents: [
          FuelTemplateComponent(
            id: 'ftc-1',
            templateId: 'fuel-tmpl',
            fuelType: FuelType.regular,
            expectedLitres: 60.0,
            expectedPricePerLitre: 265.0,
            createdAt: '2026-08-01T00:00:00.000',
          ),
          FuelTemplateComponent(
            id: 'ftc-2',
            templateId: 'fuel-tmpl',
            fuelType: FuelType.premium,
            expectedLitres: 20.0,
            expectedPricePerLitre: 290.0,
            createdAt: '2026-08-01T00:00:00.000',
          ),
        ],
      );
      expect(fuelTemplate.totalExpectedLitres, 80.0);
      expect(fuelTemplate.computedExpectedAmount, 21700.0);
    });

    test('Expected Essentials vs Actual Spending calculates totals correctly in AppState', () {
      final state = AppState.test();

      final rentTmpl = const EssentialExpenseTemplate(
        id: 'rent-tmpl',
        name: 'House Rent',
        categoryId: 'rent',
        frequency: 'monthly',
        expectedAmount: 50000.0,
        expectedDay: 1,
        isActive: true,
        isFuel: false,
        createdAt: '2026-08-01T00:00:00.000',
        updatedAt: '2026-08-01T00:00:00.000',
      );

      final fuelTmpl = const EssentialExpenseTemplate(
        id: 'fuel-tmpl',
        name: 'Fuel',
        categoryId: 'fuel',
        frequency: 'monthly',
        expectedAmount: 0.0,
        expectedDay: 15,
        isActive: true,
        isFuel: true,
        createdAt: '2026-08-01T00:00:00.000',
        updatedAt: '2026-08-01T00:00:00.000',
        fuelComponents: [
          FuelTemplateComponent(
            id: 'ftc-1',
            templateId: 'fuel-tmpl',
            fuelType: FuelType.regular,
            expectedLitres: 60.0,
            expectedPricePerLitre: 265.0,
            createdAt: '2026-08-01T00:00:00.000',
          ),
        ],
      );

      final pausedTmpl = const EssentialExpenseTemplate(
        id: 'paused-tmpl',
        name: 'Old Gym',
        categoryId: 'other',
        frequency: 'monthly',
        expectedAmount: 10000.0,
        isActive: false, // PAUSED -> Should not be included in expected total
        isFuel: false,
        createdAt: '2026-08-01T00:00:00.000',
        updatedAt: '2026-08-01T00:00:00.000',
      );

      state.essentialTemplates = [rentTmpl, fuelTmpl, pausedTmpl];

      // Actual recorded expenses in August 2026
      state.expenses = [
        const Expense(
          id: 'exp-1',
          amount: 50000.0,
          currency: 'PKR',
          categoryId: 'rent',
          title: 'August Rent Paid',
          date: '2026-08-01T12:00:00.000',
          isRecurring: false,
          createdAt: '2026-08-01T12:00:00.000',
          updatedAt: '2026-08-01T12:00:00.000',
        ),
        const Expense(
          id: 'exp-2',
          amount: 16000.0,
          currency: 'PKR',
          categoryId: 'fuel',
          title: 'Shell Fuel Refill',
          date: '2026-08-10T12:00:00.000',
          isRecurring: false,
          createdAt: '2026-08-10T12:00:00.000',
          updatedAt: '2026-08-10T12:00:00.000',
        ),
        const Expense(
          id: 'exp-3',
          amount: 4500.0,
          currency: 'PKR',
          categoryId: 'entertainment', // Non-essential
          title: 'Movie Tickets',
          date: '2026-08-12T12:00:00.000',
          isRecurring: false,
          createdAt: '2026-08-12T12:00:00.000',
          updatedAt: '2026-08-12T12:00:00.000',
        ),
      ];

      final summary = state.getMonthlyEssentialSummary(DateTime(2026, 8, 1));
      // Expected = Rent (50,000) + Fuel (60 * 265 = 15,900) = 65,900
      expect(summary['expected'], 65900.0);
      // Actual = Rent (50,000) + Fuel (16,000) = 66,000
      expect(summary['actual'], 66000.0);
    });

    test('Deleting a template removes template without deleting past expenses', () {
      final state = AppState.test();

      state.essentialTemplates = [
        const EssentialExpenseTemplate(
          id: 'rent-tmpl',
          name: 'House Rent',
          categoryId: 'rent',
          frequency: 'monthly',
          expectedAmount: 50000.0,
          isActive: true,
          isFuel: false,
          createdAt: '2026-08-01T00:00:00.000',
          updatedAt: '2026-08-01T00:00:00.000',
        ),
      ];

      final pastExpense = const Expense(
        id: 'past-exp-1',
        amount: 50000.0,
        currency: 'PKR',
        categoryId: 'rent',
        title: 'Rent Paid',
        date: '2026-08-01T10:00:00.000',
        isRecurring: false,
        createdAt: '2026-08-01T10:00:00.000',
        updatedAt: '2026-08-01T10:00:00.000',
      );
      state.expenses = [pastExpense];

      // Remove template
      state.essentialTemplates = [];

      // Template is removed
      expect(state.essentialTemplates, isEmpty);
      // Historical recorded actual expense is still intact
      expect(state.expenses, hasLength(1));
      expect(state.expenses.first.id, 'past-exp-1');
      expect(state.expenses.first.amount, 50000.0);
    });
  });
}
