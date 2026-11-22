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

/// Error text when [amount] has more decimal places than [currency] allows,
/// otherwise null.
String? amountPrecisionError(double amount, String currency) {
  final allowed = currencyInputDecimalDigits(currency);
  var scaled = amount;
  for (var i = 0; i < allowed; i++) {
    scaled *= 10;
  }
  if ((scaled - scaled.roundToDouble()).abs() < 1e-6) return null;
  return allowed == 0
      ? '${currency.toUpperCase()} amounts are whole numbers.'
      : 'Use at most $allowed decimal places.';
}
