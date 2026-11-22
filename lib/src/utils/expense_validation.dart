import '../constants/currencies.dart';
import 'number_parser.dart';

class ExpenseValidationResult {
  const ExpenseValidationResult(
      {required this.isValid,
      this.amountError,
      this.categoryError,
      this.dateError});

  final bool isValid;
  final String? amountError;
  final String? categoryError;
  final String? dateError;
}

ExpenseValidationResult validateExpenseInput({
  required String amount,
  required String? categoryId,
  required DateTime? date,
  String? currency,
}) {
  final parsed = parseTolerantNumber(amount);
  String? amountError =
      parsed == null || parsed <= 0 ? 'Enter a positive amount.' : null;
  if (amountError == null && currency != null) {
    amountError = amountPrecisionError(parsed!, currency);
  }
  final categoryError =
      categoryId == null || categoryId.isEmpty ? 'Choose a category.' : null;
  final dateError = date == null ? 'Choose a date.' : null;

  return ExpenseValidationResult(
    isValid: amountError == null && categoryError == null && dateError == null,
    amountError: amountError,
    categoryError: categoryError,
    dateError: dateError,
  );
}

/// [amountPrecisionError] for typed money [text]. Returns null when the text
/// is empty or not a number (callers report those themselves) or is fine.
String? moneyTextPrecisionError(String text, String currency) {
  final value = parseTolerantNumber(text);
  return value == null ? null : amountPrecisionError(value, currency);
}

/// Error text when [amount] has more decimal places than [currency] allows,
/// otherwise null.
String? amountPrecisionError(double amount, String currency) {
  final allowed = currencyInputDecimalDigits(currency);
  // Round in decimal (toStringAsFixed) and compare with a tolerance of a few
  // ulps relative to the amount, so large values such as 123456789.12 and
  // computed sums such as 0.1 + 0.2 are not mistaken for extra precision.
  final rounded = double.parse(amount.toStringAsFixed(allowed));
  if ((amount - rounded).abs() <= amount.abs() * 4e-16) return null;
  return allowed == 0
      ? '${currency.toUpperCase()} amounts are whole numbers.'
      : 'Use at most $allowed decimal places.';
}
