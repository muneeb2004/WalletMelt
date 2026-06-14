class ExpenseValidationResult {
  const ExpenseValidationResult({required this.isValid, this.amountError, this.categoryError, this.dateError});

  final bool isValid;
  final String? amountError;
  final String? categoryError;
  final String? dateError;
}

ExpenseValidationResult validateExpenseInput({
  required String amount,
  required String? categoryId,
  required DateTime? date,
}) {
  final parsed = double.tryParse(amount.trim());
  final amountError = parsed == null || parsed <= 0 ? 'Enter a positive amount.' : null;
  final categoryError = categoryId == null || categoryId.isEmpty ? 'Choose a category.' : null;
  final dateError = date == null ? 'Choose a date.' : null;

  return ExpenseValidationResult(
    isValid: amountError == null && categoryError == null && dateError == null,
    amountError: amountError,
    categoryError: categoryError,
    dateError: dateError,
  );
}
