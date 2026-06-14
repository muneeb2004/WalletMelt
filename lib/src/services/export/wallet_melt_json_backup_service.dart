import 'dart:io';

import '../../types/budget.dart';
import '../../types/category.dart';
import '../../types/expense.dart';
import '../../types/grocery_item.dart';
import '../../types/settings.dart';
import 'export_file_writer.dart';
import 'wallet_melt_json_backup_encoder.dart';

class WalletMeltJsonBackupService {
  const WalletMeltJsonBackupService({
    WalletMeltJsonBackupEncoder encoder = const WalletMeltJsonBackupEncoder(),
    ExportFileWriter fileWriter = const ExportFileWriter(),
    String? appVersion,
  })  : _encoder = encoder,
        _fileWriter = fileWriter,
        _appVersion = appVersion;

  final WalletMeltJsonBackupEncoder _encoder;
  final ExportFileWriter _fileWriter;
  final String? _appVersion;

  Future<ExportFileResult> createBackup({
    required Iterable<Expense> expenses,
    required Iterable<GroceryItem> groceryItems,
    required Iterable<Category> categories,
    required Iterable<CategoryBudget> budgets,
    required WalletMeltSettings settings,
    DateTime? exportedAt,
    Directory? directory,
  }) {
    final timestamp = exportedAt ?? DateTime.now();
    final json = _encoder.encode(
      expenses: expenses,
      groceryItems: groceryItems,
      categories: categories,
      budgets: budgets,
      settings: settings,
      exportedAt: timestamp,
      appVersion: _appVersion,
    );

    return _fileWriter.writeJson(
      jsonText: json,
      exportKind: 'backup',
      createdAt: timestamp,
      directory: directory,
    );
  }
}
