import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/utils/currency_format.dart';

void main() {
  group('Canonical Integer Minor Units & Money Formatting Tests', () {
    test('Converts floating-point currency to exact integer minor units', () {
      expect(toMinorUnits(10.50), 1050);
      expect(toMinorUnits(0.01), 1);
      expect(toMinorUnits(100), 10000);
      expect(toMinorUnits(0.00), 0);
      expect(toMinorUnits(-15.75), -1575);
    });

    test('Avoids IEEE-754 precision drift in repeated summation', () {
      // In IEEE-754 doubles: 0.1 + 0.2 = 0.30000000000000004
      // In integer minor units: 10 + 20 = 30 exactly
      final item1Minor = toMinorUnits(0.10);
      final item2Minor = toMinorUnits(0.20);
      final totalMinor = item1Minor + item2Minor;

      expect(totalMinor, 30);
      expect(fromMinorUnits(totalMinor), 0.30);
    });

    test('formatMoneyMinorUnits formats currency accurately', () {
      expect(formatMoneyMinorUnits(1050, 'USD'), r'$10.50');
      expect(formatMoneyMinorUnits(10000, 'USD'), r'$100');
      expect(formatMoneyMinorUnits(500, 'PKR'), 'Rs 5');
      expect(formatMoneyMinorUnits(525, 'PKR'), 'Rs 5.25');
    });
  });
}
