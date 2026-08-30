import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../types/budget.dart';
import '../../types/category.dart';
import '../../types/expense.dart';
import '../../types/grocery_item.dart';
import '../../types/settings.dart';
import '../../utils/platform_info.dart';
import 'backup_encryption_service.dart';
import 'export_file_writer.dart';
import 'wallet_melt_json_backup_encoder.dart';

class WalletMeltJsonBackupService {
  const WalletMeltJsonBackupService({
    WalletMeltJsonBackupEncoder encoder = const WalletMeltJsonBackupEncoder(),
    ExportFileWriter fileWriter = const ExportFileWriter(),
    BackupEncryptionService encryptionService = const BackupEncryptionService(),
    String? appVersion,
  })  : _encoder = encoder,
        _fileWriter = fileWriter,
        _encryptionService = encryptionService,
        _appVersion = appVersion;

  final WalletMeltJsonBackupEncoder _encoder;
  final ExportFileWriter _fileWriter;
  final BackupEncryptionService _encryptionService;
  final String? _appVersion;

  Future<ExportFileResult> createBackup({
    required Iterable<Expense> expenses,
    required Iterable<GroceryItem> groceryItems,
    required Iterable<Category> categories,
    required Iterable<CategoryBudget> budgets,
    required WalletMeltSettings settings,
    DateTime? exportedAt,
    Directory? directory,
    bool packageReceipts = true,
    String? passphrase,
  }) async {
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

    if (!packageReceipts) {
      if (passphrase != null && passphrase.isNotEmpty) {
        final encrypted = _encryptionService.encrypt(
          plaintext: utf8.encode(json),
          passphrase: passphrase,
        );
        return _fileWriter.writeZip(
          zipBytes: encrypted,
          exportKind: 'backup',
          createdAt: timestamp,
          directory: directory,
        );
      }

      return _fileWriter.writeJson(
        jsonText: json,
        exportKind: 'backup',
        createdAt: timestamp,
        directory: directory,
      );
    }

    // Collect physical receipt files to package in the ZIP
    final receiptUris = expenses
        .map((e) => e.receiptImageUri)
        .where((uri) => uri != null && uri.isNotEmpty)
        .cast<String>()
        .toSet();

    final List<File> receiptFiles = [];
    for (final uriStr in receiptUris) {
      try {
        final uri = Uri.tryParse(uriStr);
        if (uri != null && uri.isScheme('file')) {
          final file = File(uri.toFilePath());
          if (file.existsSync()) {
            receiptFiles.add(file);
          }
        } else {
          final file = File(uriStr);
          if (file.existsSync()) {
            receiptFiles.add(file);
          }
        }
      } catch (_) {
        // Safe skip on error
      }
    }

    final archive = Archive();

    // 1. Add backup.json
    final backupJsonBytes = utf8.encode(json);
    archive.addFile(ArchiveFile(
        'backup.json', backupJsonBytes.length, backupJsonBytes));

    // 2. Add metadata.json
    final metadataJson = jsonEncode({
      'backupVersion': 1,
      'createdAt': timestamp.toIso8601String(),
      'walletMeltVersion': _appVersion ?? '1.0.0+3',
      'recordCounts': {
        'expenses': expenses.length,
        'categories': categories.length,
        'groceryItems': groceryItems.length,
        'budgets': budgets.length,
        'receipts': receiptFiles.length,
      },
      'app_version': _appVersion ?? '1.0.0+3',
      'schema_version': 2,
      'export_timestamp': timestamp.toIso8601String(),
      'platform': PlatformInfo.isWeb
          ? 'Web'
          : (PlatformInfo.isAndroid
              ? 'Android'
              : (PlatformInfo.isIOS ? 'iOS' : 'Desktop')),
      'receipt_file_count': receiptFiles.length,
      'database_file_name': 'wallet_melt.db',
      'is_encrypted': passphrase != null && passphrase.isNotEmpty,
    });
    final metadataBytes = utf8.encode(metadataJson);
    archive.addFile(
        ArchiveFile('metadata.json', metadataBytes.length, metadataBytes));

    // 3. Add receipts directory files
    for (final file in receiptFiles) {
      final name = p.basename(file.path);
      final bytes = file.readAsBytesSync();
      archive.addFile(ArchiveFile('receipts/$name', bytes.length, bytes));
    }

    var zipBytes = ZipEncoder().encode(archive);

    if (passphrase != null && passphrase.isNotEmpty) {
      zipBytes = _encryptionService.encrypt(
        plaintext: zipBytes,
        passphrase: passphrase,
      );
    }

    return _fileWriter.writeZip(
      zipBytes: zipBytes,
      exportKind: 'backup',
      createdAt: timestamp,
      directory: directory,
    );
  }
}


