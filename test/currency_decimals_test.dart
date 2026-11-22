import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/constants/currencies.dart';
import 'package:wallet_melt/src/utils/currency_format.dart';
import 'package:wallet_melt/src/utils/expense_validation.dart';

void main() {
  group('currencyDecimalDigits', () {
    test('follows ISO 4217', () {
      expect(currencyDecimalDigits('PKR'), 2);
      expect(currencyDecimalDigits('usd'), 2);
      expect(currencyDecimalDigits('JPY'), 0);
      expect(currencyDecimalDigits('KRW'), 0);
      expect(currencyDecimalDigits('KWD'), 3);
      expect(currencyDecimalDigits('XYZ'), 2);
    });

    test('input digits are capped at the 1/100 storage scale', () {
      expect(currencyInputDecimalDigits('KWD'), 2);
      expect(currencyInputDecimalDigits('JPY'), 0);
      expect(currencyInputDecimalDigits('PKR'), 2);
    });
  });

  group('formatMoney', () {
    test('zero-decimal currencies never show decimals', () {
      expect(formatMoney(1200.5, 'JPY'), isNot(contains('.')));
    });

    test('two-decimal currencies keep whole amounts compact', () {
      expect(formatMoney(500, 'PKR'), isNot(contains('.')));
      expect(formatMoney(12.5, 'USD'), contains('12.50'));
    });

    test('three-decimal currencies show three places', () {
      expect(formatMoney(1.25, 'KWD'), contains('1.250'));
    });
  });

  group('amount precision', () {
    test('rejects decimals for zero-decimal currencies', () {
      expect(amountPrecisionError(100.5, 'JPY'), contains('whole numbers'));
      expect(amountPrecisionError(100, 'JPY'), isNull);
    });

    test('rejects a third decimal that storage would silently drop', () {
      expect(amountPrecisionError(1.234, 'PKR'), isNotNull);
      expect(amountPrecisionError(1.234, 'KWD'), isNotNull);
      expect(amountPrecisionError(1.23, 'PKR'), isNull);
      expect(amountPrecisionError(0.1 + 0.2, 'USD'), isNull);
    });

    test('large amounts with valid decimals are accepted', () {
      expect(amountPrecisionError(123456789.12, 'PKR'), isNull);
      expect(amountPrecisionError(999999999999.99, 'USD'), isNull);
      expect(amountPrecisionError(123456789.125, 'PKR'), isNotNull);
      expect(amountPrecisionError(987654321, 'JPY'), isNull);
    });

    test('expense validation applies the currency rule', () {
      final result = validateExpenseInput(
        amount: '1500.5',
        categoryId: 'food',
        date: DateTime(2026, 11, 1),
        currency: 'JPY',
      );
      expect(result.isValid, isFalse);
      expect(result.amountError, contains('whole numbers'));
    });
  });

  group('moneyTextPrecisionError (shared by every money form)', () {
    test('passes empty and non-numeric text through for the form to report', () {
      expect(moneyTextPrecisionError('', 'PKR'), isNull);
      expect(moneyTextPrecisionError('abc', 'PKR'), isNull);
    });

    test('flags typed precision the currency cannot hold', () {
      expect(moneyTextPrecisionError('1,250.5', 'JPY'), contains('whole numbers'));
      expect(moneyTextPrecisionError('Rs 99.999', 'PKR'), isNotNull);
      expect(moneyTextPrecisionError('1,250.50', 'PKR'), isNull);
      expect(moneyTextPrecisionError('-20.25', 'USD'), isNull);
    });
  });
}
