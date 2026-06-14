import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/expense_csv_export_service.dart';
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';

void main() {
  group('ExpenseCsvExportService', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory =
          await Directory.systemTemp.createTemp('walletmelt_expense_export_');
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('generates CSV from expenses and categories', () async {
      const service = ExpenseCsvExportService();

      final result = await service.exportActiveExpenses(
        expenses: [_expense(title: 'Weekly grocery')],
        categories: [_category(id: 'grocery', name: 'Groceries')],
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final csv = await File(result.path).readAsString();
      expect(csv, contains('Weekly grocery'));
      expect(csv, contains('Groceries'));
      expect(result.mimeType, ExportFileWriter.csvMimeType);
    });

    test('active-only export excludes deleted expenses by default', () async {
      const service = ExpenseCsvExportService();

      final result = await service.exportActiveExpenses(
        expenses: [
          _expense(id: 'active', title: 'Active expense'),
          _expense(
            id: 'deleted',
            title: 'Deleted expense',
            deletedAt: '2026-06-15T00:00:00.000',
          ),
        ],
        categories: [_category(id: 'grocery', name: 'Groceries')],
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final csv = await File(result.path).readAsString();
      expect(csv, contains('Active expense'));
      expect(csv, isNot(contains('Deleted expense')));
    });

    test('include-deleted export includes deleted expenses', () async {
      const service = ExpenseCsvExportService();

      final result = await service.exportActiveExpenses(
        expenses: [
          _expense(id: 'active', title: 'Active expense'),
          _expense(
            id: 'deleted',
            title: 'Deleted expense',
            deletedAt: '2026-06-15T00:00:00.000',
          ),
        ],
        categories: [_category(id: 'grocery', name: 'Groceries')],
        includeDeleted: true,
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final csv = await File(result.path).readAsString();
      expect(csv, contains('Active expense'));
      expect(csv, contains('Deleted expense'));
    });

    test('missing category exports as Unknown', () async {
      const service = ExpenseCsvExportService();

      final result = await service.exportActiveExpenses(
        expenses: [_expense(categoryId: 'missing')],
        categories: const [],
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final csv = await File(result.path).readAsString();
      expect(csv, contains('Unknown'));
    });

    test('handles empty expense list gracefully', () async {
      const service = ExpenseCsvExportService();

      final result = await service.exportActiveExpenses(
        expenses: const [],
        categories: const [],
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final csv = await File(result.path).readAsString();
      expect(csv.split('\n'), hasLength(1));
      expect(csv, startsWith('id,date,title,amount'));
    });
  });
}

Category _category({
  required String id,
  required String name,
}) {
  return Category(
    id: id,
    name: name,
    icon: 'shopping_basket',
    color: '#000000',
    isDefault: true,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

Expense _expense({
  String id = 'exp_1',
  double amount = 1200.5,
  String currency = 'PKR',
  String categoryId = 'grocery',
  String title = 'Grocery',
  String date = '2026-06-14T00:00:00.000',
  String? deletedAt,
}) {
  return Expense(
    id: id,
    amount: amount,
    currency: currency,
    categoryId: categoryId,
    title: title,
    date: date,
    isRecurring: false,
    createdAt: '2026-06-14T10:00:00.000',
    updatedAt: '2026-06-14T10:00:00.000',
    deletedAt: deletedAt,
  );
}
