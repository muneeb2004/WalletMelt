import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    hide EssentialExpenseTemplate, FuelTemplateComponent, FuelTransaction, FuelComponent;
import 'package:wallet_melt/src/data/repositories/drift/drift_essential_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_fuel_repository.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/fuel.dart';

void main() {
  group('Drift Essential Expenses & Fuel Repositories Tests', () {
    late WalletMeltDatabase db;
    late DriftEssentialExpenseRepository essentialRepo;
    late DriftFuelRepository fuelRepo;
    late DriftExpenseRepository expenseRepo;

    setUp(() {
      db = WalletMeltDatabase(NativeDatabase.memory());
      essentialRepo = DriftEssentialExpenseRepository(db);
      fuelRepo = DriftFuelRepository(db);
      expenseRepo = DriftExpenseRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Create and retrieve essential template with fuel template components', () async {
      const template = EssentialExpenseTemplate(
        id: 'tmpl-fuel-1',
        name: 'Monthly Commute Fuel',
        categoryId: 'fuel',
        frequency: 'monthly',
        expectedAmount: 0.0,
        expectedDay: 5,
        isActive: true,
        isFuel: true,
        notes: 'Honda Civic monthly refill',
        createdAt: '2026-08-01T00:00:00.000',
        updatedAt: '2026-08-01T00:00:00.000',
      );

      final components = [
        const FuelTemplateComponent(
          id: 'ftc-1',
          templateId: 'tmpl-fuel-1',
          fuelType: FuelType.regular,
          expectedLitres: 50.0,
          expectedPricePerLitre: 265.0,
          createdAt: '2026-08-01T00:00:00.000',
        ),
        const FuelTemplateComponent(
          id: 'ftc-2',
          templateId: 'tmpl-fuel-1',
          fuelType: FuelType.premium,
          expectedLitres: 10.0,
          expectedPricePerLitre: 290.0,
          createdAt: '2026-08-01T00:00:00.000',
        ),
      ];

      await essentialRepo.create(template, fuelComponents: components);

      final retrieved = await essentialRepo.getById('tmpl-fuel-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Monthly Commute Fuel');
      expect(retrieved.isFuel, isTrue);
      expect(retrieved.expectedDay, 5);
      expect(retrieved.fuelComponents, hasLength(2));
      expect(retrieved.totalExpectedLitres, 60.0);
      expect(retrieved.computedExpectedAmount, 16150.0); // (50*265) + (10*290) = 13250 + 2900 = 16150

      // Toggle active status
      await essentialRepo.toggleActive('tmpl-fuel-1', false);
      final toggled = await essentialRepo.getById('tmpl-fuel-1');
      expect(toggled!.isActive, isFalse);

      // Delete template
      await essentialRepo.delete('tmpl-fuel-1');
      final afterDelete = await essentialRepo.getById('tmpl-fuel-1');
      expect(afterDelete, isNull);
    });

    test('DriftExpenseRepository writes and reads fuel transaction and components', () async {
      final draft = ExpenseDraft(
        amount: 13500.0,
        currency: 'PKR',
        categoryId: 'fuel',
        title: 'Shell Petrol Station',
        vendor: 'Shell Gulberg',
        date: DateTime(2026, 8, 15),
        notes: 'Trip refill',
        subtotalAmount: 13500.0,
        fuelTransaction: const FuelTransactionDraft(
          odometerReading: 52400.0,
          components: [
            FuelComponentDraft(
              fuelType: FuelType.regular,
              quantityLitres: 40.0,
              pricePerLitre: 265.0,
            ),
            FuelComponentDraft(
              fuelType: FuelType.premium,
              quantityLitres: 10.0,
              pricePerLitre: 290.0,
            ),
          ],
        ),
      );

      final createdExpense = await expenseRepo.create(draft);
      expect(createdExpense.id, isNotNull);

      // Read via DriftFuelRepository
      final fuelTx = await fuelRepo.getByExpenseId(createdExpense.id);
      expect(fuelTx, isNotNull);
      expect(fuelTx!.expenseId, createdExpense.id);
      expect(fuelTx.odometerReading, 52400.0);
      expect(fuelTx.components, hasLength(2));
      expect(fuelTx.totalLitres, 50.0);
      expect(fuelTx.totalAmount, 13500.0);

      // Verify cascading on expense permanent deletion
      await expenseRepo.permanentlyDelete(createdExpense.id);
      final afterDeleteTx = await fuelRepo.getByExpenseId(createdExpense.id);
      expect(afterDeleteTx, isNull);
    });
  });
}
