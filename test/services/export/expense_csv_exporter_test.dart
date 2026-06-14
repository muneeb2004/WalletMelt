import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/expense_csv_exporter.dart';
import 'package:wallet_melt/src/types/expense.dart';

void main() {
  group('ExpenseCsvExporter', () {
    const exporter = ExpenseCsvExporter();

    test('emits deterministic headers', () {
      final csv = exporter.exportExpenses(
        expenses: const [],
        categoryNamesById: const {},
      );

      expect(csv,
          'id,date,title,amount,currency,category_name,vendor,notes,receipt_image_uri,is_recurring,created_at');
    });

    test('emits one row per active expense', () {
      final csv = exporter.exportExpenses(
        expenses: [
          _expense(id: 'exp_1', title: 'Rent'),
          _expense(id: 'exp_2', title: 'Groceries'),
        ],
        categoryNamesById: const {'grocery': 'Groceries'},
      );

      expect(csv.split('\n'), hasLength(3));
      expect(csv, contains('exp_1'));
      expect(csv, contains('exp_2'));
    });

    test('preserves amount, date, title, and notes', () {
      final csv = exporter.exportExpenses(
        expenses: [
          _expense(
            amount: 8450.75,
            date: '2026-06-14T00:00:00.000',
            title: 'Monthly grocery',
            notes: 'Monthly stock',
          ),
        ],
        categoryNamesById: const {'grocery': 'Groceries'},
      );

      expect(csv, contains('8450.75'));
      expect(csv, contains('2026-06-14T00:00:00.000'));
      expect(csv, contains('Monthly grocery'));
      expect(csv, contains('Monthly stock'));
    });

    test('maps category ID to category name', () {
      final csv = exporter.exportExpenses(
        expenses: [_expense(categoryId: 'electricity')],
        categoryNamesById: const {'electricity': 'Electricity'},
      );

      expect(csv.split('\n').last, contains('Electricity'));
    });

    test('handles missing category lookup safely', () {
      final csv = exporter.exportExpenses(
        expenses: [_expense(categoryId: 'missing')],
        categoryNamesById: const {},
      );

      expect(csv.split('\n').last,
          contains(ExpenseCsvExporter.missingCategoryName));
    });

    test('preserves receipt URI/path text', () {
      final csv = exporter.exportExpenses(
        expenses: [_expense(receiptImageUri: 'file:///receipts/grocery.jpg')],
        categoryNamesById: const {'grocery': 'Groceries'},
      );

      expect(csv, contains('file:///receipts/grocery.jpg'));
    });

    test('does not require Flutter bindings or platform channels', () {
      final csv = exporter.exportExpenses(
        expenses: [_expense()],
        categoryNamesById: const {'grocery': 'Groceries'},
      );

      expect(csv, contains('exp_1'));
    });

    test('active-only mode excludes deleted expenses by default', () {
      final csv = exporter.exportExpenses(
        expenses: [
          _expense(id: 'active'),
          _expense(id: 'deleted', deletedAt: '2026-06-15T00:00:00.000'),
        ],
        categoryNamesById: const {'grocery': 'Groceries'},
      );

      expect(csv, contains('active'));
      expect(csv, isNot(contains('deleted')));
    });

    test('include-deleted mode includes deleted expenses', () {
      final csv = exporter.exportExpenses(
        expenses: [
          _expense(id: 'active'),
          _expense(id: 'deleted', deletedAt: '2026-06-15T00:00:00.000'),
        ],
        categoryNamesById: const {'grocery': 'Groceries'},
        includeDeleted: true,
      );

      expect(csv, contains('active'));
      expect(csv, contains('deleted'));
    });
  });
}

Expense _expense({
  String id = 'exp_1',
  double amount = 1200.5,
  String currency = 'PKR',
  String categoryId = 'grocery',
  String title = 'Grocery',
  String date = '2026-06-14T00:00:00.000',
  String? vendor = 'Imtiaz',
  String? notes,
  String? receiptImageUri,
  bool isRecurring = false,
  String createdAt = '2026-06-14T10:00:00.000',
  String updatedAt = '2026-06-14T10:00:00.000',
  String? deletedAt,
}) {
  return Expense(
    id: id,
    amount: amount,
    currency: currency,
    categoryId: categoryId,
    title: title,
    vendor: vendor,
    date: date,
    notes: notes,
    receiptImageUri: receiptImageUri,
    isRecurring: isRecurring,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}
