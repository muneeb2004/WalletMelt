import 'dart:convert';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'wallet_melt_json_backup_validator.dart';

/// Service abstraction for picking files from the system.
class FilePickerService {
  const FilePickerService();

  /// Prompts the user to pick a JSON file and returns its content as a String.
  /// Returns null if the user cancels or the file cannot be read.
  Future<String?> pickJsonFileContent() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) {
        return null;
      }
      final file = files.first;

      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        return utf8.decode(bytes);
      }

      final path = file.path;
      if (path != null) {
        return io.File(path).readAsString();
      }

      final chunks = await file.readAsByteStream().toList();
      return utf8.decode(chunks.expand((chunk) => chunk).toList());
    } catch (_) {
      // Return null on failure or user cancellation.
    }
    return null;
  }

  /// Prompts the user to pick a backup file (either JSON or ZIP) and returns a WalletMeltBackupFile.
  Future<WalletMeltBackupFile?> pickBackupFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
      );
      if (files.isEmpty) {
        return null;
      }
      final file = files.first;

      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        return await WalletMeltBackupFile.fromBytes(bytes);
      }

      final path = file.path;
      if (path != null) {
        return await WalletMeltBackupFile.fromPath(path);
      }

      final chunks = await file.readAsByteStream().toList();
      final streamBytes = chunks.expand((chunk) => chunk).toList();
      return await WalletMeltBackupFile.fromBytes(streamBytes);
    } catch (_) {
      // Return null on failure or user cancellation.
    }
    return null;
  }
}
