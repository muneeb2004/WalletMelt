import 'dart:io';

import '../../types/category.dart';
import '../../types/expense.dart';
import 'expense_csv_exporter.dart';
import 'export_file_writer.dart';

class ExpenseCsvExportService {
  const ExpenseCsvExportService({
    ExpenseCsvExporter exporter = const ExpenseCsvExporter(),
    ExportFileWriter fileWriter = const ExportFileWriter(),
  })  : _exporter = exporter,
        _fileWriter = fileWriter;

  final ExpenseCsvExporter _exporter;
  final ExportFileWriter _fileWriter;

  Future<ExportFileResult> exportActiveExpenses({
    required Iterable<Expense> expenses,
    required Iterable<Category> categories,
    bool includeDeleted = false,
    DateTime? createdAt,
    Directory? directory,
  }) {
    final csv = _exporter.exportExpenses(
      expenses: expenses,
      categoryNamesById: {
        for (final category in categories) category.id: category.name,
      },
      includeDeleted: includeDeleted,
    );

    return _fileWriter.writeCsv(
      csvText: csv,
      exportKind: 'expenses',
      createdAt: createdAt,
      directory: directory,
    );
  }
}
