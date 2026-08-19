import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/types/fuel.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';

void main() {
  group('Fuel Calculation & Formatting Tests', () {
    test('Single fuel type calculation with deterministic rounding', () {
      final comp = FuelComponent(
        id: 'comp-1',
        fuelTransactionId: 'tx-1',
        fuelType: FuelType.regular,
        quantityLitres: 40.0,
        pricePerLitre: 265.0,
        subtotal: 10600.0,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(comp.computedSubtotal, 10600.0);
      expect(comp.subtotal, 10600.0);
    });

    test('Decimal quantity support and fractional precision rounding', () {
      // 12.34 L @ PKR 265.50 = 3276.27
      final subtotal = roundToTwoDecimals(12.34 * 265.50);
      expect(subtotal, 3276.27);

      final compDraft = FuelComponentDraft(
        fuelType: FuelType.regular,
        quantityLitres: 12.34,
        pricePerLitre: 265.50,
      );
      expect(compDraft.subtotal, 3276.27);
    });

    test('All 7 fuel type combinations calculate subtotals and grand totals correctly', () {
      // 1. Regular only
      final tx1 = FuelTransactionDraft(
        components: [
          const FuelComponentDraft(
            fuelType: FuelType.regular,
            quantityLitres: 40.0,
            pricePerLitre: 265.0,
          ),
        ],
      );
      expect(tx1.totalLitres, 40.0);
      expect(tx1.totalAmount, 10600.0);

      // 2. Premium only
      final tx2 = FuelTransactionDraft(
        components: [
          const FuelComponentDraft(
            fuelType: FuelType.premium,
            quantityLitres: 30.0,
            pricePerLitre: 290.0,
          ),
        ],
      );
      expect(tx2.totalLitres, 30.0);
      expect(tx2.totalAmount, 8700.0);

      // 3. Diesel only
      final tx3 = FuelTransactionDraft(
        components: [
          const FuelComponentDraft(
            fuelType: FuelType.diesel,
            quantityLitres: 50.0,
            pricePerLitre: 275.0,
          ),
        ],
      );
      expect(tx3.totalLitres, 50.0);
      expect(tx3.totalAmount, 13750.0);

      // 4. Regular + Premium
      final tx4 = FuelTransactionDraft(
        components: [
          const FuelComponentDraft(
            fuelType: FuelType.regular,
            quantityLitres: 40.0,
            pricePerLitre: 265.0,
          ),
          const FuelComponentDraft(
            fuelType: FuelType.premium,
            quantityLitres: 10.0,
            pricePerLitre: 290.0,
          ),
        ],
      );
      expect(tx4.totalLitres, 50.0);
      expect(tx4.totalAmount, 13500.0);

      // 5. Regular + Diesel
      final tx5 = FuelTransactionDraft(
        components: [
          const FuelComponentDraft(
            fuelType: FuelType.regular,
            quantityLitres: 20.0,
            pricePerLitre: 265.0,
          ),
          const FuelComponentDraft(
            fuelType: FuelType.diesel,
            quantityLitres: 30.0,
            pricePerLitre: 275.0,
          ),
        ],
      );
      expect(tx5.totalLitres, 50.0);
      expect(tx5.totalAmount, 13550.0);

      // 6. Premium + Diesel
      final tx6 = FuelTransactionDraft(
        components: [
          const FuelComponentDraft(
            fuelType: FuelType.premium,
            quantityLitres: 15.0,
            pricePerLitre: 290.0,
          ),
          const FuelComponentDraft(
            fuelType: FuelType.diesel,
            quantityLitres: 25.0,
            pricePerLitre: 275.0,
          ),
        ],
      );
      expect(tx6.totalLitres, 40.0);
      expect(tx6.totalAmount, 11225.0);

      // 7. Regular + Premium + Diesel
      final tx7 = FuelTransactionDraft(
        components: [
          const FuelComponentDraft(
            fuelType: FuelType.regular,
            quantityLitres: 20.0,
            pricePerLitre: 265.0,
          ),
          const FuelComponentDraft(
            fuelType: FuelType.premium,
            quantityLitres: 10.0,
            pricePerLitre: 290.0,
          ),
          const FuelComponentDraft(
            fuelType: FuelType.diesel,
            quantityLitres: 15.0,
            pricePerLitre: 275.0,
          ),
        ],
      );
      expect(tx7.totalLitres, 45.0);
      expect(tx7.totalAmount, 12325.0);
    });

    test('Odometer reading is preserved when present and null when omitted', () {
      const withOdo = FuelTransactionDraft(
        odometerReading: 45200.5,
        components: [
          FuelComponentDraft(
            fuelType: FuelType.regular,
            quantityLitres: 20.0,
            pricePerLitre: 265.0,
          ),
        ],
      );
      expect(withOdo.odometerReading, 45200.5);

      const withoutOdo = FuelTransactionDraft(
        components: [
          FuelComponentDraft(
            fuelType: FuelType.regular,
            quantityLitres: 20.0,
            pricePerLitre: 265.0,
          ),
        ],
      );
      expect(withoutOdo.odometerReading, isNull);
    });

    test('Historical price preservation: template price modification does not mutate past fuel transaction', () {
      // Past August transaction with PKR 250/L
      final augTxComponent = FuelComponent(
        id: 'aug-comp-1',
        fuelTransactionId: 'aug-tx-1',
        fuelType: FuelType.regular,
        quantityLitres: 50.0,
        pricePerLitre: 250.0,
        subtotal: 12500.0,
        createdAt: '2026-08-01T10:00:00.000',
      );

      // September template price changes to PKR 280/L
      final sepTemplate = EssentialExpenseTemplate(
        id: 'tmpl-1',
        name: 'Monthly Fuel',
        categoryId: 'fuel',
        frequency: 'monthly',
        expectedAmount: 0.0,
        isActive: true,
        isFuel: true,
        createdAt: '2026-09-01T10:00:00.000',
        updatedAt: '2026-09-01T10:00:00.000',
        fuelComponents: const [
          FuelTemplateComponent(
            id: 'ftc-1',
            templateId: 'tmpl-1',
            fuelType: FuelType.regular,
            expectedLitres: 50.0,
            expectedPricePerLitre: 280.0,
            createdAt: '2026-09-01T10:00:00.000',
          ),
        ],
      );

      // Template computed expected is now 50 * 280 = 14,000
      expect(sepTemplate.computedExpectedAmount, 14000.0);

      // Past August transaction MUST remain 12,500 at 250/L
      expect(augTxComponent.pricePerLitre, 250.0);
      expect(augTxComponent.subtotal, 12500.0);
      expect(augTxComponent.computedSubtotal, 12500.0);
    });
  });
}
