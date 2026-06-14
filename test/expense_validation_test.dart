import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/utils/expense_validation.dart';

void main() {
  group('validateExpenseInput', () {
    test('rejects missing and non-positive amount', () {
      expect(validateExpenseInput(amount: '', categoryId: 'rent', date: DateTime(2026)).isValid, isFalse);
      expect(validateExpenseInput(amount: '-4', categoryId: 'rent', date: DateTime(2026)).amountError, isNotNull);
      expect(validateExpenseInput(amount: '0', categoryId: 'rent', date: DateTime(2026)).amountError, isNotNull);
    });

    test('requires category and date', () {
      final result = validateExpenseInput(amount: '1200', categoryId: null, date: null);
      expect(result.isValid, isFalse);
      expect(result.categoryError, isNotNull);
      expect(result.dateError, isNotNull);
    });

    test('accepts positive amount with category and date', () {
      final result = validateExpenseInput(amount: '1200.50', categoryId: 'grocery', date: DateTime(2026, 6, 13));
      expect(result.isValid, isTrue);
    });
  });
}
