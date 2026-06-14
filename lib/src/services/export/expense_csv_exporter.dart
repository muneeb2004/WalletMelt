import '../../types/expense.dart';
import 'csv_encoder.dart';

class ExpenseCsvExporter {
  const ExpenseCsvExporter({CsvEncoder encoder = const CsvEncoder()})
      : _encoder = encoder;

  static const List<String> headers = [
    'id',
    'date',
    'title',
    'amount',
    'currency',
    'category_name',
    'vendor',
    'notes',
    'receipt_image_uri',
    'is_recurring',
    'created_at',
  ];

  static const String missingCategoryName = 'Unknown';

  final CsvEncoder _encoder;

  String exportExpenses({
    required Iterable<Expense> expenses,
    required Map<String, String> categoryNamesById,
    bool includeDeleted = false,
  }) {
    final rows = <Iterable<Object?>>[
      headers,
      for (final expense in expenses)
        if (includeDeleted || !expense.isDeleted)
          _rowFor(expense, categoryNamesById),
    ];

    return _encoder.encodeRows(rows);
  }

  List<Object?> _rowFor(
      Expense expense, Map<String, String> categoryNamesById) {
    return [
      expense.id,
      expense.date,
      expense.title,
      _formatAmount(expense.amount),
      expense.currency,
      _categoryNameFor(expense.categoryId, categoryNamesById),
      expense.vendor,
      expense.notes,
      expense.receiptImageUri,
      expense.isRecurring ? 'true' : 'false',
      expense.createdAt,
    ];
  }

  String _categoryNameFor(
      String categoryId, Map<String, String> categoryNamesById) {
    final name = categoryNamesById[categoryId]?.trim();
    if (name == null || name.isEmpty) return missingCategoryName;
    return name;
  }

  String _formatAmount(double amount) {
    return amount.toString();
  }
}
